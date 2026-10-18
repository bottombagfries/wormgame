--!strict
-- The Train (§11): furnace fueling, fuel meter, lever, depart timer, early depart, horn.
--
-- State is replicated as attributes on the Train model (tagged "Train"):
--   Fuel (0-100 meter), Phase (Types.TrainPhase), DepartAt / EarlyDepartAt (server time, or nil).
--
-- The Train model may contain parts or models named "Furnace", "Lever" and "Horn". Any that are
-- missing get a greybox placed on the deck from Config.Game.Train.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Loot = require(ReplicatedStorage.Shared.Config.Loot)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local ItemService = require(script.Parent.ItemService)
local WormService = require(script.Parent.WormService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)
local MapService = require(script.Parent.MapService)
local PardnerService = require(script.Parent.PardnerService)

local TrainConfig = GameConfig.Train
local Tags = TagDefs.Tags

local TrainService = {}

-- Fires once when the Train leaves: (escaped, leftBehind).
local departed: Signal.Signal<{ Player }, { Player }> = Signal.new()
TrainService.departed = departed

local train: Model
local zoneCFrame: CFrame -- "on the Train" volume
local zoneSize: Vector3
local furnaceCFrame: CFrame -- items inside this box are burned
local furnaceSize: Vector3
local leverPrompt: ProximityPrompt
local hornPrompt: ProximityPrompt
local keyholePrompt: ProximityPrompt
local notifyRemote: RemoteEvent

-- The keyhole only matters while Find the Train Key is active (§10.2).
local keyholeActive = false
local keyInserted = false

local phase: Types.TrainPhase = "Fueling"
local delivered = 0
local required = 1
local departAt: number? = nil
local boardedFor = 0
local hornReadyAt = 0
local leverLockedUntil = 0

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function publish()
	train:SetAttribute("Fuel", TrainService.getFuelMeter())
	train:SetAttribute("Phase", phase)
	train:SetAttribute("DepartAt", departAt)
	train:SetAttribute(
		"EarlyDepartAt",
		if boardedFor > 0 then now() + TrainConfig.EarlyDepartSeconds - boardedFor else nil
	)
	leverPrompt.Enabled = phase == "Ready"
	-- The horn is disabled once the lever has been pulled.
	hornPrompt.Enabled = phase == "Fueling" or phase == "Ready"
end

local function setPhase(newPhase: Types.TrainPhase)
	phase = newPhase
	publish()
end

local function getBounds(instance: Instance): (CFrame, Vector3)
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end
	return train:GetPivot(), Vector3.one
end

local function getPromptPart(instance: Instance): BasePart
	if instance:IsA("BasePart") then
		return instance
	end
	local part = if instance:IsA("Model") then instance.PrimaryPart else nil
	part = part or instance:FindFirstChildWhichIsA("BasePart", true)
	assert(part, `[TrainService] Train part "{instance.Name}" contains no BasePart`)
	return part
end

-- Finds a named part of the Train, or builds its greybox on the deck.
local function getComponent(name: string, assetId: string, deckTop: CFrame, offset: Vector3): Instance
	local existing = train:FindFirstChild(name, true)
	if existing then
		return existing
	end

	local model = AssetService.get(assetId) -- TODO(asset): TrainFurnace / TrainLever / TrainHorn
	model.Name = name
	Geometry.placeOnGround(model, deckTop * CFrame.new(offset))
	model.Parent = train
	return model
end

local function makePrompt(component: Instance, objectText: string, actionText: string, hold: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = objectText
	prompt.ActionText = actionText
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = TrainConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	prompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	prompt.Parent = getPromptPart(component)
	return prompt
end

-- Prompts are triggered by the client, so the server re-checks who and where.
local function canUsePrompt(player: Player, prompt: ProximityPrompt): boolean
	local root = PardnerService.getLiving()[player]
	local part = prompt.Parent
	if not root or not part or not part:IsA("BasePart") then
		return false
	end
	local reach = TrainConfig.PromptDistance + TrainConfig.PromptSlack
	return (root.Position - part.Position).Magnitude <= reach
end

local function buildTrain()
	local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]

	train = AssetService.get("Train") -- TODO(asset): Train
	Geometry.placeOnGround(train, trainSpot)

	-- Measured before the furnace/lever/horn greyboxes are added so they don't stretch the zone.
	local boundsCFrame, boundsSize = train:GetBoundingBox()
	local deckTop = boundsCFrame * CFrame.new(0, boundsSize.Y / 2, 0)
	zoneSize = Vector3.new(boundsSize.X, TrainConfig.OnTrainHeight, boundsSize.Z)
	zoneCFrame = deckTop * CFrame.new(0, TrainConfig.OnTrainHeight / 2, 0)

	local furnace = getComponent("Furnace", "TrainFurnace", deckTop, TrainConfig.FurnaceOffset)
	local lever = getComponent("Lever", "TrainLever", deckTop, TrainConfig.LeverOffset)
	local horn = getComponent("Horn", "TrainHorn", deckTop, TrainConfig.HornOffset)
	local keyhole = getComponent("Keyhole", "TrainKeyhole", deckTop, TrainConfig.KeyholeOffset)

	-- Indestructible and immovable; a greybox furnace is hollow so thrown items fly into it.
	for _, descendant in train:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	if furnace:GetAttribute("Greybox") then
		for _, descendant in furnace:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
			end
		end
	end

	local furnaceBoundsCFrame, furnaceBoundsSize = getBounds(furnace)
	furnaceCFrame = furnaceBoundsCFrame
	furnaceSize = furnaceBoundsSize + Vector3.one * (TrainConfig.FurnacePadding * 2)

	leverPrompt = makePrompt(lever, "Train", "Pull lever", TrainConfig.LeverHoldSeconds)
	hornPrompt = makePrompt(horn, "Train", "Sound horn", TrainConfig.HornHoldSeconds)
	keyholePrompt = makePrompt(keyhole, "Keyhole", "Insert key", TrainConfig.KeyholeHoldSeconds)
	keyholePrompt.Enabled = false

	CollectionService:AddTag(train, Tags.Train)
	train.Parent = Workspace
end

local function onLever(player: Player)
	if phase ~= "Ready" or not canUsePrompt(player, leverPrompt) then
		return
	end
	local locked = leverLockedUntil - now()
	if locked > 0 then
		notifyRemote:FireClient(player, `The lever is locked for {math.ceil(locked)}s after the horn`)
		return
	end
	departAt = now() + TrainConfig.DepartSeconds
	boardedFor = 0
	setPhase("Departing")
	notifyRemote:FireAllClients("The lever has been pulled - get on the Train!")
	SoundCue.play("LeverPulled")
end

local function onHorn(player: Player)
	if (phase ~= "Fueling" and phase ~= "Ready") or not canUsePrompt(player, hornPrompt) then
		return
	end
	local cooldown = hornReadyAt - now()
	if cooldown > 0 then
		notifyRemote:FireClient(player, `The horn is ready in {math.ceil(cooldown)}s`)
		return
	end
	hornReadyAt = now() + TrainConfig.HornCooldownSeconds
	leverLockedUntil = now() + TrainConfig.HornLeverLockSeconds
	-- Same effect as a cymbal monkey, over a wide radius (§11). TODO: wormlings too, once they exist.
	WormService.disorient(train:GetPivot().Position, TrainConfig.HornRadius, TrainConfig.HornDisorientSeconds)
	-- TODO(asset): horn sound
	notifyRemote:FireAllClients("The train horn blares!")
	SoundCue.play("TrainHorn")
end

local function onKeyhole(player: Player)
	if not keyholeActive or keyInserted or not canUsePrompt(player, keyholePrompt) then
		return
	end
	if ItemService.getHandItemId(player) ~= "TrainKey" then
		notifyRemote:FireClient(player, "You need to be holding the Train Key")
		return
	end
	ItemService.consumeHand(player)
	keyInserted = true
	keyholePrompt.Enabled = false
	train:SetAttribute("KeyInserted", true)
	notifyRemote:FireAllClients("The Train Key is in!")
end

local function burnFuel()
	local burned = false
	local seen: { [Model]: boolean } = {}
	for _, part in Workspace:GetPartBoundsInBox(furnaceCFrame, furnaceSize) do
		local model, itemId = ItemService.findLooseItem(part)
		if model and itemId and not seen[model] then
			seen[model] = true
			local fuel = Items[itemId].fuel
			if fuel then
				delivered += fuel
				SoundCue.play("FurnaceBurn", furnaceCFrame.Position)
				burned = true
				ItemService.destroy(model)
			end
		end
	end
	if not burned then
		return
	end
	if delivered >= required then
		delivered = required
		notifyRemote:FireAllClients("The Train is fully fueled")
	end
	publish()
end

local function depart()
	local escaped: { Player } = {}
	local leftBehind: { Player } = {}
	for player, root in PardnerService.getLiving() do
		if Geometry.isPointInBox(zoneCFrame, zoneSize, root.Position) then
			table.insert(escaped, player)
		else
			table.insert(leftBehind, player)
		end
	end
	departAt = nil
	boardedFor = 0
	setPhase("Departed")
	-- TODO(asset): the Train driving away
	departed:fire(escaped, leftBehind)
end

-- Early depart: every living Pardner on the Train for EarlyDepartSeconds in a row.
local function updateBoarding(dt: number)
	local living = 0
	local aboard = 0
	for _, root in PardnerService.getLiving() do
		living += 1
		if Geometry.isPointInBox(zoneCFrame, zoneSize, root.Position) then
			aboard += 1
		end
	end

	local wasBoarding = boardedFor > 0
	if living > 0 and aboard == living then
		boardedFor += dt
	else
		boardedFor = 0
	end
	if wasBoarding ~= (boardedFor > 0) then
		publish()
	end

	if boardedFor >= TrainConfig.EarlyDepartSeconds or (departAt and now() >= departAt) then
		depart()
	end
end

local function step(dt: number)
	if phase == "Fueling" and delivered < required then
		burnFuel()
	elseif phase == "Departing" then
		updateBoarding(dt)
	end
end

function TrainService.getTrain(): Model
	return train
end

function TrainService.getPhase(): Types.TrainPhase
	return phase
end

function TrainService.getDelivered(): number
	return delivered
end

-- Where the furnace is (tumbleweeds are lit here, §10.3).
function TrainService.getFurnacePosition(): Vector3
	return furnaceCFrame.Position
end

-- Ground level at the caboose end (the Train's -X end), facing along the Train (§7).
function TrainService.getCabooseCFrame(): CFrame
	local boundsCFrame, size = train:GetBoundingBox()
	return boundsCFrame * CFrame.new(-size.X / 2, -size.Y / 2, 0)
end

-- The 0-100 fuel meter players see.
function TrainService.getFuelMeter(): number
	return math.floor(math.clamp(delivered / required, 0, 1) * 100)
end

-- Called by ObjectiveService when every active objective is done: the lever becomes usable (§11).
function TrainService.unlockLever()
	if phase == "Fueling" then
		setPhase("Ready")
		notifyRemote:FireAllClients("All objectives complete - pull the lever on the Train!")
	end
end

-- True if `position` counts as standing on the Train.
function TrainService.isOnTrain(position: Vector3): boolean
	return Geometry.isPointInBox(zoneCFrame, zoneSize, position)
end

-- Caboose contents at match start (§7): crates on the deck and shovels on the ground past the
-- caboose (the Train's -X end). TODO: ladders on the caboose side, once ladders exist.
function TrainService.spawnContents()
	local Caboose = Loot.Caboose
	local boundsCFrame, size = train:GetBoundingBox()
	local cabooseEnd = boundsCFrame * CFrame.new(-size.X / 2, 0, 0)

	for index = 1, Caboose.Crates do
		local x = Caboose.CrateSpacing * index
		local model = ItemService.spawn("Crate", cabooseEnd * CFrame.new(x, size.Y / 2, 0))
		if model then
			model:PivotTo(model:GetPivot() + Vector3.yAxis * (model:GetExtentsSize().Y / 2 + 0.5))
		end
	end

	local groundY = -size.Y / 2
	for index = 1, Caboose.Shovels do
		local z = (index - (Caboose.Shovels + 1) / 2) * Caboose.ShovelSpacing
		local model = ItemService.spawn("Shovel", cabooseEnd * CFrame.new(-Caboose.ShovelGap, groundY, z))
		if model then
			model:PivotTo(model:GetPivot() + Vector3.yAxis * (model:GetExtentsSize().Y / 2 + 0.5))
		end
	end
end

-- Restarts the depart countdown (a Pardner was revived, §9).
function TrainService.restartDepartTimer()
	if phase == "Departing" then
		departAt = now() + TrainConfig.DepartSeconds
		publish()
	end
end

-- Turns the keyhole prompt on or off for a match, and takes any key back out.
function TrainService.setKeyholeActive(active: boolean)
	keyholeActive = active
	keyInserted = false
	keyholePrompt.Enabled = active
	train:SetAttribute("KeyInserted", false)
end

function TrainService.isKeyInserted(): boolean
	return keyInserted
end

-- Back to an empty furnace. Fuel needed = base + perPardner * pardnerCount (§5.2).
function TrainService.reset(pardnerCount: number, difficultyName: string?)
	local difficulty = Difficulty[difficultyName or GameConfig.DefaultDifficulty]
		or Difficulty[GameConfig.DefaultDifficulty]
	required = difficulty.fuelPointsBase + difficulty.fuelPointsPerPardner * math.max(pardnerCount, 1)
	delivered = 0
	departAt = nil
	boardedFor = 0
	hornReadyAt = 0
	leverLockedUntil = 0
	setPhase("Fueling")
end

-- Phase 13: the Train is only in the Workspace while the map is loaded (its prompts stay connected).
function TrainService.setActive(active: boolean)
	train.Parent = if active then Workspace else ServerStorage
end

function TrainService.init()
	notifyRemote = Net.event("Fx_Notify")
	buildTrain()
	TrainService.reset(1)
end

function TrainService.start()
	leverPrompt.Triggered:Connect(onLever)
	hornPrompt.Triggered:Connect(onHorn)
	keyholePrompt.Triggered:Connect(onKeyhole)
	RunService.Heartbeat:Connect(step)
end

return TrainService
