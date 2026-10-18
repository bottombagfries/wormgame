--!strict
-- Objective 6 (§10): two stagecoaches each start with two Sassparilla crates (6 bottles each).
-- Bring crates to the drop-off ring behind the caboose; the bottles still in them count toward
-- `sassparillaBottles`. Hard impacts break bottles: broken = floor(impactSpeed / BottleBreakSpeed).
-- Whenever a crate is delivered, smashed empty, or otherwise lost, a new one appears at its coach.
-- Crate attribute: Bottles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Types = require(ReplicatedStorage.Shared.Types)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local StructureBuilder = require(script.Parent.Parent.Map.StructureBuilder)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local MapService = require(script.Parent.Parent.Services.MapService)
local TrainService = require(script.Parent.Parent.Services.TrainService)

local Params = Objectives.DeliverSassparilla.params :: { [string]: any }
local Tags = TagDefs.Tags
local CRATE = "SassparillaCrate"

type Coach = {
	model: Model,
	slots: { CFrame }, -- where its crates wait
}

type Crate = {
	model: Model,
	coach: Coach,
	slot: CFrame,
	bottles: number,
	lastVelocity: Vector3,
	wasLoose: boolean,
	breakReadyAt: number,
	handled: boolean, -- delivered or smashed; its replacement is already on the way
}

local coaches: { Coach } = {}
local crates: { [Model]: Crate } = {}
local active = false
local delivered = 0
local needed = 0
local dropOff: BasePart? = nil

local spawnCrate: (coach: Coach, slot: CFrame) -> ()

local function onCrateGone(crate: Crate)
	crates[crate.model] = nil
	if active then
		spawnCrate(crate.coach, crate.slot)
	end
end

function spawnCrate(coach: Coach, slot: CFrame)
	local model = ItemService.spawn(CRATE, slot)
	if not model then
		return
	end
	model:PivotTo(slot + Vector3.yAxis * (model:GetExtentsSize().Y / 2 + 0.5))
	model:SetAttribute("Bottles", ItemTuning.BottlesPerCrate)
	local crate: Crate = {
		model = model,
		coach = coach,
		slot = slot,
		bottles = ItemTuning.BottlesPerCrate,
		lastVelocity = Vector3.zero,
		wasLoose = true,
		breakReadyAt = 0,
		handled = false,
	}
	crates[model] = crate
	-- Swallowed, fallen out of the world, delivered, smashed: a new crate takes its place.
	model.Destroying:Connect(function()
		onCrateGone(crate)
	end)
end

local function spawnCoaches(parent: Instance, rng: Random)
	local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]
	local spots = MapService.getMarkerCFrames(Tags.StagecoachSpot, trainSpot * CFrame.new(Params.FallbackOffset))
	local Stagecoach = Structures.Stagecoach
	for _, spot in RandomUtil.sample(spots, Stagecoach.PerMatch, rng) do
		local model = StructureBuilder.build("Stagecoach", spot) -- TODO(asset): Stagecoach
		model.Parent = parent
		local cframe, size = model:GetBoundingBox()
		local coach: Coach = { model = model, slots = {} }
		for index = 1, Stagecoach.Crates do
			local along = (index - (Stagecoach.Crates + 1) / 2) * (size.X / Stagecoach.Crates)
			local slot = cframe * CFrame.new(along, -size.Y / 2, size.Z / 2 + Params.CrateGap)
			table.insert(coach.slots, slot)
			spawnCrate(coach, slot)
		end
		table.insert(coaches, coach)
	end
end

local function buildDropOff(parent: Instance)
	local caboose = TrainService.getCabooseCFrame()
	local center = caboose * CFrame.new(-Params.DropOffGap, 0, 0)
	local diameter = Params.DropOffRadius * 2
	local ring = Instance.new("Part") -- TODO(asset): drop-off marking
	ring.Name = "SassparillaDropOff"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, diameter, diameter)
	ring.Color = Params.RingColor
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.5
	ring.CFrame = CFrame.new(center.Position + Vector3.yAxis * 0.1) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Parent = parent

	local billboard = Instance.new("BillboardGui")
	billboard.Size = Params.LabelSize
	billboard.StudsOffsetWorldSpace = Vector3.new(0, Params.LabelHeight, 0)
	billboard.MaxDistance = GameConfig.Debug.LabelMaxDistance
	billboard.LightInfluence = 0
	billboard.Parent = ring
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "Sassparilla drop-off"
	label.Parent = billboard

	dropOff = ring
end

-- Sudden changes in a loose crate's velocity are impacts; each one breaks bottles by its size.
-- Returns true if the crate is now empty.
local function checkImpact(crate: Crate, primary: BasePart, now: number): boolean
	local velocity = primary.AssemblyLinearVelocity
	local impact = (crate.lastVelocity - velocity).Magnitude
	crate.lastVelocity = velocity
	if impact < ItemTuning.BottleBreakSpeed or now < crate.breakReadyAt then
		return false
	end
	crate.breakReadyAt = now + Params.BreakCooldown
	local broken = math.floor(impact / ItemTuning.BottleBreakSpeed)
	crate.bottles = math.max(0, crate.bottles - broken)
	crate.model:SetAttribute("Bottles", crate.bottles) -- TODO(asset): glass-breaking sound
	return crate.bottles == 0
end

local DeliverSassparilla: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		local parent = MapService.getRuntimeFolder()
		if not parent then
			warn("[DeliverSassparilla] The map has not been populated - no stagecoaches")
			return
		end
		local difficulty = Difficulty[context.difficulty] or Difficulty[GameConfig.DefaultDifficulty]
		needed = difficulty.sassparillaBottles
		delivered = 0
		active = true
		buildDropOff(parent)
		spawnCoaches(parent, Random.new())
	end,

	getProgress = function(): (number, number)
		return math.min(delivered, needed), needed
	end,

	step = function(_dt: number)
		local zone = dropOff
		local now = os.clock()
		-- Collected first: destroying a crate spawns its replacement, which must not happen mid-loop.
		local finished: { Model } = {}
		for model, crate in crates do
			local primary = model.PrimaryPart
			if crate.handled or not primary then
				continue
			end
			if ItemService.findLooseItem(primary) ~= model then
				crate.wasLoose = false -- carried: no impacts, and its velocity is the carrier's
				continue
			end
			if not crate.wasLoose then
				-- Just thrown or dropped: start measuring from here, the release itself is not an impact.
				crate.wasLoose = true
				crate.lastVelocity = primary.AssemblyLinearVelocity
				continue
			end

			local smashed = checkImpact(crate, primary, now)
			local offset = if zone then primary.Position - zone.Position else nil
			local inZone = offset ~= nil and Vector3.new(offset.X, 0, offset.Z).Magnitude <= Params.DropOffRadius
			if inZone and not smashed then
				delivered += crate.bottles
			end
			if smashed or inZone then
				crate.handled = true
				table.insert(finished, model)
			end
		end
		for _, model in finished do
			model:Destroy()
		end
	end,

	cleanup = function()
		active = false
		local models = {}
		for model in crates do
			table.insert(models, model)
		end
		for _, model in models do
			model:Destroy()
		end
		table.clear(crates)
		for _, coach in coaches do
			coach.model:Destroy()
		end
		table.clear(coaches)
		if dropOff then
			dropOff:Destroy()
		end
		dropOff = nil
	end,
}

return DeliverSassparilla
