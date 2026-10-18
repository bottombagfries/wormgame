--!strict
-- Reads the map layout from marker parts in Workspace/MapTemplate (§4) and populates it each match:
-- watertower, ranches (Pardner spawns), town houses with loot, the town well, the Church and its
-- revive ring, the quarry, lookout towers with chests, cacti (some with fruit), and loose sand loot
-- including chests with kit guarantees.
--
-- Objective-only markers (TraincarSpot, BrokenTrackSpot, StagecoachSpot, SignalFireSpot, DigArea)
-- are used by the objective modules (Phase 9), since §5.3 says their things only spawn when active.
--
-- Everything spawned per match goes in Workspace/MapRuntime and is removed by clearRuntime().

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Loot = require(ReplicatedStorage.Shared.Config.Loot)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Types = require(ReplicatedStorage.Shared.Types)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local Chests = require(script.Parent.Parent.Map.Chests)
local GreyboxMap = require(script.Parent.Parent.Map.GreyboxMap)
local Quarry = require(script.Parent.Parent.Map.Quarry)
local StructureBuilder = require(script.Parent.Parent.Map.StructureBuilder)
local VendingMachine = require(script.Parent.Parent.Map.VendingMachine)
local Well = require(script.Parent.Parent.Map.Well)
local ItemService = require(script.Parent.ItemService)
local StructureService = require(script.Parent.StructureService)

local Debug = GameConfig.Debug
local Tags = TagDefs.Tags

local MAP_FOLDER = "MapTemplate"
local RUNTIME_FOLDER = "MapRuntime"
local MARKER_LABEL_SIZE = UDim2.fromOffset(120, 18)
local SAND_PROBE_HEIGHT = 200 -- loose loot looks down from this high, so roofs count as "not sand"

local MapService = {}

local mapFolder: Instance
local runtime: Folder? = nil
local warnedTags: { [string]: boolean } = {}
local pardnerSpawns: { CFrame } = {}
local ranchHouses: { Model } = {}
local churchRing: BasePart? = nil
local summary: { [string]: number } = {}

local function getOrCreateFolder(name: string): Instance
	local existing = Workspace:FindFirstChild(name)
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	return folder
end

local function count(what: string, amount: number?)
	summary[what] = (summary[what] or 0) + (amount or 1)
end

local function labelMarker(marker: BasePart, tag: string)
	if not TagDefs.Volumes[tag] then
		marker.Transparency = Debug.MarkerTransparency
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MarkerLabel"
	billboard.Size = MARKER_LABEL_SIZE
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.MaxDistance = Debug.LabelMaxDistance
	billboard.LightInfluence = 0
	billboard.Parent = marker

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 240, 120)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = tag
	label.Parent = billboard
end

-- Phase 2 checkpoint helper: something tall to climb.
local function spawnTestWall()
	local wall = Instance.new("Part")
	wall.Name = "DebugClimbWall"
	wall.Size = Debug.TestWallSize
	wall.Position = Debug.TestWallPosition + Vector3.new(0, Debug.TestWallSize.Y / 2, 0)
	wall.Anchored = true
	wall.Material = Enum.Material.Brick
	wall.Color = Color3.fromRGB(150, 110, 90)
	wall.Parent = mapFolder
end

-- The lobby spawn next to the Train. Any other SpawnLocation (such as the default one at the origin,
-- under the Train) is switched off for this play session.
local function setupLobbySpawn()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Enabled = false
		end
	end

	local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]
	local size = GameConfig.TemporarySpawnSize
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PardnerSpawn"
	spawn.Size = size
	spawn.CFrame = trainSpot * CFrame.new(GameConfig.TemporarySpawnOffset + Vector3.new(0, size.Y / 2, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = mapFolder
end

-- Population helpers ----------------------------------------------------------------------------

-- { SmallCoal = 2, Bed = 1 } -> { "Bed", "SmallCoal", "SmallCoal" } (sorted, so a seed repeats).
local function expandLoot(lootTable: { [string]: number }): { string }
	local ids = {}
	for id in lootTable do
		table.insert(ids, id)
	end
	table.sort(ids)
	local list = {}
	for _, id in ids do
		for _ = 1, lootTable[id] do
			table.insert(list, id)
		end
	end
	return list
end

-- Spawns an item resting on `point` (a floor or ground surface).
local function spawnItemOn(itemId: string, point: Vector3, rng: Random): Model?
	local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local model = ItemService.spawn(itemId, CFrame.new(point) * yaw)
	if model then
		local lift = model:GetExtentsSize().Y / 2 + Structures.Placement.LootLift
		model:PivotTo(CFrame.new(point + Vector3.yAxis * lift) * yaw)
	end
	return model
end

local function placeStructure(assetId: string, defId: string?, cframe: CFrame): Model
	local model = StructureBuilder.build(assetId, cframe)
	model.Parent = runtime
	if defId then
		StructureService.register(model, defId)
	end
	count(assetId)
	return model
end

local function spawnLoot(model: Model, itemIds: { string }, rng: Random)
	local points = StructureBuilder.lootPoints(model, #itemIds, rng)
	for index, itemId in itemIds do
		spawnItemOn(itemId, points[index], rng)
	end
	count("loot items", #itemIds)
end

-- A house of `variant` with a random tier (its loot table), body color and trim (§7, §7.1).
local function spawnHouse(variant: string, cframe: CFrame, rng: Random): Model
	local House = Structures.House
	local model = placeStructure(`House{variant}`, "House", cframe)
	StructureBuilder.paint(model, RandomUtil.pick(House.Colors, rng), RandomUtil.pick(House.Trims, rng))
	local tier = rng:NextInteger(1, House.Tiers)
	model:SetAttribute("Tier", tier)
	spawnLoot(model, expandLoot(Loot.House[variant][tier]), rng)
	return model
end

-- In front of a model's doorway (its -Z face), `gap` studs out, at ground level.
local function inFrontOf(model: Model, gap: number): CFrame
	local cframe, size = model:GetBoundingBox()
	return cframe * CFrame.new(0, -size.Y / 2, -(size.Z / 2 + gap))
end

local function spawnRanches(rng: Random)
	local Ranch = Structures.Ranch
	for _, marker in MapService.getMarkers(Tags.RanchSpot) do
		local house = spawnHouse(Ranch.HouseVariant, marker.CFrame, rng)
		placeStructure("Shelter", "Shelter", marker.CFrame * CFrame.new(Ranch.ShelterOffset))
		table.insert(pardnerSpawns, inFrontOf(house, Ranch.SpawnGap))
		table.insert(ranchHouses, house)
		-- TODO(Phase 9): the OpenSafe objective puts its safe in one ranch house.
	end
end

local function spawnChurch(trainSpot: CFrame, rng: Random)
	local fallback = trainSpot * CFrame.new(Debug.TestChurchOffset)
	local spot = if Debug.Enabled and Debug.ChurchNearTrain
		then fallback
		else RandomUtil.pick(MapService.getMarkerCFrames(Tags.ChurchSpot, fallback), rng) -- one per match (§4)

	local church = placeStructure("Church", "Church", spot)
	local Church = Structures.Church
	local contents = { "Pulpit" }
	for _ = 1, rng:NextInteger(Church.PewsMin, Church.PewsMax) do
		table.insert(contents, "Pew")
	end
	spawnLoot(church, contents, rng)
	-- TODO: ladder at the back (ladders are not built yet)

	-- The yellow revive ring sits in front of the Church and is not part of it, so it survives a
	-- collapse. A model's own part named "ReviveRing" sets where it goes.
	local ringCFrame = inFrontOf(church, Church.RingGap + Church.ReviveRadius)
	local custom = church:FindFirstChild("ReviveRing", true)
	if custom and custom:IsA("BasePart") then
		ringCFrame = custom.CFrame
		custom:Destroy()
	end
	local diameter = Church.ReviveRadius * 2
	local ring = Instance.new("Part") -- TODO(asset): revive ring
	ring.Name = "ReviveRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, diameter, diameter)
	ring.Color = Church.RingColor
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.5
	ring.CFrame = CFrame.new(ringCFrame.Position + Vector3.yAxis * 0.1) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Parent = runtime
	churchRing = ring
end

-- 3 towers spread as far apart as possible, each with 2 chests on the deck (§4, §7).
local function spawnLookouts(rng: Random)
	local Lookout = Structures.LookoutTower
	local markers = MapService.getMarkers(Tags.LookoutSpot)
	local positions = {}
	for _, marker in markers do
		table.insert(positions, marker.Position)
	end
	for _, index in Geometry.farthestPointSample(positions, Lookout.PerMatch, rng) do
		local tower = placeStructure("LookoutTower", "LookoutTower", markers[index].CFrame)
		local cframe, size = tower:GetBoundingBox()
		local deckTop = cframe * CFrame.new(0, size.Y / 2, 0)
		for chest = 1, Lookout.Chests do
			local x = (chest - (Lookout.Chests + 1) / 2) * Lookout.ChestSpacing
			Chests.plan(deckTop * CFrame.new(x, 0, 0), false)
		end
	end
end

local function spawnCacti(rng: Random)
	for _, marker in MapService.getMarkers(Tags.CactusSpot) do
		local cactus = placeStructure("CactusTall", "Cactus", marker.CFrame)
		if rng:NextNumber() < Loot.Cactus.FruitChance then
			local cframe, size = cactus:GetBoundingBox()
			spawnItemOn("CactusFruit", (cframe * CFrame.new(0, size.Y / 2, 0)).Position, rng)
			count("cactus fruit")
		end
	end
end

-- A random spot on open sand inside one of the LooseItemArea volumes, or nil.
local function looseSpot(areas: { BasePart }, rng: Random): Vector3?
	for _ = 1, Structures.Placement.Attempts do
		local area = RandomUtil.pick(areas, rng)
		local point = Geometry.randomPointInPart(area, rng)
		local surfaceY, isSand = Ground.surfaceBelow(point, SAND_PROBE_HEIGHT)
		local spot = if surfaceY then Vector3.new(point.X, surfaceY, point.Z) else nil
		if spot and isSand and not StructureService.isInside(spot + Vector3.yAxis) then
			return spot
		end
	end
	return nil
end

-- Tumbleweeds, backpacks, crates and chests scattered on the sand (Config.Loot.Loose).
local function spawnLooseLoot(rng: Random)
	local areas = MapService.getMarkers(Tags.LooseItemArea)
	if #areas == 0 then
		return
	end
	local kinds = {}
	for kind in Loot.Loose do
		table.insert(kinds, kind)
	end
	table.sort(kinds)
	for _, kind in kinds do
		for _ = 1, Loot.Loose[kind] do
			local spot = looseSpot(areas, rng)
			if not spot then
				continue
			end
			if kind == "Chest" then
				Chests.plan(CFrame.new(spot) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), true)
			else
				spawnItemOn(kind, spot, rng)
			end
			count(`loose {kind}`)
		end
	end
end

local function printSummary()
	local lines = {}
	for what, amount in summary do
		table.insert(lines, `{what}={amount}`)
	end
	table.sort(lines)
	print(`[MapService] Populated: {table.concat(lines, ", ")}`)
end

-- Public API ------------------------------------------------------------------------------------

-- All marker parts with this tag that are currently in the Workspace.
function MapService.getMarkers(tag: string): { BasePart }
	local markers = {}
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(Workspace) then
			table.insert(markers, instance)
		end
	end
	return markers
end

-- Marker CFrames for a tag. If the map has none, warns once and returns just `fallback`
-- so callers can still spawn a greybox instead of erroring.
function MapService.getMarkerCFrames(tag: string, fallback: CFrame): { CFrame }
	local cframes = {}
	for _, marker in MapService.getMarkers(tag) do
		table.insert(cframes, marker.CFrame)
	end
	if #cframes == 0 then
		if not warnedTags[tag] then
			warnedTags[tag] = true
			warn(`[MapService] No "{tag}" markers in Workspace/{MAP_FOLDER} - using a fallback position`)
		end
		table.insert(cframes, fallback)
	end
	return cframes
end

-- Spawns this match's structures and loot. Call after ItemService.clearAll().
function MapService.populate(_settings: Types.MatchSettings)
	MapService.clearRuntime()
	local folder = Instance.new("Folder")
	folder.Name = RUNTIME_FOLDER
	folder.Parent = Workspace
	runtime = folder

	local rng = Random.new()
	local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]

	placeStructure("Watertower", "Watertower", trainSpot * CFrame.new(Structures.Watertower.Offset))
	-- TODO: watertower ladder (ladders are not built yet)
	spawnRanches(rng)
	for _, marker in MapService.getMarkers(Tags.TownHouseSpot) do
		spawnHouse(RandomUtil.pick(Structures.House.Variants, rng), marker.CFrame, rng)
	end
	if Debug.Enabled and Debug.SpawnTestHouse then
		spawnHouse(RandomUtil.pick(Structures.House.Variants, rng), trainSpot * CFrame.new(Debug.TestHouseOffset), rng)
	end
	Well.spawn(MapService.getMarkerCFrames(Tags.TownWell, trainSpot * CFrame.new(60, 0, -60))[1], folder)
	count("TownWell")
	spawnChurch(trainSpot, rng)
	Quarry.spawn(MapService.getMarkerCFrames(Tags.QuarrySpot, trainSpot * CFrame.new(150, 0, -150))[1], folder)
	count("Quarry")
	spawnLookouts(rng)
	spawnCacti(rng)
	spawnLooseLoot(rng)
	count("Chest", Chests.spawnPlanned(folder, rng))

	if Debug.Enabled and Debug.LogMapSummary then
		printSummary()
	end
end

-- Removes everything populate() spawned (structures, chests, well, quarry carts). Items are
-- ItemService's to clear.
function MapService.clearRuntime()
	StructureService.clearAll()
	Chests.clear()
	Well.clear()
	Quarry.clear()
	VendingMachine.clear()
	if runtime then
		runtime:Destroy()
	end
	runtime = nil
	churchRing = nil
	table.clear(pardnerSpawns)
	table.clear(ranchHouses)
	table.clear(summary)
end

-- The folder this match's spawned things live in (objective modules put theirs here too), or nil
-- before populate().
function MapService.getRuntimeFolder(): Folder?
	return runtime
end

-- This match's ranch houses (the OpenSafe objective hides its safe in one).
function MapService.getRanchHouses(): { Model }
	return ranchHouses
end

-- Where loot goes inside a structure (StructureBuilder.lootPoints).
function MapService.getLootPoints(model: Model, amount: number, rng: Random): { Vector3 }
	return StructureBuilder.lootPoints(model, amount, rng)
end

-- A random open-sand spot in the LooseItemAreas (not inside a structure), or nil.
function MapService.findLooseSpot(rng: Random): Vector3?
	local areas = MapService.getMarkers(Tags.LooseItemArea)
	return if #areas > 0 then looseSpot(areas, rng) else nil
end

-- Spawns `itemId` at a random open-sand spot in the LooseItemAreas (respawning tumbleweeds, ...).
-- Returns nil if no spot was found.
function MapService.spawnLooseItem(itemId: string): Model?
	local rng = Random.new()
	local areas = MapService.getMarkers(Tags.LooseItemArea)
	local spot = if #areas > 0 then looseSpot(areas, rng) else nil
	return if spot then spawnItemOn(itemId, spot, rng) else nil
end

-- Where Pardners start a match: in front of the ranch houses (§4).
function MapService.getPardnerSpawns(): { CFrame }
	return pardnerSpawns
end

-- The Church's revive ring for this match (ReviveService), or nil before populate().
function MapService.getChurchRing(): BasePart?
	return churchRing
end

function MapService.init()
	mapFolder = getOrCreateFolder(MAP_FOLDER)

	if #mapFolder:GetChildren() == 0 then
		print(`[MapService] Workspace/{MAP_FOLDER} is empty - building the greybox map`)
		GreyboxMap.build(mapFolder)
	end
	setupLobbySpawn()
end

function MapService.start()
	local markerSummary = {}
	for _, tag in TagDefs.MapMarkers do
		local markers = MapService.getMarkers(tag)
		if #markers == 0 then
			warnedTags[tag] = true
			warn(`[MapService] Map has no "{tag}" markers - a fallback position will be used`)
		end
		table.insert(markerSummary, `{tag}={#markers}`)

		if Debug.Enabled and Debug.ShowMarkers and tag ~= Tags.Sand then
			for _, marker in markers do
				labelMarker(marker, tag)
			end
		end
	end
	if Debug.Enabled and Debug.LogBootstrap then
		print(`[MapService] Markers: {table.concat(markerSummary, ", ")}`)
	end

	if Debug.Enabled and Debug.SpawnTestWall then
		spawnTestWall()
	end

	-- Well tokens and quarry dynamite tick while a match is populated.
	RunService.Heartbeat:Connect(function(dt)
		if runtime then
			Well.step(dt)
			Quarry.step(dt)
			VendingMachine.step(dt)
		end
	end)
end

return MapService
