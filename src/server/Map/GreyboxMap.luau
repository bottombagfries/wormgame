--!strict
-- Builds a flat sand baseplate with auto-placed markers (§4) so the game is playable with zero
-- user building. Only used when Workspace/MapTemplate is empty. Layout numbers: Config.Game.GreyboxMap.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)

local MAP = GameConfig.GreyboxMap
local Tags = TagDefs.Tags

local GreyboxMap = {}

local function ground(position: Vector3): Vector3
	return Vector3.new(position.X, MAP.GroundY, position.Z)
end

local function makeMarker(parent: Instance, tag: string, cframe: CFrame, size: Vector3?): Part
	local marker = Instance.new("Part")
	marker.Name = tag
	marker.Size = size or MAP.MarkerSize
	marker.CFrame = cframe
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Transparency = 1
	marker.Parent = parent
	CollectionService:AddTag(marker, tag)
	return marker
end

local function isClear(point: Vector3, placed: { Vector3 }, separation: number): boolean
	for _, other in placed do
		if (other - point).Magnitude < separation then
			return false
		end
	end
	return true
end

-- Rejection-samples `count` ground points away from the center and from everything in `placed`.
local function scatter(rng: Random, count: number, placed: { Vector3 }, separation: number): { Vector3 }
	local half = MAP.Size / 2 - MAP.EdgeMargin
	local results = {}
	for _ = 1, count do
		local point = Vector3.zero
		for _ = 1, MAP.ScatterAttempts do
			point = ground(Vector3.new(rng:NextNumber(-half, half), 0, rng:NextNumber(-half, half)))
			if point.Magnitude >= MAP.CenterClearRadius and isClear(point, placed, separation) then
				break
			end
		end
		table.insert(results, point)
		table.insert(placed, point)
	end
	return results
end

local function randomYaw(rng: Random): CFrame
	return CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

function GreyboxMap.build(mapFolder: Instance)
	local rng = Random.new(MAP.Seed)
	local counts = MAP.Counts

	-- Studio's default Baseplate would z-fight with the sand. Removed for this play session only.
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate and defaultBaseplate:IsA("BasePart") then
		defaultBaseplate:Destroy()
	end

	local sand = Instance.new("Part")
	sand.Name = "SandBaseplate"
	sand.Size = Vector3.new(MAP.Size, MAP.Thickness, MAP.Size)
	sand.Position = Vector3.new(0, MAP.GroundY - MAP.Thickness / 2, 0)
	sand.Anchored = true
	sand.Material = Enum.Material.Sand
	sand.Color = MAP.SandColor
	sand.TopSurface = Enum.SurfaceType.Smooth
	sand.Parent = mapFolder
	CollectionService:AddTag(sand, Tags.Sand)

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = mapFolder

	local placed: { Vector3 } = {}
	local function place(tag: string, position: Vector3, rotation: CFrame?)
		local point = ground(position)
		table.insert(placed, point)
		makeMarker(markers, tag, CFrame.new(point) * (rotation or CFrame.identity))
	end

	-- Fixed layout: train in the middle, track along X, ranches on a ring, town on a grid.
	place(Tags.TrainSpot, Vector3.zero)

	for i = 1, counts.BrokenTrackSpot do
		local t = (i - 0.5) / counts.BrokenTrackSpot
		place(Tags.BrokenTrackSpot, Vector3.new(-MAP.TrackHalfLength + 2 * MAP.TrackHalfLength * t, 0, 0))
	end

	for i = 1, counts.RanchSpot do
		local angle = (i - 0.5) / counts.RanchSpot * math.pi * 2
		local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * MAP.RanchRingRadius
		-- Ranches face the train.
		makeMarker(markers, Tags.RanchSpot, CFrame.lookAt(ground(position), ground(Vector3.zero)))
		table.insert(placed, ground(position))
	end

	local rows = math.ceil(counts.TownHouseSpot / MAP.TownColumns)
	for i = 0, counts.TownHouseSpot - 1 do
		local column = i % MAP.TownColumns
		local row = i // MAP.TownColumns
		local offset = Vector3.new(
			(column - (MAP.TownColumns - 1) / 2) * MAP.TownSpacing,
			0,
			(row - (rows - 1) / 2) * MAP.TownSpacing
		)
		place(Tags.TownHouseSpot, MAP.TownCenter + offset)
	end
	-- The well sits in the street between two rows of houses.
	place(Tags.TownWell, MAP.TownCenter + Vector3.new(MAP.TownSpacing / 2, 0, MAP.TownSpacing / 2))

	place(Tags.QuarrySpot, MAP.QuarryPosition)

	-- Everything else is scattered.
	local scattered = {
		{ tag = Tags.ChurchSpot, count = counts.ChurchSpot },
		{ tag = Tags.LookoutSpot, count = counts.LookoutSpot },
		{ tag = Tags.TraincarSpot, count = counts.TraincarSpot },
		{ tag = Tags.StagecoachSpot, count = counts.StagecoachSpot },
		{ tag = Tags.SignalFireSpot, count = counts.SignalFireSpot },
	}
	for _, entry in scattered do
		for _, point in scatter(rng, entry.count, placed, MAP.MinSeparation) do
			makeMarker(markers, entry.tag, CFrame.new(point) * randomYaw(rng))
		end
	end
	for _, point in scatter(rng, counts.CactusSpot, placed, MAP.CactusSeparation) do
		makeMarker(markers, Tags.CactusSpot, CFrame.new(point) * randomYaw(rng))
	end

	-- Volumes
	for _, area in MAP.DigAreas do
		makeMarker(markers, Tags.DigArea, CFrame.new(ground(area.Position)), area.Size)
	end
	for _, area in MAP.LooseItemAreas do
		makeMarker(markers, Tags.LooseItemArea, CFrame.new(ground(area.Position)), area.Size)
	end
end

return GreyboxMap
