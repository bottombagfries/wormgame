--!strict
-- Objective 5 (§10): bring ScrapPerTrack Scrap to each broken track.
-- Setup spawns the half-buried traincars (dynamite-only scrap sources, §7) at random TraincarSpots and
-- the broken tracks at random BrokenTrackSpots (count by difficulty). Scrap dropped or thrown near a
-- broken track is used up; once a track has enough it is repaired.
-- Progress counts scrap delivered, out of brokenTracks * ScrapPerTrack.
-- Track attributes: Scrap, Needed, Repaired.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Types = require(ReplicatedStorage.Shared.Types)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local StructureBuilder = require(script.Parent.Parent.Map.StructureBuilder)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local MapService = require(script.Parent.Parent.Services.MapService)
local StructureService = require(script.Parent.Parent.Services.StructureService)

local Params = Objectives.RepairTracks.params :: { [string]: any }
local Tags = TagDefs.Tags
local SCRAP = "Scrap"

type Track = {
	model: Model,
	center: Vector3,
	scrap: number,
	label: TextLabel,
}

local tracks: { Track } = {}
local spawned: { Model } = {}

local function refresh(track: Track)
	local needed = Params.ScrapPerTrack
	local repaired = track.scrap >= needed
	track.model:SetAttribute("Scrap", track.scrap)
	track.model:SetAttribute("Needed", needed)
	track.model:SetAttribute("Repaired", repaired)
	track.label.Text = if repaired then "Track repaired" else `Broken track: {track.scrap}/{needed} scrap`
	if repaired then
		for _, descendant in track.model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Color = Params.RepairedColor -- TODO(asset): swap to a repaired-track model
			end
		end
	end
end

local function addLabel(model: Model): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrackLabel"
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
	label.Parent = billboard
	return label
end

local function spawnTraincars(parent: Instance, rng: Random)
	local spots = MapService.getMarkerCFrames(Tags.TraincarSpot, CFrame.identity)
	for _, spot in RandomUtil.sample(spots, Structures.Traincar.PerMatch, rng) do
		local model = StructureBuilder.build("Traincar", spot) -- TODO(asset): Traincar
		local _, size = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() - Vector3.yAxis * (size.Y * Params.TraincarBuryFraction))
		model.Parent = parent
		StructureService.register(model, "Traincar")
		table.insert(spawned, model)
	end
end

local function spawnTracks(count: number, parent: Instance, rng: Random)
	local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1].Position
	local candidates = {}
	for _, marker in MapService.getMarkers(Tags.BrokenTrackSpot) do
		local offset = marker.Position - trainSpot
		if Vector3.new(offset.X, 0, offset.Z).Magnitude >= Params.MinTrainDistance then
			table.insert(candidates, marker.CFrame)
		end
	end
	if #candidates == 0 then
		warn("[RepairTracks] No usable BrokenTrackSpot markers - using a spot beside the Train")
		table.insert(candidates, CFrame.new(trainSpot + Vector3.new(Params.MinTrainDistance, 0, 0)))
	end

	for _, spot in RandomUtil.sample(candidates, count, rng) do
		local model = StructureBuilder.build("BrokenTrack", spot) -- TODO(asset): BrokenTrack
		model.Parent = parent
		local cframe = model:GetBoundingBox()
		local track: Track = { model = model, center = cframe.Position, scrap = 0, label = addLabel(model) }
		refresh(track)
		table.insert(tracks, track)
		table.insert(spawned, model)
	end
end

local RepairTracks: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		local parent = MapService.getRuntimeFolder()
		if not parent then
			warn("[RepairTracks] The map has not been populated - nothing to repair")
			return
		end
		local rng = Random.new()
		local difficulty = Difficulty[context.difficulty] or Difficulty[GameConfig.DefaultDifficulty]
		spawnTraincars(parent, rng)
		spawnTracks(difficulty.brokenTracks, parent, rng)
	end,

	getProgress = function(): (number, number)
		local delivered = 0
		for _, track in tracks do
			delivered += math.min(track.scrap, Params.ScrapPerTrack)
		end
		return delivered, #tracks * Params.ScrapPerTrack
	end,

	-- Uses up loose scrap lying near a track that still needs some.
	step = function(_dt: number)
		for _, track in tracks do
			if track.scrap >= Params.ScrapPerTrack then
				continue
			end
			for _, model in ItemService.getLooseNear(track.center, Params.RepairRadius) do
				if ItemService.getItemId(model) == SCRAP and track.scrap < Params.ScrapPerTrack then
					ItemService.destroy(model)
					track.scrap += 1
					refresh(track)
				end
			end
		end
	end,

	cleanup = function()
		for _, model in spawned do
			model:Destroy()
		end
		table.clear(spawned)
		table.clear(tracks)
	end,
}

return RepairTracks
