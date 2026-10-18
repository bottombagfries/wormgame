--!strict
-- Shared bits for worm ability modules: placing zone visuals, finding the ground, and who's in range.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local AbilityKit = {}

-- The ground (sand first) over or under `position`.
function AbilityKit.groundAt(position: Vector3): Vector3
	local y = Ground.sandBelow(position) or Ground.surfaceBelow(position, WormConfig.SandProbeUp) or position.Y
	return Vector3.new(position.X, y, position.Z)
end

-- A flat zone (sinkhole, sandtrap, ...) of `radius` lying on the ground at `center`. Greyboxes are
-- cylinders on their side, resized; real models are scaled to the diameter.
function AbilityKit.zone(assetId: string, center: Vector3, radius: number, parent: Instance): Model
	local model = AssetService.get(assetId) -- TODO(asset): zone visuals
	local diameter = radius * 2
	local greybox = model:GetAttribute("Greybox") == true
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			if greybox then
				descendant.Size = Vector3.new(descendant.Size.X, diameter, diameter)
				descendant.Transparency = WormConfig.ZoneTransparency
			end
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	if greybox then
		model:PivotTo(CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2))
	else
		model:ScaleTo(diameter / math.max(model:GetExtentsSize().X, 0.1))
		model:PivotTo(CFrame.new(center))
	end
	model.Parent = parent
	return model
end

-- Living Pardners whose root is within `radius` of `position` (flat distance when `flat`).
function AbilityKit.pardnersNear(position: Vector3, radius: number, flat: boolean?): { [Player]: BasePart }
	local found = {}
	for player, root in PardnerService.getLiving() do
		local offset = root.Position - position
		local distance = if flat then Vector3.new(offset.X, 0, offset.Z).Magnitude else offset.Magnitude
		if distance <= radius then
			found[player] = root
		end
	end
	return found
end

-- A timed slow on a Pardner, refreshed every ability tick while they stay in the zone.
function AbilityKit.slow(player: Player, id: string, fraction: number)
	PardnerService.addStatus(player, {
		id = id,
		expires = os.clock() + WormConfig.AbilityTickSeconds * 2,
		speedMult = 1 - fraction,
	})
end

-- Runs `tick` every AbilityTickSeconds for `seconds` (or until it returns false), then `done`.
function AbilityKit.forSeconds(seconds: number, tick: () -> boolean?, done: (() -> ())?)
	task.spawn(function()
		local ends = os.clock() + seconds
		while os.clock() < ends do
			if tick() == false then
				break
			end
			task.wait(WormConfig.AbilityTickSeconds)
		end
		if done then
			done()
		end
	end)
end

return AbilityKit
