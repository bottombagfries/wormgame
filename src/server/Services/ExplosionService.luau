--!strict
-- Blasts (§6.7): dynamite now; bile bomb and the concoction later.
-- A blast kills Pardners in range, hurts and force-burrows worms, flattens structures and cacti,
-- shortens other dynamite fuses, flings loose items, and leaves a crater mark.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ItemService = require(script.Parent.ItemService)
local PardnerService = require(script.Parent.PardnerService)
local StructureService = require(script.Parent.StructureService)
local WormService = require(script.Parent.WormService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local CRATERS_FOLDER = "Craters"

local ExplosionService = {}

-- Fires after every blast: (position, radius). DigService (Phase 9) unearths dig spots with it.
local exploded: Signal.Signal<Vector3, number> = Signal.new()
ExplosionService.exploded = exploded

local cratersFolder: Instance

local function leaveCrater(position: Vector3, radius: number)
	local groundY = Ground.surfaceBelow(position)
	if not groundY then
		return
	end
	local crater = AssetService.get("Crater") -- TODO(asset): crater decal
	local diameter = radius * ItemTuning.CraterSizeMult
	for _, descendant in crater:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Size = Vector3.new(diameter, descendant.Size.Y, diameter)
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	crater:PivotTo(CFrame.new(position.X, groundY, position.Z))
	crater.Parent = cratersFolder
	task.delay(ItemTuning.CraterSeconds, function()
		crater:Destroy()
	end)
end

-- Sets off a blast of `radius` at `position`. `causedBy` is whoever lit it, if anyone.
function ExplosionService.explode(position: Vector3, radius: number, causedBy: Player?)
	-- Visual only: the engine explosion does no damage and breaks no joints. TODO(asset): blast sound
	SoundCue.play("Explosion", position)
	local visual = Instance.new("Explosion")
	visual.Position = position
	visual.BlastRadius = radius
	visual.BlastPressure = 0
	visual.DestroyJointRadiusPercent = 0
	visual.ExplosionType = Enum.ExplosionType.NoCraters
	visual.Parent = Workspace

	-- Pardners in range die instantly.
	for player, root in PardnerService.getLiving() do
		if (root.Position - position).Magnitude <= radius then
			PardnerService.damage(player, math.huge)
		end
	end

	-- Worms: big damage and a forced burrow; the head counts if any of it is in range.
	for _, worm in WormService.getWorms() do
		if (worm.position - position).Magnitude <= radius + WormConfig.GrabRadius then
			WormService.damage(worm.player, WormConfig.DynamiteDamageFraction, position)
		end
	end

	for _, model in StructureService.getInRadius(position, radius) do
		StructureService.destroy(model)
	end

	-- Other dynamite: fuse halved (or lit at half). Everything else loose gets thrown outward.
	for _, model in ItemService.getLooseNear(position, radius) do
		if not ItemService.chainIgnite(model, ItemTuning.DynamiteChainFuseMult, causedBy) then
			local offset = model:GetPivot().Position - position
			local falloff = 1 - math.clamp(offset.Magnitude / radius, 0, 1)
			local direction = if offset.Magnitude > 0.01 then (offset.Unit + Vector3.yAxis).Unit else Vector3.yAxis
			ItemService.push(model, direction * ItemTuning.BlastFling * falloff)
		end
	end

	leaveCrater(position, radius)
	exploded:fire(position, radius)
end

-- Removes leftover craters (new match).
function ExplosionService.clearAll()
	cratersFolder:ClearAllChildren()
end

function ExplosionService.init()
	local folder = Instance.new("Folder")
	folder.Name = CRATERS_FOLDER
	folder.Parent = Workspace
	cratersFolder = folder
end

function ExplosionService.start()
	ItemService.explosionRequested:connect(ExplosionService.explode)
end

return ExplosionService
