--!strict
-- The Worm (§8.2): character, movement validation, burrow rules, pounce, grab + mouth minigame
-- (§8.3), health, forced burrow and healing rings.
--
-- A worm is a Model in Workspace/Worms tagged "Worm". Its head is an unanchored, non-colliding part
-- owned by the worm player's client, which drives it with the head's LinearVelocity ("Drive") and
-- AlignOrientation ("Align"). The server owns the *mode* and checks the head's movement against it.
-- Replicated as attributes on the model: OwnerUserId, Mode, Health, BurrowLocked, RingCenter,
-- Sneaking, PounceReadyAt, GrabbedUserId.
--
-- Pounce/Burrow/Sneak are handled here for now; Phase 11 moves abilities into AbilityService.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local WormSkin = require(ReplicatedStorage.Shared.WormSkin)
local CosmeticsService = require(script.Parent.CosmeticsService)
local ItemService = require(script.Parent.ItemService)
local MapService = require(script.Parent.MapService)
local PardnerService = require(script.Parent.PardnerService)
local StructureService = require(script.Parent.StructureService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local Tags = TagDefs.Tags
local GrabConfig = WormConfig.Grab
local Minigame = WormConfig.Minigame

local WORMS_FOLDER = "Worms"
local AUTO_INPUT = "Auto"
local DRAIN_INTERVAL = 0.25 -- seconds between mouth-damage ticks (keeps State_Pardner traffic down)
local MODE_SETTLE_SECONDS = 1 -- a freshly burrowed head gets this long to sink before the height check

type Grab = {
	worm: Worm,
	pardner: Player,
	root: BasePart,
	sequence: { string },
	progress: number,
	checkpoint: number,
	lastInput: number,
	auto: boolean,
	autoTime: number,
	drainTimer: number,
	hold: CFrame?, -- where the Pardner is held; nil = in the head (a Sandtrap holds them in the sand)
}

type Worm = {
	player: Player,
	model: Model,
	head: BasePart,
	radius: number,
	health: number,
	publishedHealth: number,
	mode: Types.WormMode,
	modeSince: number,
	burrowLocked: boolean, -- took damage: stays underground until healed
	ringCenter: Vector3?,
	carapaceUntil: number, -- server time; Armored Carapace shell while now < this
	lastY: number,
	windowStart: Vector3,
	windowTime: number,
	windowMaxSpeed: number,
	grab: Grab?,
	pounceHits: { [Model]: boolean }, -- structures already damaged by the current pounce
	disorientedUntil: number, -- server time; sees nothing until then
	connection: RBXScriptConnection,
}

export type WormInfo = {
	player: Player,
	position: Vector3,
	mode: Types.WormMode,
	grabbed: Player?,
	model: Model,
	head: BasePart,
	burrowLocked: boolean,
}

local WormService = {}

-- Fires when a worm loses health: (wormPlayer).
local damaged: Signal.Signal<Player> = Signal.new()
WormService.damaged = damaged

-- Fires when a worm comes up out of the sand (unburrow or pounce): (wormPlayer, position).
local surfaced: Signal.Signal<Player, Vector3> = Signal.new()
WormService.surfaced = surfaced

local worms: { [Player]: Worm } = {}
local grabs: { [Player]: Grab } = {} -- by grabbed Pardner
local immuneUntil: { [Player]: number } = {}
local swallowedBy: { [Player]: Player } = {} -- Pardner who died in a mouth -> that worm, until collected
local night = false
-- Asked when a grabbed Pardner is about to die; true = they get out instead (KitService: knife).
local escapeSaver: ((pardner: Player) -> boolean)? = nil

local wormsFolder: Instance
local launchRemote: RemoteEvent
local minigameRemote: RemoteEvent
local notifyRemote: RemoteEvent

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function publish(worm: Worm)
	local model = worm.model
	local grab = worm.grab
	worm.publishedHealth = math.floor(worm.health)
	model:SetAttribute("Health", worm.publishedHealth)
	model:SetAttribute("Mode", worm.mode)
	model:SetAttribute("BurrowLocked", worm.burrowLocked)
	model:SetAttribute("RingCenter", worm.ringCenter)
	model:SetAttribute("CarapaceUntil", if worm.carapaceUntil > now() then worm.carapaceUntil else nil)
	model:SetAttribute("GrabbedUserId", if grab then grab.pardner.UserId else nil)
end

local function setMode(worm: Worm, mode: Types.WormMode)
	local wasUnderground = worm.mode == "Underground"
	if worm.mode ~= mode then
		worm.mode = mode
		worm.modeSince = now()
	end
	publish(worm)
	if wasUnderground and mode ~= "Underground" then
		surfaced:fire(worm.player, worm.head.Position)
	end
end

local function hasCarapace(worm: Worm): boolean
	return now() < worm.carapaceUntil
end

local function endCarapace(worm: Worm)
	worm.carapaceUntil = 0
	publish(worm)
end

local function teleport(worm: Worm, position: Vector3)
	worm.head.CFrame = CFrame.new(position) * worm.head.CFrame.Rotation
	worm.head.AssemblyLinearVelocity = Vector3.zero
	worm.windowStart = position
end

local function allowedSpeed(worm: Worm): number
	if worm.mode == "Airborne" then
		return WormConfig.MaxAirSpeed
	elseif worm.mode == "Surface" then
		return WormConfig.SurfaceSpeed
	end
	return WormConfig.UndergroundSpeed
end

-- A point under the sand, SpawnRadius from the TrainSpot.
local function spawnPosition(): Vector3
	local center = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1].Position
	local rng = Random.new()
	for _ = 1, WormConfig.SpawnAttempts do
		local angle = rng:NextNumber(0, math.pi * 2)
		local point = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * WormConfig.SpawnRadius
		local sandY = Ground.sandBelow(point)
		if sandY then
			return Vector3.new(point.X, sandY - WormConfig.UndergroundDepth, point.Z)
		end
	end
	warn("[WormService] No sand found for the worm spawn - spawning under the TrainSpot")
	return center - Vector3.yAxis * WormConfig.UndergroundDepth
end

-- Mouth minigame --------------------------------------------------------------------------------

local function sendMinigame(grab: Grab)
	local state: Types.MinigameState = {
		active = true,
		sequence = grab.sequence,
		progress = grab.progress,
		checkpoint = grab.checkpoint,
		auto = grab.auto,
		autoEndsAt = if grab.auto then now() + Minigame.AutoEscapeSeconds - grab.autoTime else nil,
	}
	minigameRemote:FireClient(grab.pardner, state)
end

-- Ends a grab. `released` puts the Pardner back on their feet above the worm.
local function endGrab(grab: Grab, released: boolean)
	local worm, pardner, root = grab.worm, grab.pardner, grab.root
	grabs[pardner] = nil
	worm.grab = nil
	PardnerService.setGrabbed(pardner, false)
	if pardner.Parent then
		local idle: Types.MinigameState = { active = false, sequence = {}, progress = 0, checkpoint = 0, auto = false }
		minigameRemote:FireClient(pardner, idle)
	end

	if root.Parent then
		if released then
			local hold = grab.hold
			local position = if hold then hold.Position else worm.head.Position
			local sandY = Ground.sandBelow(position)
			local y = math.max(position.Y, (sandY or position.Y) + GrabConfig.ReleaseHeight)
			root.CFrame = CFrame.new(position.X, y, position.Z)
		end
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		pcall(function()
			root:SetNetworkOwner(pardner)
		end)
	end
	publish(worm)
end

local function startGrab(worm: Worm, pardner: Player, root: BasePart, hold: CFrame?)
	ItemService.dropHeld(pardner)
	PardnerService.setGrabbed(pardner, true)

	local stats = PardnerService.getStats(pardner)
	if stats and stats.health > GrabConfig.InitialDamageMinHealth then
		PardnerService.damage(pardner, GrabConfig.InitialDamage)
	end

	local rng = Random.new()
	local sequence = table.create(Minigame.ArrowsToEscape)
	for index = 1, Minigame.ArrowsToEscape do
		sequence[index] = Minigame.Arrows[rng:NextInteger(1, #Minigame.Arrows)]
	end

	root.Anchored = true
	local grab: Grab = {
		worm = worm,
		pardner = pardner,
		root = root,
		sequence = sequence,
		progress = 0,
		checkpoint = 0,
		lastInput = 0,
		auto = false,
		autoTime = 0,
		drainTimer = 0,
		hold = hold,
	}
	worm.grab = grab
	grabs[pardner] = grab
	publish(worm)
	sendMinigame(grab)
	notifyRemote:FireClient(pardner, "The Worm has you! Match the arrows to escape")
	SoundCue.play("Grab", worm.head.Position)
	notifyRemote:FireClient(worm.player, `You caught {pardner.DisplayName}`)
end

-- The Pardner fought their way out: the worm is hurt, the Pardner gets Adrenaline (§8.3).
local function escape(grab: Grab)
	local worm, pardner = grab.worm, grab.pardner
	endGrab(grab, true)
	immuneUntil[pardner] = now() + WormConfig.GrabImmunitySeconds
	PardnerService.rewardEscape(pardner)
	WormService.damage(worm.player, WormConfig.EscapeDamageFraction, worm.head.Position)
	notifyRemote:FireClient(pardner, "You escaped! Run!")
	SoundCue.play("MouthEscape", worm.head.Position)
	notifyRemote:FireClient(worm.player, `{pardner.DisplayName} escaped your mouth`)
end

local function updateGrab(grab: Grab, dt: number)
	local root = grab.root
	if not root.Parent or not grab.pardner.Parent then
		endGrab(grab, false)
		return
	end
	root.CFrame = grab.hold or grab.worm.head.CFrame

	if grab.auto then
		grab.autoTime += dt
		if grab.autoTime >= Minigame.AutoEscapeSeconds then
			escape(grab)
			return
		end
	end

	grab.drainTimer += dt
	if grab.drainTimer >= DRAIN_INTERVAL then
		local amount = GrabConfig.DrainPerSecond * grab.drainTimer
		grab.drainTimer = 0
		-- A Quick Escape Knife saves a Pardner the moment the mouth would kill them (§6.6).
		local stats = PardnerService.getStats(grab.pardner)
		local saver = escapeSaver
		if stats and stats.health - amount <= 0 and saver and saver(grab.pardner) then
			escape(grab)
			return
		end
		-- May kill the Pardner; PardnerService.died then ends the grab.
		PardnerService.damage(grab.pardner, amount)
	end
end

local function onMinigameInput(player: Player, arrow: any)
	local grab = grabs[player]
	if not grab or typeof(arrow) ~= "string" then
		return
	end

	if arrow == AUTO_INPUT then
		grab.auto = not grab.auto
		grab.autoTime = 0
		sendMinigame(grab)
		return
	end
	if grab.auto then
		return
	end

	-- Anti-macro: inputs faster than a person can read the next arrow are dropped.
	local time = os.clock()
	if time - grab.lastInput < Minigame.MinInputInterval then
		return
	end
	grab.lastInput = time

	if arrow == grab.sequence[grab.progress + 1] then
		grab.progress += 1
		if grab.progress % Minigame.CheckpointEvery == 0 then
			grab.checkpoint = grab.progress
		end
		if grab.progress >= #grab.sequence then
			escape(grab)
			return
		end
	else
		grab.progress = math.max(grab.checkpoint, grab.progress - Minigame.WrongInputPenalty)
	end
	sendMinigame(grab)
end

-- Per-frame worm updates ------------------------------------------------------------------------

local function tryGrab(worm: Worm, position: Vector3)
	local time = now()
	for pardner, root in PardnerService.getLiving() do
		local stats = PardnerService.getStats(pardner)
		local immune = (immuneUntil[pardner] or 0) > time
		if stats and not stats.grabbed and not immune then
			if (root.Position - position).Magnitude <= WormConfig.GrabRadius then
				startGrab(worm, pardner, root)
				return
			end
		end
	end
end

local function updateAirborne(worm: Worm, position: Vector3)
	if not worm.grab then
		tryGrab(worm, position)
	end

	-- Loose items in the pounce's path are swallowed (dynamite goes off at once, §6.7).
	for _, model in ItemService.getLooseNear(position, WormConfig.GrabRadius) do
		ItemService.swallow(model, worm.head, GrabConfig.ItemSwallowSeconds)
	end

	-- Each structure the pounce passes through takes one hit (§7); with the Armored Carapace up, the
	-- first one it can damage is flattened outright and the shell is spent.
	for _, model in StructureService.getInRadius(position, worm.radius) do
		if not worm.pounceHits[model] then
			worm.pounceHits[model] = true
			if hasCarapace(worm) and StructureService.isWormDamageable(model) then
				StructureService.destroy(model)
				endCarapace(worm)
			else
				StructureService.damage(model, Structures.PounceDamage, "Worm")
			end
		end
	end

	-- Landing: coming down, and the bottom of the head has reached the ground.
	if now() - worm.modeSince < WormConfig.PounceMinAirTime or position.Y >= worm.lastY then
		return
	end
	local surfaceY, isSand = Ground.surfaceBelow(position)
	if not surfaceY then
		surfaceY = Ground.sandBelow(position)
		isSand = surfaceY ~= nil
	end
	if not surfaceY then
		setMode(worm, "Underground") -- nothing below at all: stop the fall
	elseif isSand then
		-- Diving back into sand burrows, once the head is half under.
		if position.Y <= surfaceY then
			setMode(worm, "Underground")
		end
	elseif position.Y - worm.radius <= surfaceY then
		setMode(worm, "Surface") -- a belly flop onto something solid
	end
end

-- The head is client-driven, so every ValidateWindow the server compares how far it went with how
-- far its mode allows, and puts it back if that was too far.
local function validate(worm: Worm, position: Vector3, dt: number)
	worm.windowTime += dt
	worm.windowMaxSpeed = math.max(worm.windowMaxSpeed, allowedSpeed(worm))
	if worm.windowTime < WormConfig.ValidateWindow then
		return
	end

	local offset = position - worm.windowStart
	local travelled = Vector3.new(offset.X, 0, offset.Z).Magnitude
	local allowed = worm.windowMaxSpeed * WormConfig.SpeedTolerance * worm.windowTime + WormConfig.ValidateSlack
	if travelled > allowed then
		teleport(worm, worm.windowStart)
	else
		worm.windowStart = position
		-- A burrowed head has to stay under the sand.
		if worm.mode == "Underground" and now() - worm.modeSince > MODE_SETTLE_SECONDS then
			local sandY = Ground.sandBelow(position)
			if sandY and position.Y > sandY + WormConfig.SurfaceSlack then
				teleport(worm, Vector3.new(position.X, sandY - WormConfig.UndergroundDepth, position.Z))
			end
		end
	end
	worm.windowTime = 0
	worm.windowMaxSpeed = 0
end

-- Healing rings (§8.2): the farther from where it was hurt, the faster the worm heals.
local function heal(worm: Worm, position: Vector3, dt: number)
	local center = worm.ringCenter
	if not worm.burrowLocked or not center then
		return
	end

	local offset = position - center
	local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
	local rings = WormConfig.HealRings
	local ring = rings[#rings]
	for _, candidate in rings do
		if distance < candidate.radius then
			ring = candidate
			break
		end
	end

	local rate = if night then ring.nightHealPerSecond else ring.healPerSecond
	worm.health = math.min(WormConfig.MaxHealth, worm.health + rate * dt)

	if worm.health >= WormConfig.MaxHealth * WormConfig.UnburrowHealthFraction then
		worm.burrowLocked = false
		worm.ringCenter = nil
		publish(worm)
		notifyRemote:FireClient(worm.player, "You have healed - you can surface again")
	elseif math.floor(worm.health) ~= worm.publishedHealth then
		publish(worm)
	end
end

local function step(dt: number)
	for _, worm in worms do
		local head = worm.head
		if not head.Parent then
			continue
		end
		local position = head.Position
		if worm.mode == "Airborne" then
			updateAirborne(worm, position)
		end
		validate(worm, position, dt)
		heal(worm, position, dt)
		local grab = worm.grab
		if grab then
			updateGrab(grab, dt)
		end
		worm.lastY = position.Y
	end
end

-- Movement abilities (AbilityService calls these; it owns cooldowns and input) --------------------

-- Toggle (§12). Burrowing needs sand underneath; surfacing needs full health after being hurt.
-- Returns false and a reason if nothing happened.
function WormService.toggleBurrow(player: Player): (boolean, string?)
	local worm = worms[player]
	if not worm then
		return false, nil
	end
	if worm.mode == "Underground" then
		if worm.burrowLocked then
			return false, "You are hurt - heal before surfacing"
		end
		setMode(worm, "Surface")
		return true, nil
	elseif worm.mode == "Surface" then
		local _, isSand = Ground.surfaceBelow(worm.head.Position)
		if not isSand then
			return false, "You can only burrow into sand"
		end
		setMode(worm, "Underground")
		return true, nil
	end
	return false, nil
end

-- Pounce (§12): launches the head on an arc toward `direction`, far stronger when bursting out of
-- the sand. Returns false and a reason if it can't.
function WormService.pounce(player: Player, direction: Vector3): (boolean, string?)
	local worm = worms[player]
	if not worm or worm.mode == "Airborne" then
		return false, nil
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if not (flat.Magnitude > 0.1 and flat.Magnitude < 1.5) then
		return false, nil -- also rejects NaN
	end
	if worm.mode == "Underground" and worm.burrowLocked then
		return false, "You are hurt - heal before surfacing"
	end

	local params = Abilities.Pounce.params
	local speed = if worm.mode == "Underground" then params.UnburrowLaunchSpeed else params.LaunchSpeed
	local angle = math.rad(WormConfig.PounceAngle)
	local velocity = flat.Unit * (speed * math.cos(angle)) + Vector3.yAxis * (speed * math.sin(angle))
	table.clear(worm.pounceHits)
	setMode(worm, "Airborne")
	SoundCue.play("Pounce", worm.head.Position)
	launchRemote:FireClient(worm.player, velocity)
	return true, nil
end

-- Pushes an airborne worm's head (Bodyslam drives it straight down).
function WormService.launch(player: Player, velocity: Vector3)
	local worm = worms[player]
	if worm then
		launchRemote:FireClient(worm.player, velocity)
	end
end

-- Hold to sneak: slower, and no dirt mound for Pardners to spot.
function WormService.setSneaking(player: Player, sneaking: boolean)
	local worm = worms[player]
	if worm then
		worm.model:SetAttribute("Sneaking", sneaking)
	end
end

-- Armored Carapace (§12): until `untilTime` the next hit is shrugged off and the next structure it can
-- damage is flattened; either one ends the shell.
function WormService.setCarapace(player: Player, untilTime: number)
	local worm = worms[player]
	if worm then
		worm.carapaceUntil = untilTime
		publish(worm)
	end
end

function WormService.hasCarapace(player: Player): boolean
	local worm = worms[player]
	return worm ~= nil and hasCarapace(worm)
end

-- Sandtrap (§12): the trap's worm takes hold of a Pardner who stepped in, holding them at `hold` in
-- the sand; they must win the mouth minigame. False if that worm is already holding someone.
function WormService.trapGrab(wormPlayer: Player, pardner: Player, hold: CFrame): boolean
	local worm = worms[wormPlayer]
	local root = PardnerService.getLiving()[pardner]
	local stats = PardnerService.getStats(pardner)
	if not worm or worm.grab or not root or not stats or stats.grabbed then
		return false
	end
	if (immuneUntil[pardner] or 0) > now() then
		return false
	end
	startGrab(worm, pardner, root, hold)
	return true
end

function WormService.isNight(): boolean
	return night
end

-- Public API ------------------------------------------------------------------------------------

-- Turns a player into a worm: their character is removed and a worm spawns under the sand.
function WormService.add(player: Player)
	if worms[player] then
		return
	end

	local character = player.Character
	player.Character = nil
	if character then
		character:Destroy()
	end

	local model = AssetService.get("WormHead") -- TODO(asset): WormHead
	model.Name = `Worm_{player.Name}`
	-- Cosmetic skin: the server dresses the head; every client dresses its own body segments from "Skin".
	local skin = CosmeticsService.getWormSkin(player)
	model:SetAttribute("Skin", skin)
	WormSkin.apply(model, skin, 0)
	local head = model.PrimaryPart
	assert(head, "[WormService] WormHead has no PrimaryPart")

	-- The worm passes through everything; grabs and landings are checked by the server instead.
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			if descendant ~= head then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = head
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy() -- a greybox label would poke out of the sand and give the worm away
		end
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "Root"
	attachment.Parent = head

	local drive = Instance.new("LinearVelocity")
	drive.Name = "Drive"
	drive.Attachment0 = attachment
	drive.RelativeTo = Enum.ActuatorRelativeTo.World
	drive.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	drive.MaxForce = WormConfig.MaxForce
	drive.VectorVelocity = Vector3.zero
	drive.Parent = head

	local align = Instance.new("AlignOrientation")
	align.Name = "Align"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.CFrame = CFrame.identity
	align.Parent = head

	local position = spawnPosition()
	model:PivotTo(CFrame.new(position))

	local worm: Worm = {
		player = player,
		model = model,
		head = head,
		radius = head.Size.Y / 2,
		health = WormConfig.MaxHealth,
		publishedHealth = WormConfig.MaxHealth,
		mode = "Underground",
		modeSince = now(),
		burrowLocked = false,
		ringCenter = nil,
		carapaceUntil = 0,
		lastY = position.Y,
		windowStart = position,
		windowTime = 0,
		windowMaxSpeed = 0,
		grab = nil,
		pounceHits = {},
		disorientedUntil = 0,
		-- A worm has no humanoid character; if Roblox respawns one anyway, remove it.
		connection = player.CharacterAdded:Connect(function(newCharacter)
			task.defer(function()
				if worms[player] then
					player.Character = nil
					newCharacter:Destroy()
				end
			end)
		end),
	}
	worms[player] = worm

	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Sneaking", false)
	publish(worm)
	CollectionService:AddTag(model, Tags.Worm)
	model.Parent = wormsFolder
	head:SetNetworkOwner(player)
end

function WormService.remove(player: Player)
	local worm = worms[player]
	if not worm then
		return
	end
	if worm.grab then
		endGrab(worm.grab, true)
	end
	worms[player] = nil
	worm.connection:Disconnect()
	worm.model:Destroy()
end

function WormService.removeAll()
	local players = {}
	for player in worms do
		table.insert(players, player)
	end
	for _, player in players do
		WormService.remove(player)
	end
	table.clear(immuneUntil)
	table.clear(swallowedBy)
end

-- If this Pardner just died inside a worm's mouth, returns that worm (once).
function WormService.takeSwallower(pardner: Player): Player?
	local worm = swallowedBy[pardner]
	swallowedBy[pardner] = nil
	return worm
end

-- Where a worm's head is right now, if it still exists.
function WormService.getPosition(player: Player): Vector3?
	local worm = worms[player]
	if worm and worm.head.Parent then
		return worm.head.Position
	end
	return nil
end

function WormService.isWorm(player: Player): boolean
	return worms[player] ~= nil
end

function WormService.setEscapeSaver(saver: (pardner: Player) -> boolean)
	escapeSaver = saver
end

-- The Pardner is out of the mouth at once, as if they'd won the minigame (Quick Escape Knife).
-- Returns false if they aren't grabbed.
function WormService.forceEscape(pardner: Player): boolean
	local grab = grabs[pardner]
	if not grab then
		return false
	end
	escape(grab)
	return true
end

function WormService.isGrabbed(pardner: Player): boolean
	return grabs[pardner] ~= nil
end

-- The Bullworm Rifle hit this worm (§6.6): it lets go of whoever it holds and takes rifle damage
-- (which also forces it under, like all damage).
function WormService.shoot(wormPlayer: Player, hitPosition: Vector3)
	local worm = worms[wormPlayer]
	if not worm then
		return
	end
	if worm.grab then
		endGrab(worm.grab, true)
	end
	WormService.damage(wormPlayer, WormConfig.RifleDamageFraction, hitPosition)
	notifyRemote:FireClient(wormPlayer, "You've been shot!")
end

-- Cymbal monkey / train horn (§6.6, §11): worms in range can't see Pardners, props or pings for a while.
function WormService.disorient(position: Vector3, radius: number, seconds: number)
	local untilTime = now() + seconds
	for _, worm in worms do
		if worm.head.Parent and (worm.head.Position - position).Magnitude <= radius then
			worm.disorientedUntil = math.max(worm.disorientedUntil, untilTime)
			worm.model:SetAttribute("DisorientedUntil", worm.disorientedUntil)
			notifyRemote:FireClient(worm.player, "You're disoriented!")
		end
	end
end

function WormService.isDisoriented(wormPlayer: Player): boolean
	local worm = worms[wormPlayer]
	return worm ~= nil and now() < worm.disorientedUntil
end

-- Where every worm is and what it is doing (DetectionService).
function WormService.getWorms(): { WormInfo }
	local list = {}
	for player, worm in worms do
		if worm.head.Parent then
			table.insert(list, {
				player = player,
				position = worm.head.Position,
				mode = worm.mode,
				grabbed = if worm.grab then worm.grab.pardner else nil,
				model = worm.model,
				head = worm.head,
				burrowLocked = worm.burrowLocked,
			})
		end
	end
	return list
end

-- Any health loss forces the worm underground until it has healed (§8.2).
-- `fraction` is of MaxHealth; the healing rings are centered on `position`.
function WormService.damage(player: Player, fraction: number, position: Vector3?)
	local worm = worms[player]
	if not worm then
		return
	end
	-- The Armored Carapace shrugs off one hit, and is gone.
	if hasCarapace(worm) then
		endCarapace(worm)
		notifyRemote:FireClient(player, "Your carapace took the hit")
		return
	end
	worm.health = math.max(0, worm.health - WormConfig.MaxHealth * fraction)
	worm.burrowLocked = true
	worm.ringCenter = position or worm.head.Position
	setMode(worm, "Underground")
	damaged:fire(player)
end

-- After sundown the worm heals faster in the outer rings and its cooldowns shrink (§5.4).
function WormService.setNight(isNight: boolean)
	night = isNight
end

function WormService.init()
	local folder = Instance.new("Folder")
	folder.Name = WORMS_FOLDER
	folder.Parent = Workspace
	wormsFolder = folder

	launchRemote = Net.event("Worm_Launch")
	minigameRemote = Net.event("State_Minigame")
	notifyRemote = Net.event("Fx_Notify")
end

function WormService.start()
	Net.onRequest("Request_MinigameInput", onMinigameInput)

	-- A Pardner who dies in the mouth has been eaten; ReviveService handles digestion (§9).
	PardnerService.died:connect(function(player: Player)
		local grab = grabs[player]
		if grab then
			swallowedBy[player] = grab.worm.player
			endGrab(grab, false)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local grab = grabs[player]
		if grab then
			endGrab(grab, false)
		end
		immuneUntil[player] = nil
		WormService.remove(player)
	end)

	RunService.Heartbeat:Connect(step)
end

return WormService
