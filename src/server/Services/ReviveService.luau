--!strict
-- Death and revive (§8.4, §9): heart jars, digestion, ghosts, the Church revive ring, revive limits.
--
-- When a Pardner dies:
--   * eaten (died in a worm's mouth): after the digestion time, a HeartJar drops where that worm is;
--   * any other death: a HeartJar drops at the body straight away.
-- Meanwhile the Pardner is a ghost: a small client-driven model in Workspace/Ghosts (tag "Ghost")
-- that can shove loose items. Dropping the jar inside the Church ring (built by MapService) revives
-- them, unless it is night or the jar is ossified (revive limit reached).
--
-- Jar attributes: OwnerUserId, OwnerName, Ossified. Ghost attributes: OwnerUserId, PushReadyAt.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local ItemService = require(script.Parent.ItemService)
local MapService = require(script.Parent.MapService)
local PardnerService = require(script.Parent.PardnerService)
local TrainService = require(script.Parent.TrainService)
local WormService = require(script.Parent.WormService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local GhostConfig = PardnerConfig.Ghost
local SPIRIT_BOARD = "SpiritBoard"
local ChurchConfig = Structures.Church
local Tags = TagDefs.Tags

local GHOSTS_FOLDER = "Ghosts"
local HEART_JAR = "HeartJar"

type Death = {
	player: Player,
	position: Vector3, -- where they died
	ossified: boolean,
	jar: Model?,
	swallower: Player?, -- the worm digesting them
	digestedAt: number?, -- server time the jar drops
}

type Ghost = {
	model: Model,
	part: BasePart,
	pushReadyAt: number,
}

local ReviveService = {}

-- Fires after a Pardner has been brought back: (player).
local revived: Signal.Signal<Player> = Signal.new()
ReviveService.revived = revived

local deaths: { [Player]: Death } = {}
local ghosts: { [Player]: Ghost } = {}
local jarOwners: { [Model]: Player } = {}

local active = false
local night = false
local reviveLimit = -1
local timer = 0
local ring: BasePart? = nil
local ghostsFolder: Instance
local notifyRemote: RemoteEvent

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Ghosts --------------------------------------------------------------------------------------

local function removeGhost(player: Player)
	local ghost = ghosts[player]
	if ghost then
		ghosts[player] = nil
		ghost.model:Destroy()
	end
end

local function spawnGhost(player: Player, position: Vector3)
	removeGhost(player)

	local model = AssetService.get("Ghost") -- TODO(asset): Ghost
	model.Name = `Ghost_{player.Name}`
	local part = model.PrimaryPart
	assert(part, "[ReviveService] Ghost has no PrimaryPart")

	-- Like the worm: non-colliding, flown by its owner's client.
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			if descendant ~= part then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "Root"
	attachment.Parent = part

	local drive = Instance.new("LinearVelocity")
	drive.Name = "Drive"
	drive.Attachment0 = attachment
	drive.RelativeTo = Enum.ActuatorRelativeTo.World
	drive.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	drive.MaxForce = GhostConfig.MaxForce
	drive.VectorVelocity = Vector3.zero
	drive.Parent = part

	model:PivotTo(CFrame.new(position))
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("PushReadyAt", 0)
	CollectionService:AddTag(model, Tags.Ghost)
	model.Parent = ghostsFolder
	part:SetNetworkOwner(player)

	ghosts[player] = { model = model, part = part, pushReadyAt = 0 }
end

-- Hold-to-charge shove on a loose item. Several ghosts pushing the same item simply add up.
local function onGhostPush(player: Player, target: any, direction: any, charge: any)
	local ghost = ghosts[player]
	if not ghost or typeof(target) ~= "Instance" or not target:IsA("Model") then
		return
	end
	if typeof(direction) ~= "Vector3" or typeof(charge) ~= "number" or charge ~= charge then
		return
	end
	if not (direction.Magnitude > 0.5 and direction.Magnitude < 1.5) or now() < ghost.pushReadyAt then
		return
	end

	local reach = GhostConfig.PushRange + target:GetExtentsSize().Magnitude / 2 + GhostConfig.PushSlack
	if (target:GetPivot().Position - ghost.part.Position).Magnitude > reach then
		return
	end

	local speed = GhostConfig.PushMaxForce * math.clamp(charge, 0, 1)
	if ItemService.push(target, direction.Unit * speed) then
		-- Shorter for every ghost while any living Pardner carries a Spirit Board (§8.4).
		local cooldown = GhostConfig.PushCooldown
		for living in PardnerService.getLiving() do
			if ItemService.getKitId(living) == SPIRIT_BOARD then
				cooldown = Kits.SpiritBoard.params.GhostPushCooldown
				break
			end
		end
		ghost.pushReadyAt = now() + cooldown
		ghost.model:SetAttribute("PushReadyAt", ghost.pushReadyAt)
	end
end

-- Heart jars ----------------------------------------------------------------------------------

local function spawnJar(death: Death, position: Vector3)
	local model = ItemService.spawn(HEART_JAR, CFrame.new(position))
	if not model then
		return
	end
	model:SetAttribute("OwnerUserId", death.player.UserId)
	model:SetAttribute("OwnerName", death.player.DisplayName)
	model:SetAttribute("Ossified", death.ossified)
	death.jar = model
	jarOwners[model] = death.player
	model.Destroying:Connect(function()
		jarOwners[model] = nil
		if death.jar == model then
			death.jar = nil -- lost for good; only a new jar (none yet) could bring them back
		end
	end)
end

local function removeBody(player: Player, character: Model)
	if player.Character == character then
		player.Character = nil
	end
	character:Destroy()
end

local function onDied(player: Player)
	if not active or deaths[player] then
		return
	end
	local character = player.Character
	local position = if character then character:GetPivot().Position else Vector3.zero
	local limitReached = reviveLimit >= 0 and PardnerService.getRevives(player) >= reviveLimit
	local death: Death = { player = player, position = position, ossified = limitReached }
	deaths[player] = death

	-- Deferred so WormService has recorded whether this death happened in a mouth.
	task.defer(function()
		if deaths[player] ~= death then
			return
		end
		local swallower = WormService.takeSwallower(player)
		if swallower then
			-- TODO(Phase 8+): +CactusFruitDigestionBonus per cactus fruit eaten since last being eaten.
			death.swallower = swallower
			death.digestedAt = now() + PardnerConfig.DigestionSeconds
			if character then
				removeBody(player, character)
			end
			notifyRemote:FireClient(player, "You were eaten. Your heart jar will appear when the Worm digests you")
			notifyRemote:FireAllClients(`{player.DisplayName} was eaten`, "Kill")
		else
			spawnJar(death, position + Vector3.yAxis * PardnerConfig.JarSpawnHeight)
			if character then
				task.delay(PardnerConfig.BodyRemoveSeconds, function()
					if PardnerService.isDead(player) then
						removeBody(player, character)
					end
				end)
			end
			notifyRemote:FireClient(player, "You died. A Pardner can carry your heart jar to the Church")
			notifyRemote:FireAllClients(`{player.DisplayName} died`, "Kill")
		end
		spawnGhost(player, position + Vector3.yAxis * GhostConfig.SpawnHeight)
	end)
end

-- The jar drops where the worm that ate them is now.
local function finishDigestion(death: Death)
	death.digestedAt = nil
	local swallower = death.swallower
	local position = (swallower and WormService.getPosition(swallower)) or death.position
	local sandY = Ground.sandBelow(position)
	local y = math.max(position.Y, sandY or position.Y) + PardnerConfig.JarSpawnHeight
	spawnJar(death, Vector3.new(position.X, y, position.Z))
	notifyRemote:FireAllClients(`{death.player.DisplayName}'s heart jar has appeared`, "Event")
end

-- Revive ----------------------------------------------------------------------------------------

-- Brings a dead Pardner back at `cframe` with reduced max health. Used by the Church ring and
-- (Phase 10) the Book of the Dead, which ignores night and ossified jars. Returns false if they
-- are not dead.
function ReviveService.revive(player: Player, cframe: CFrame): boolean
	local death = deaths[player]
	if not death or not player.Parent then
		return false
	end
	deaths[player] = nil
	if death.jar then
		ItemService.destroy(death.jar)
	end
	removeGhost(player)
	PardnerService.markRevived(player)

	task.spawn(function()
		local ok = pcall(player.LoadCharacter, player)
		local character = player.Character
		if ok and character then
			character:PivotTo(cframe * CFrame.new(0, PardnerConfig.ReviveSpawnHeight, 0))
		end
	end)

	-- Reviving resets the depart countdown (§9). The balloon notices the alive count change itself.
	TrainService.restartDepartTimer()
	SoundCue.play("Revive", cframe.Position)
	notifyRemote:FireAllClients(`{player.DisplayName} has been revived!`, "Revive")
	revived:fire(player)
	return true
end

local function checkChurch()
	local zone = ring
	if not zone or not zone.Parent then
		return
	end
	for jar, owner in jarOwners do
		local primary = jar.PrimaryPart
		-- Only a jar that has been put down counts (not one in hands or a bag).
		if not primary or ItemService.findLooseItem(primary) ~= jar then
			continue
		end
		local offset = primary.Position - zone.Position
		local inside = Vector3.new(offset.X, 0, offset.Z).Magnitude <= ChurchConfig.ReviveRadius
			and math.abs(offset.Y) <= ChurchConfig.ReviveHeight
		if inside and not night and jar:GetAttribute("Ossified") ~= true then
			ReviveService.revive(owner, zone.CFrame)
			return -- jarOwners changed; the rest are checked next tick
		end
	end
end

local function step(dt: number)
	if not active then
		return
	end
	timer += dt
	if timer < PardnerConfig.ReviveTickSeconds then
		return
	end
	timer = 0

	local time = now()
	for _, death in deaths do
		if death.digestedAt and time >= death.digestedAt then
			finishDigestion(death)
		end
	end
	checkChurch()
end

-- Match lifecycle -------------------------------------------------------------------------------

-- Call after MapService.populate(): the revive ring is the one MapService put by the Church.
function ReviveService.begin(settings: Types.MatchSettings)
	ReviveService.finish()
	reviveLimit = settings.reviveLimit
	night = false
	timer = 0
	ring = MapService.getChurchRing()
	if not ring then
		warn("[ReviveService] No Church revive ring this match - only the Book of the Dead can revive")
	end
	active = true
end

function ReviveService.finish()
	active = false
	local dead = {}
	for player in ghosts do
		table.insert(dead, player)
	end
	for _, player in dead do
		removeGhost(player)
	end
	table.clear(deaths)
	table.clear(jarOwners)
	ring = nil
end

-- No Church revives after sundown (§5.4).
function ReviveService.setNight(isNight: boolean)
	night = isNight
end

function ReviveService.getGhostCount(): number
	local count = 0
	for _ in ghosts do
		count += 1
	end
	return count
end

-- Book of the Dead (§9): revives the owner of `jar` at `cframe`, ignoring night and ossified hearts.
function ReviveService.reviveFromJar(jar: Model, cframe: CFrame): boolean
	local owner = jarOwners[jar]
	return owner ~= nil and ReviveService.revive(owner, cframe)
end

function ReviveService.getJarOwner(jar: Model): Player?
	return jarOwners[jar]
end

function ReviveService.init()
	local folder = Instance.new("Folder")
	folder.Name = GHOSTS_FOLDER
	folder.Parent = Workspace
	ghostsFolder = folder
	notifyRemote = Net.event("Fx_Notify")
end

function ReviveService.start()
	Net.onRequest("Request_GhostPush", onGhostPush)
	PardnerService.died:connect(onDied)

	Players.PlayerRemoving:Connect(function(player)
		local death = deaths[player]
		deaths[player] = nil
		removeGhost(player)
		if death and death.jar then
			ItemService.destroy(death.jar)
		end
	end)

	RunService.Heartbeat:Connect(step)
end

return ReviveService
