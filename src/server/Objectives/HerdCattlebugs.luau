--!strict
-- Objective 4 (§10): `cattlebugs` bugs wander the sand. Throw dandylions (Dandylion Bundle kit) to lure
-- them, one flower at a time, into the pen behind the caboose. Bundles wait behind the caboose and
-- come from the vending machine. NPCService does the bugs and flowers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Types = require(ReplicatedStorage.Shared.Types)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local VendingMachine = require(script.Parent.Parent.Map.VendingMachine)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local MapService = require(script.Parent.Parent.Services.MapService)
local NPCService = require(script.Parent.Parent.Services.NPCService)
local TrainService = require(script.Parent.Parent.Services.TrainService)

local Params = Objectives.HerdCattlebugs.params :: { [string]: any }
local Tags = TagDefs.Tags
local BUNDLE = "DandylionBundle"

local penRing: BasePart? = nil
local total = 0

local function buildPen(parent: Instance, center: Vector3): BasePart
	local diameter = Params.PenRadius * 2
	local ring = Instance.new("Part") -- TODO(asset): cattlebug pen (fence)
	ring.Name = "CattlebugPen"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, diameter, diameter)
	ring.Color = Params.PenColor
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.5
	ring.CFrame = CFrame.new(center + Vector3.yAxis * 0.1) * CFrame.Angles(0, 0, math.pi / 2)
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
	label.Text = "Cattlebug pen"
	label.Parent = billboard
	return ring
end

local HerdCattlebugs: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		local parent = MapService.getRuntimeFolder()
		if not parent then
			warn("[HerdCattlebugs] The map has not been populated - no cattlebugs")
			return
		end
		local rng = Random.new()
		local difficulty = Difficulty[context.difficulty] or Difficulty[GameConfig.DefaultDifficulty]
		local caboose = TrainService.getCabooseCFrame()

		local center = (caboose * CFrame.new(Params.PenOffset)).Position
		penRing = buildPen(parent, center)

		local positions = {}
		local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1].Position
		for _ = 1, difficulty.cattlebugs do
			local spot = MapService.findLooseSpot(rng)
			if not spot then
				local fallback = trainSpot + Params.FallbackOffset
				spot = Vector3.new(fallback.X, Ground.sandBelow(fallback) or fallback.Y, fallback.Z)
			end
			table.insert(positions, spot :: Vector3)
		end
		total = #positions
		NPCService.spawnCattlebugs(positions, center, Params.PenRadius)

		-- Bundles behind the caboose, and more from the vending machine (§7).
		for index = 1, Params.Bundles do
			ItemService.spawn(BUNDLE, caboose * CFrame.new(Params.BundleOffset + Vector3.new(0, 1, index * 2)))
		end
		VendingMachine.addProduct(BUNDLE, parent, caboose)
	end,

	getProgress = function(): (number, number)
		return math.min(NPCService.getDelivered(), total), total
	end,

	cleanup = function()
		NPCService.clear()
		if penRing then
			penRing:Destroy()
		end
		penRing = nil
		total = 0
	end,
}

return HerdCattlebugs
