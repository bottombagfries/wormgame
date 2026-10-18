--!strict
-- Builds structure models. A real model from ReplicatedStorage/Assets/Structures wins (§3); without
-- one, a walk-in greybox is built from the size in Config/Assets and the shape kind in
-- Config/Structures.Greybox (a plain AssetService box would be solid, so nobody could go inside).
--
-- Every structure comes back anchored, with its pivot at the middle of its base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)

local Greybox = Structures.Greybox

local StructureBuilder = {}

local function addPart(model: Model, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.WoodPlanks
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.Parent = model
	return part
end

-- Floor, roof, and four walls; the front (-Z) wall has a doorway. Parts are named so house colors
-- apply (Wall = body, Roof = trim).
local function buildShell(model: Model, size: Vector3, color: Color3): BasePart
	local t = Greybox.WallThickness
	local halfX, halfZ = size.X / 2, size.Z / 2
	local wallHeight = size.Y - t * 2
	local wallY = t + wallHeight / 2

	local floor = addPart(model, "Floor", Vector3.new(size.X, t, size.Z), CFrame.new(0, t / 2, 0), color)
	addPart(model, "Roof", Vector3.new(size.X, t, size.Z), CFrame.new(0, size.Y - t / 2, 0), color)

	addPart(model, "Wall", Vector3.new(size.X, wallHeight, t), CFrame.new(0, wallY, halfZ - t / 2), color)
	addPart(model, "Wall", Vector3.new(t, wallHeight, size.Z), CFrame.new(-halfX + t / 2, wallY, 0), color)
	addPart(model, "Wall", Vector3.new(t, wallHeight, size.Z), CFrame.new(halfX - t / 2, wallY, 0), color)

	-- Front wall: two pieces either side of the door, and a lintel above it.
	local doorWidth = math.min(Greybox.DoorWidth, size.X - t * 4)
	local doorHeight = math.min(Greybox.DoorHeight, wallHeight - t)
	local sideWidth = (size.X - doorWidth) / 2
	local frontZ = -halfZ + t / 2
	addPart(
		model,
		"Wall",
		Vector3.new(sideWidth, wallHeight, t),
		CFrame.new(-halfX + sideWidth / 2, wallY, frontZ),
		color
	)
	addPart(
		model,
		"Wall",
		Vector3.new(sideWidth, wallHeight, t),
		CFrame.new(halfX - sideWidth / 2, wallY, frontZ),
		color
	)
	local lintelHeight = wallHeight - doorHeight
	addPart(
		model,
		"Wall",
		Vector3.new(doorWidth, lintelHeight, t),
		CFrame.new(0, t + doorHeight + lintelHeight / 2, frontZ),
		color
	)
	return floor
end

-- Four legs and a deck on top (the deck's top surface is at `deckHeight`).
local function buildPlatform(model: Model, size: Vector3, deckHeight: number, color: Color3): BasePart
	local leg = Greybox.LegThickness
	local deck = Greybox.DeckThickness
	local legHeight = deckHeight - deck
	local insetX, insetZ = size.X / 2 - leg / 2, size.Z / 2 - leg / 2
	local base: BasePart? = nil
	for _, corner in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
		local part = addPart(
			model,
			"Leg",
			Vector3.new(leg, legHeight, leg),
			CFrame.new(corner.X * insetX, legHeight / 2, corner.Z * insetZ),
			color
		)
		base = base or part
	end
	addPart(model, "Deck", Vector3.new(size.X, deck, size.Z), CFrame.new(0, deckHeight - deck / 2, 0), color)
	return base :: BasePart
end

-- Builds `assetId` with its base centered on `cframe`.
function StructureBuilder.build(assetId: string, cframe: CFrame): Model
	local kind = Greybox.Kinds[assetId]
	if AssetService.hasUserModel(assetId) or not kind then
		local model = AssetService.get(assetId) -- TODO(asset): falls back to a plain greybox box
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		local boundsCFrame, size = model:GetBoundingBox()
		local pivotToBounds = model:GetPivot():ToObjectSpace(boundsCFrame)
		model:PivotTo(cframe * CFrame.new(0, size.Y / 2, 0) * pivotToBounds:Inverse())
		return model
	end

	-- TODO(asset): walk-in greybox for this structure
	local def = AssetService.getDef(assetId)
	local size = def.size
	local model = Instance.new("Model")
	model.Name = assetId

	local base: BasePart
	if kind == "Shell" then
		base = buildShell(model, size, def.color)
	elseif kind == "Tank" then
		local deckHeight = size.Y * (1 - Greybox.TankFraction)
		base = buildPlatform(model, size, deckHeight, def.color)
		local tankHeight = size.Y - deckHeight
		addPart(
			model,
			"Tank",
			Vector3.new(size.X, tankHeight, size.Z),
			CFrame.new(0, deckHeight + tankHeight / 2, 0),
			def.color
		)
	else
		base = buildPlatform(model, size, size.Y, def.color)
	end
	AssetService.addLabel(base, assetId, size.Y)

	-- Pivot at the middle of the base, then move into place.
	model.WorldPivot = CFrame.identity
	model:PivotTo(cframe)
	model.PrimaryPart = base
	model:SetAttribute("AssetId", assetId)
	model:SetAttribute("Greybox", true)
	return model
end

-- House colors (§7): parts named like Config.Structures.House.BodyPartNames get `body`, TrimPartNames get `trim`.
function StructureBuilder.paint(model: Model, body: Color3, trim: Color3)
	local House = Structures.House
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			if table.find(House.BodyPartNames, descendant.Name) then
				descendant.Color = body
			elseif table.find(House.TrimPartNames, descendant.Name) then
				descendant.Color = trim
			end
		end
	end
end

-- Where loot goes inside a structure: its "LootPoint" attachments if it has any, otherwise `count`
-- random points on the floor of its bounding box (§7.1). Returned positions are on the floor surface.
function StructureBuilder.lootPoints(model: Model, count: number, rng: Random): { Vector3 }
	local points: { Vector3 } = {}
	local attachments = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Attachment") and descendant.Name == "LootPoint" then
			table.insert(attachments, descendant)
		end
	end
	if #attachments > 0 then
		for index = 1, count do
			table.insert(points, attachments[(index - 1) % #attachments + 1].WorldPosition)
		end
		return points
	end

	local boundsCFrame, size = model:GetBoundingBox()
	local margin = Greybox.WallThickness + Greybox.LootMargin
	local halfX = math.max(0, size.X / 2 - margin)
	local halfZ = math.max(0, size.Z / 2 - margin)
	local floorY = -size.Y / 2 + Greybox.WallThickness
	for _ = 1, count do
		local offset = Vector3.new(rng:NextNumber(-halfX, halfX), floorY, rng:NextNumber(-halfZ, halfZ))
		table.insert(points, boundsCFrame:PointToWorldSpace(offset))
	end
	return points
end

return StructureBuilder
