--!strict
-- Server authority for Pardner health, stamina and grip (§8.1).
-- Clients send intents (sprint / climb / jump); this validates them, runs PardnerLogic, and
-- replicates the result with State_Pardner.
-- MatchService decides who is a Pardner (PardnerService.add / remove).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local PardnerLogic = require(ReplicatedStorage.Shared.PardnerLogic)
local Janitor = require(ReplicatedStorage.Shared.Util.Janitor)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local Debug = GameConfig.Debug

type Pardner = {
	player: Player,
	stats: PardnerLogic.Stats,
	wantsSprint: boolean,
	wantsClimb: boolean,
	climbMiss: number, -- seconds the server has seen no wall while climbing
	lastJump: number,
	sendTimer: number,
	humanoid: Humanoid?,
	root: BasePart?,
	rayParams: RaycastParams,
	dead: boolean, -- stays true (as a ghost) until revived
	revives: number, -- each one lowers max health
	statuses: { Status }, -- timed effects; cleared on death
	snakeOil: boolean, -- permanent Snake Oil buff; kept through death (§6.6)
	janitor: Janitor.Janitor,
	characterJanitor: Janitor.Janitor,
}

-- A timed status effect (§8.1). The same id replaces itself. TODO(asset): status particles.
export type Status = {
	id: string,
	expires: number, -- os.clock()
	speedMult: number?,
	staminaUseMult: number?,
	revealed: boolean?, -- worms see this Pardner wherever they are (DetectionService)
	damageTakenMult: number?, -- scales damage taken (carapace sand blast)
}

-- What the Pardner's kit adds all the time (KitService provides it): speed and stamina-use multipliers.
export type PassiveMods = (player: Player) -> (number, number)

local PardnerService = {}

local passiveMods: PassiveMods? = nil

-- Fires when a Pardner grabs a wall (ItemService drops whatever they were holding).
local climbStarted: Signal.Signal<Player> = Signal.new()
PardnerService.climbStarted = climbStarted

local died: Signal.Signal<Player> = Signal.new()
PardnerService.died = died

local pardners: { [Player]: Pardner } = {}
local stateRemote: RemoteEvent
local impulseRemote: RemoteEvent

local function syncHumanoid(pardner: Pardner)
	local humanoid = pardner.humanoid
	if humanoid then
		humanoid.MaxHealth = pardner.stats.maxHealth
		humanoid.Health = pardner.stats.health
	end
end

local function sendState(pardner: Pardner)
	pardner.sendTimer = 0
	stateRemote:FireClient(pardner.player, pardner.stats)
end

local function onCharacter(pardner: Pardner, character: Model)
	pardner.characterJanitor:cleanup()
	pardner.humanoid = nil
	pardner.root = nil

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	if pardners[pardner.player] ~= pardner or pardner.player.Character ~= character then
		return
	end

	-- Every revive costs a slice of the base max health, down to a floor (§8.1).
	local stats = PardnerLogic.new()
	local lost = PardnerConfig.MaxHealth * PardnerConfig.ReviveMaxHealthLossFraction * pardner.revives
	stats.maxHealth = math.max(PardnerConfig.MinMaxHealth, PardnerConfig.MaxHealth - lost)
	stats.health = stats.maxHealth
	pardner.stats = stats
	table.clear(pardner.statuses)
	pardner.wantsSprint = false
	pardner.wantsClimb = false
	pardner.climbMiss = 0
	pardner.humanoid = humanoid
	pardner.root = root
	pardner.rayParams.FilterDescendantsInstances = { character }

	humanoid.WalkSpeed = PardnerConfig.WalkSpeed
	syncHumanoid(pardner)

	pardner.characterJanitor:add(humanoid.Died:Connect(function()
		pardner.stats.health = 0
		pardner.stats.sprinting = false
		pardner.stats.climbing = false
		pardner.wantsSprint = false
		pardner.wantsClimb = false
		pardner.dead = true
		pardner.humanoid = nil
		pardner.root = nil
		pardner.player:SetAttribute("Dead", true)
		sendState(pardner)
		died:fire(pardner.player)
	end))
	sendState(pardner)
end

local function stepPardner(pardner: Pardner, dt: number)
	local humanoid, root = pardner.humanoid, pardner.root
	local stats = pardner.stats
	if not humanoid or not root or stats.health <= 0 then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > PardnerConfig.MoveThreshold

	local groundReach = humanoid.HipHeight + root.Size.Y / 2 + PardnerConfig.GroundCheckSlack
	local grounded = Workspace:Raycast(root.Position, Vector3.yAxis * -groundReach, pardner.rayParams) ~= nil

	-- A climbing client faces the wall, so the wall must be in front of the root part.
	if pardner.wantsClimb then
		local wallReach = PardnerConfig.ClimbReach + PardnerConfig.ClimbServerSlack
		if Workspace:Raycast(root.Position, root.CFrame.LookVector * wallReach, pardner.rayParams) then
			pardner.climbMiss = 0
		else
			pardner.climbMiss += dt
			if pardner.climbMiss > PardnerConfig.ClimbValidateGrace then
				pardner.wantsClimb = false
			end
		end
	end

	-- Multipliers from status effects, the kit, and Snake Oil.
	local now = os.clock()
	local speedMult, staminaUseMult = 1, 1
	for index = #pardner.statuses, 1, -1 do
		local status = pardner.statuses[index]
		if now >= status.expires then
			table.remove(pardner.statuses, index)
		else
			speedMult *= status.speedMult or 1
			staminaUseMult *= status.staminaUseMult or 1
		end
	end
	local provider = passiveMods
	if provider then
		local kitSpeed, kitStamina = provider(pardner.player)
		speedMult *= kitSpeed
		staminaUseMult *= kitStamina
	end
	if pardner.snakeOil then
		speedMult *= Kits.SnakeOil.params.SpeedMult
	end
	stats.speedMult = speedMult
	stats.staminaUseMult = staminaUseMult

	PardnerLogic.step(stats, {
		wantsSprint = pardner.wantsSprint,
		wantsClimb = pardner.wantsClimb,
		moving = moving,
		grounded = grounded,
	}, dt)

	-- Out of grip and stamina: the climb is over until the client asks again.
	if pardner.wantsClimb and not stats.climbing then
		pardner.wantsClimb = false
	end

	local walkSpeed = PardnerLogic.walkSpeed(stats)
	if humanoid.WalkSpeed ~= walkSpeed then
		humanoid.WalkSpeed = walkSpeed
	end

	pardner.sendTimer += dt
	if pardner.sendTimer >= 1 / PardnerConfig.StateSendRate then
		sendState(pardner)
	end
end

-- Studio-only debug commands: !hurt <n>, !heal <n> (a leading / also works if the chat lets it through)
local function onChatCommand(player: Player, message: string)
	local command, argument = string.match(message, "^[!/](%a+)%s*([%d%.]*)")
	local amount = tonumber(argument) or Debug.ChatCommandDefaultAmount
	if command == "hurt" then
		PardnerService.damage(player, amount)
	elseif command == "heal" then
		PardnerService.heal(player, amount)
	end
end

local function addPardner(player: Player)
	if pardners[player] then
		return
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true

	local pardner: Pardner = {
		player = player,
		stats = PardnerLogic.new(),
		wantsSprint = false,
		wantsClimb = false,
		climbMiss = 0,
		lastJump = 0,
		sendTimer = 0,
		humanoid = nil,
		root = nil,
		rayParams = rayParams,
		dead = false,
		revives = 0,
		statuses = {},
		snakeOil = false,
		janitor = Janitor.new(),
		characterJanitor = Janitor.new(),
	}
	pardners[player] = pardner
	player:SetAttribute("Dead", false)
	pardner.janitor:add(pardner.characterJanitor)

	pardner.janitor:add(player.CharacterAdded:Connect(function(character)
		onCharacter(pardner, character)
	end))
	if player.Character then
		task.spawn(onCharacter, pardner, player.Character)
	end

	if Debug.Enabled and Debug.ChatCommands and RunService:IsStudio() then
		pardner.janitor:add(player.Chatted:Connect(function(message)
			onChatCommand(player, message)
		end))
	end
end

local function removePardner(player: Player)
	local pardner = pardners[player]
	if pardner then
		pardners[player] = nil
		pardner.janitor:cleanup()
		player:SetAttribute("Dead", false)
	end
end

-- MatchService decides who is a Pardner. Adding gives full stats on the current (and every later) character.
function PardnerService.add(player: Player)
	addPardner(player)
end

function PardnerService.remove(player: Player)
	removePardner(player)
end

function PardnerService.getPardners(): { Player }
	local list = {}
	for player in pardners do
		table.insert(list, player)
	end
	return list
end

function PardnerService.isPardner(player: Player): boolean
	return pardners[player] ~= nil
end

-- Root parts of every Pardner who is alive right now, by player.
function PardnerService.getLiving(): { [Player]: BasePart }
	local living = {}
	for player, pardner in pardners do
		local root = pardner.root
		if root and root.Parent and pardner.stats.health > 0 then
			living[player] = root
		end
	end
	return living
end

-- Pardners who have not died (or have been revived). Unlike getLiving this does not need a character,
-- so it is safe to ask while everyone is still spawning.
function PardnerService.getAliveCount(): number
	local count = 0
	for _, pardner in pardners do
		if not pardner.dead then
			count += 1
		end
	end
	return count
end

function PardnerService.isDead(player: Player): boolean
	local pardner = pardners[player]
	return pardner ~= nil and pardner.dead
end

function PardnerService.getRevives(player: Player): number
	local pardner = pardners[player]
	return if pardner then pardner.revives else 0
end

-- Marks a dead Pardner as alive again. The caller then loads their character, which picks up the
-- reduced max health.
-- Sundown (§5.4): with no more Church revives, every living Pardner whose health is below what a revive
-- would give them (the max health they'd have after one more revive) is topped up to that.
function PardnerService.sundownTopUp()
	for _, pardner in pardners do
		local stats = pardner.stats
		if pardner.dead or stats.health <= 0 then
			continue
		end
		local lost = PardnerConfig.MaxHealth * PardnerConfig.ReviveMaxHealthLossFraction * (pardner.revives + 1)
		local reviveHealth = math.max(PardnerConfig.MinMaxHealth, PardnerConfig.MaxHealth - lost)
		if stats.health < reviveHealth then
			stats.health = math.min(stats.maxHealth, reviveHealth)
			syncHumanoid(pardner)
			sendState(pardner)
		end
	end
end

function PardnerService.markRevived(player: Player)
	local pardner = pardners[player]
	if pardner and pardner.dead then
		pardner.dead = false
		pardner.revives += 1
		player:SetAttribute("Dead", false)
	end
end

function PardnerService.getStats(player: Player): PardnerLogic.Stats?
	local pardner = pardners[player]
	return pardner and pardner.stats
end

function PardnerService.damage(player: Player, amount: number)
	local pardner = pardners[player]
	if not pardner or pardner.stats.health <= 0 then
		return
	end
	local stats = pardner.stats
	if amount > 0 then
		local now = os.clock()
		for _, status in pardner.statuses do
			if status.damageTakenMult and now < status.expires then
				amount *= status.damageTakenMult
			end
		end
	end
	stats.health = math.clamp(stats.health - amount, 0, stats.maxHealth)
	syncHumanoid(pardner)
	sendState(pardner)
end

-- Takes stamina away (carapace sand blast).
function PardnerService.drainStamina(player: Player, amount: number)
	local pardner = pardners[player]
	if pardner then
		pardner.stats.stamina = math.max(0, pardner.stats.stamina - amount)
		pardner.stats.regenDelay = PardnerConfig.StaminaRegenDelay
		sendState(pardner)
	end
end

function PardnerService.heal(player: Player, amount: number)
	PardnerService.damage(player, -amount)
end

-- In a worm's mouth: the Pardner can't sprint or climb (WormService holds their character in place).
function PardnerService.setGrabbed(player: Player, grabbed: boolean)
	local pardner = pardners[player]
	if not pardner then
		return
	end
	pardner.stats.grabbed = grabbed
	if grabbed then
		pardner.wantsSprint = false
		pardner.wantsClimb = false
	end
	sendState(pardner)
end

-- Adrenaline (§8.1): +speed and no stamina drain for a while after escaping a worm's mouth.
function PardnerService.giveAdrenaline(player: Player)
	local pardner = pardners[player]
	if pardner then
		pardner.stats.adrenaline = PardnerConfig.Adrenaline.Seconds
		sendState(pardner)
	end
end

-- Escaped a worm's mouth (§8.3): Adrenaline, plus Snake Oil's bonus health if they have the buff.
function PardnerService.rewardEscape(player: Player)
	local pardner = pardners[player]
	if not pardner then
		return
	end
	if pardner.snakeOil then
		local params = Kits.SnakeOil.params
		PardnerService.heal(player, math.random(params.EscapeHealMin, params.EscapeHealMax))
	end
	PardnerService.giveAdrenaline(player)
end

-- Adds (or refreshes) a timed status effect. Expires on its own; cleared on death.
function PardnerService.addStatus(player: Player, status: Status)
	local pardner = pardners[player]
	if not pardner then
		return
	end
	for index, existing in pardner.statuses do
		if existing.id == status.id then
			table.remove(pardner.statuses, index)
			break
		end
	end
	table.insert(pardner.statuses, status)
end

-- Worms can see this Pardner anywhere right now (Coffee Tin, Concoction).
function PardnerService.isRevealed(player: Player): boolean
	local pardner = pardners[player]
	if not pardner then
		return false
	end
	local now = os.clock()
	for _, status in pardner.statuses do
		if status.revealed and now < status.expires then
			return true
		end
	end
	return false
end

-- Snake Oil (§6.6): max one buff per Pardner. Returns false if they already have it.
function PardnerService.giveSnakeOil(player: Player): boolean
	local pardner = pardners[player]
	if not pardner or pardner.snakeOil then
		return false
	end
	pardner.snakeOil = true
	return true
end

function PardnerService.setPassiveMods(provider: PassiveMods)
	passiveMods = provider
end

-- Pushes the Pardner's character (recoil, pogo). The character is client-owned, so its client applies it.
function PardnerService.impulse(player: Player, velocity: Vector3)
	if pardners[player] then
		impulseRemote:FireClient(player, velocity)
	end
end

function PardnerService.init()
	stateRemote = Net.event("State_Pardner")
	impulseRemote = Net.event("Pardner_Impulse")

	-- An empty script named "Health" replaces Roblox's default health-regen script.
	local characterScripts = StarterPlayer:FindFirstChildOfClass("StarterCharacterScripts")
	if characterScripts and not characterScripts:FindFirstChild("Health") then
		local override = Instance.new("Script")
		override.Name = "Health"
		override.Parent = characterScripts
	end
end

function PardnerService.start()
	Net.onRequest("Request_Sprint", function(player, state)
		local pardner = pardners[player]
		if pardner and typeof(state) == "boolean" then
			pardner.wantsSprint = state
		end
	end)

	Net.onRequest("Request_Climb", function(player, state)
		local pardner = pardners[player]
		if not pardner or typeof(state) ~= "boolean" then
			return
		end
		if state and (pardner.stats.health <= 0 or not PardnerLogic.canClimb(pardner.stats)) then
			return
		end
		pardner.wantsClimb = state
		pardner.climbMiss = 0
		if state then
			climbStarted:fire(player)
		end
	end)

	Net.onRequest("Request_Jump", function(player)
		local pardner = pardners[player]
		if not pardner or pardner.stats.health <= 0 then
			return
		end
		local now = os.clock()
		local elapsed = now - pardner.lastJump
		if pardner.stats.climbing then
			if elapsed >= PardnerConfig.ClimbJumpCooldown and pardner.stats.grip > 0 then
				pardner.lastJump = now
				PardnerLogic.applyClimbJump(pardner.stats)
			end
		elseif elapsed >= PardnerConfig.JumpMinInterval then
			pardner.lastJump = now
			PardnerLogic.applyJump(pardner.stats)
		end
	end)

	Players.PlayerRemoving:Connect(removePardner)

	RunService.Heartbeat:Connect(function(dt)
		for _, pardner in pardners do
			stepPardner(pardner, dt)
		end
	end)
end

return PardnerService
