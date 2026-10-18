--!strict
-- Bullworm Rifle (§6.6): 1 shot along the aim. The shot stops at the first solid thing; a worm head it
-- passes close to takes rifle damage, drops whoever it holds and is forced under; loose dynamite it
-- passes goes off at once. The kick pushes the shooter back. TODO: kills wormlings, once they exist.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Types = require(ReplicatedStorage.Shared.Types)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local WormService = require(script.Parent.Parent.Services.WormService)

local DYNAMITE = "Dynamite"
local IGNORED_FOLDERS = { "Items", "Worms", "Ghosts", "NPCs" }

-- How far along `direction` the point is, and how far it is from the line (0 <= along <= length only).
local function nearLine(origin: Vector3, direction: Vector3, length: number, point: Vector3): (number, number)
	local along = math.clamp((point - origin):Dot(direction), 0, length)
	return along, (point - (origin + direction * along)).Magnitude
end

local function drawTracer(from: Vector3, to: Vector3, seconds: number)
	local tracer = AssetService.get("RifleTracer") -- TODO(asset): muzzle flash, tracer, gunshot sound
	local part = tracer.PrimaryPart :: BasePart
	for _, descendant in tracer:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	local length = (to - from).Magnitude
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Size = Vector3.new(part.Size.X, part.Size.Y, length)
	part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = Workspace
	Debris:AddItem(tracer, seconds)
end

local BullwormRifle: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local params = context.params
		local direction = context.direction
		local origin = context.root.Position + Vector3.yAxis * PardnerConfig.ThrowOriginHeight

		-- The shot's reach: the first solid thing in the way.
		local ignore: { Instance } = { context.root.Parent :: Instance }
		for _, name in IGNORED_FOLDERS do
			local folder = Workspace:FindFirstChild(name)
			if folder then
				table.insert(ignore, folder)
			end
		end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = ignore
		rayParams.RespectCanCollide = true
		local hit = Workspace:Raycast(origin, direction * params.Range, rayParams)
		local length = if hit then hit.Distance else params.Range

		-- The nearest worm head along the shot, if any.
		local headRadius = AssetService.getDef("WormHead").size.X / 2
		local bestWorm: Player? = nil
		local bestAlong = length
		for _, worm in WormService.getWorms() do
			local along, off = nearLine(origin, direction, length, worm.position)
			if off <= headRadius + params.HitSlack and along <= bestAlong then
				bestWorm, bestAlong = worm.player, along
			end
		end

		-- Dynamite on the way (before the worm) goes off.
		for _, model in ItemService.getItemsById(DYNAMITE) do
			local along, off = nearLine(origin, direction, bestAlong, model:GetPivot().Position)
			if off <= params.DynamiteHitRadius and along < bestAlong then
				ItemService.detonate(model)
			end
		end

		local stop = origin + direction * bestAlong
		if bestWorm then
			WormService.shoot(bestWorm, stop)
			context.notify("Hit!")
		end
		drawTracer(origin, stop, params.TracerSeconds)
		PardnerService.impulse(context.player, -direction * params.RecoilSpeed)
		return true
	end,
}

return BullwormRifle
