--!strict
-- Destructible structures (§7): HP, damage, collapse, scrap.
--
-- MapService registers each structure it spawns with its Config.Structures.Defs id. Damage comes
-- from worm pounces (WormService) and blasts (ExplosionService). At 0 HP the structure collapses:
-- Pardners inside it or standing on it die, loose loot inside falls to the ground (it was never
-- attached), and Scrap drops when scrap is enabled for the match.
-- Replicated: attribute HP on the model.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ItemService = require(script.Parent.ItemService)
local PardnerService = require(script.Parent.PardnerService)

local SCRAP = "Scrap"

type Structure = {
	model: Model,
	defId: string,
	hp: number?, -- nil = indestructible
	scrap: number,
	wormDamageable: boolean,
	cframe: CFrame, -- bounding box, measured at registration
	size: Vector3,
}

export type DamageSource = "Worm" | "Explosion"

local StructureService = {}

-- Fires after a structure has collapsed: (defId, boundsCFrame, boundsSize).
local destroyed: Signal.Signal<string, CFrame, Vector3> = Signal.new()
StructureService.destroyed = destroyed

local structures: { [Model]: Structure } = {}
local scrapEnabled = false

-- Distance from a point to the nearest part of a structure's bounding box (0 if inside).
local function distanceTo(structure: Structure, point: Vector3): number
	local localPoint = structure.cframe:PointToObjectSpace(point)
	local half = structure.size / 2
	local clamped = Vector3.new(
		math.clamp(localPoint.X, -half.X, half.X),
		math.clamp(localPoint.Y, -half.Y, half.Y),
		math.clamp(localPoint.Z, -half.Z, half.Z)
	)
	return (localPoint - clamped).Magnitude
end

local function collapse(structure: Structure)
	structures[structure.model] = nil

	-- Anyone inside or on top dies (§7).
	local zoneSize = structure.size + Vector3.new(0, Structures.OnTopHeight, 0)
	local zoneCFrame = structure.cframe * CFrame.new(0, Structures.OnTopHeight / 2, 0)
	for player, root in PardnerService.getLiving() do
		if Geometry.isPointInBox(zoneCFrame, zoneSize, root.Position) then
			PardnerService.damage(player, math.huge)
		end
	end

	structure.model:Destroy() -- TODO(asset): collapse effect / debris / sound

	if scrapEnabled then
		local center = structure.cframe.Position
		local bottom = center.Y - structure.size.Y / 2
		local rng = Random.new()
		for _ = 1, structure.scrap do
			local offset = Vector3.new(
				rng:NextNumber(-Structures.ScrapScatter, Structures.ScrapScatter),
				0,
				rng:NextNumber(-Structures.ScrapScatter, Structures.ScrapScatter)
			)
			ItemService.spawn(
				SCRAP,
				CFrame.new(center.X + offset.X, bottom + Structures.Placement.LootLift + 1, center.Z + offset.Z)
			)
		end
	end

	destroyed:fire(structure.defId, structure.cframe, structure.size)
end

-- Makes `model` a destructible structure using Config.Structures.Defs[defId].
function StructureService.register(model: Model, defId: string)
	local def = Structures.Defs[defId]
	if not def then
		warn(`[StructureService] Unknown structure "{defId}"`)
		return
	end
	local cframe, size = model:GetBoundingBox()
	structures[model] = {
		model = model,
		defId = defId,
		hp = def.hp,
		scrap = def.scrap,
		wormDamageable = def.wormDamageable,
		cframe = cframe,
		size = size,
	}
	model:SetAttribute("HP", def.hp)
	model:SetAttribute("StructureId", defId)
end

-- Worm damage only hurts structures that allow it (traincars don't, §7).
function StructureService.damage(model: Model, amount: number, source: DamageSource)
	local structure = structures[model]
	if not structure or not structure.hp then
		return
	end
	if source == "Worm" and not structure.wormDamageable then
		return
	end
	structure.hp -= amount
	model:SetAttribute("HP", math.max(0, structure.hp))
	if structure.hp <= 0 then
		collapse(structure)
	end
end

-- Whether worm attacks can hurt this structure (traincars can't, §7).
function StructureService.isWormDamageable(model: Model): boolean
	local structure = structures[model]
	return structure ~= nil and structure.hp ~= nil and structure.wormDamageable
end

-- Instant destruction (dynamite, armored carapace). Indestructible structures are ignored.
function StructureService.destroy(model: Model)
	local structure = structures[model]
	if structure and structure.hp then
		collapse(structure)
	end
end

-- Registered structures whose bounding box comes within `radius` of `position`.
function StructureService.getInRadius(position: Vector3, radius: number): { Model }
	local list = {}
	for model, structure in structures do
		if distanceTo(structure, position) <= radius then
			table.insert(list, model)
		end
	end
	return list
end

-- True if `position` is inside any registered structure (used to keep sand loot out of buildings).
function StructureService.isInside(position: Vector3): boolean
	for _, structure in structures do
		if Geometry.isPointInBox(structure.cframe, structure.size, position) then
			return true
		end
	end
	return false
end

-- Scrap only spawns when Repair Tracks is active (§5.3); MatchService sets this per match.
function StructureService.setScrapEnabled(enabled: boolean)
	scrapEnabled = enabled
end

-- Forgets every structure (MapService destroys the models).
function StructureService.clearAll()
	table.clear(structures)
end

return StructureService
