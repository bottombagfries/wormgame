--!strict
-- Objective 3 (§10): light a tumbleweed at the Train's furnace (it then burns for 80 s) and carry it
-- to an unlit signal fire before it burns out. `signalFires` fires spawn at random SignalFireSpots.
-- A tumbleweed that burns out, or is used up lighting a fire, is replaced by a new one on the sand.
-- Fire attributes: Lit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Types = require(ReplicatedStorage.Shared.Types)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local StructureBuilder = require(script.Parent.Parent.Map.StructureBuilder)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local MapService = require(script.Parent.Parent.Services.MapService)
local TrainService = require(script.Parent.Parent.Services.TrainService)

local Params = Objectives.LightSignalFires.params :: { [string]: any }
local Tags = TagDefs.Tags
local TUMBLEWEED = "Tumbleweed"

type Fire = {
	model: Model,
	center: Vector3,
	lit: boolean,
	label: TextLabel,
}

local fires: { Fire } = {}
local connection: Signal.Connection? = nil

local function addLabel(model: Model): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FireLabel"
	billboard.Size = Params.LabelSize
	billboard.StudsOffsetWorldSpace = Vector3.new(0, Params.LabelHeight, 0)
	billboard.MaxDistance = GameConfig.Debug.LabelMaxDistance
	billboard.LightInfluence = 0
	billboard.Parent = model.PrimaryPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "Signal fire: unlit"
	label.Parent = billboard
	return label
end

local function lightFire(fire: Fire)
	fire.lit = true
	fire.model:SetAttribute("Lit", true)
	fire.label.Text = "Signal fire: burning"
	for _, descendant in fire.model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = Params.LitColor
		end
	end
	local flame = Instance.new("Fire") -- TODO(asset): big signal fire effect + sound
	flame.Size = Params.FireSize
	flame.Parent = fire.model.PrimaryPart
end

local function spawnFires(count: number, parent: Instance, rng: Random)
	local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]
	local spots = MapService.getMarkerCFrames(Tags.SignalFireSpot, trainSpot * CFrame.new(Params.FallbackOffset))
	for _, spot in RandomUtil.sample(spots, count, rng) do
		local model = StructureBuilder.build("SignalFire", spot) -- TODO(asset): SignalFire
		model.Parent = parent
		local center = model:GetBoundingBox().Position
		table.insert(fires, { model = model, center = center, lit = false, label = addLabel(model) })
	end
end

local function unlitFireNear(position: Vector3): Fire?
	for _, fire in fires do
		if not fire.lit and (fire.center - position).Magnitude <= Params.FireRadius then
			return fire
		end
	end
	return nil
end

local LightSignalFires: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		local parent = MapService.getRuntimeFolder()
		if not parent then
			warn("[LightSignalFires] The map has not been populated - no signal fires")
			return
		end
		local difficulty = Difficulty[context.difficulty] or Difficulty[GameConfig.DefaultDifficulty]
		spawnFires(difficulty.signalFires, parent, Random.new())

		-- Keep the supply going: every tumbleweed that burns out comes back somewhere on the sand.
		connection = ItemService.fuseEnded:connect(function(itemId: string)
			if itemId == TUMBLEWEED then
				MapService.spawnLooseItem(TUMBLEWEED)
			end
		end)
	end,

	getProgress = function(): (number, number)
		local lit = 0
		for _, fire in fires do
			if fire.lit then
				lit += 1
			end
		end
		return lit, #fires
	end,

	-- Held or loose tumbleweeds catch at the furnace; burning ones light the fire they're brought to.
	step = function(_dt: number)
		local furnace = TrainService.getFurnacePosition()
		for _, model in ItemService.getItemsById(TUMBLEWEED) do
			local position = model:GetPivot().Position
			if not ItemService.isLit(model) then
				if (position - furnace).Magnitude <= Params.LightRadius then
					ItemService.light(model, nil)
				end
			else
				local fire = unlitFireNear(position)
				if fire then
					lightFire(fire)
					ItemService.destroy(model)
					MapService.spawnLooseItem(TUMBLEWEED)
				end
			end
		end
	end,

	cleanup = function()
		local current = connection
		if current then
			current:disconnect()
		end
		connection = nil
		for _, fire in fires do
			fire.model:Destroy()
		end
		table.clear(fires)
	end,
}

return LightSignalFires
