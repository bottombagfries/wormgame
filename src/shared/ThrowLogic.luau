--!strict
-- Pure throw math, shared so the client's aim arc matches what the server actually does.

local PardnerConfig = require(script.Parent.Config.Pardner)

local ThrowLogic = {}

-- Throw direction for a camera look vector (tilted up a little).
function ThrowLogic.direction(look: Vector3): Vector3
	return (look + Vector3.yAxis * PardnerConfig.ThrowUpTilt).Unit
end

-- Where a thrown item starts, clear of the thrower's body.
function ThrowLogic.origin(rootPosition: Vector3, direction: Vector3, itemExtents: Vector3): Vector3
	local forward = PardnerConfig.ThrowOriginForward + itemExtents.Magnitude / 2
	return rootPosition + Vector3.yAxis * PardnerConfig.ThrowOriginHeight + direction * forward
end

-- power is the throw meter's level (ThrowMeter.MinPower..1); multiplier is for kit bonuses (Slingshot).
function ThrowLogic.velocity(direction: Vector3, power: number, multiplier: number?): Vector3
	local clamped = math.clamp(power, PardnerConfig.ThrowMeter.MinPower, 1)
	return direction * (PardnerConfig.ThrowPower * clamped * (multiplier or 1))
end

-- The throw meter's level `elapsed` seconds into aiming: rises from MinPower to 1, falls back, repeats.
function ThrowLogic.meterPower(elapsed: number): number
	local meter = PardnerConfig.ThrowMeter
	local phase = (elapsed / meter.CycleSeconds) % 1
	local level = 1 - math.abs(2 * phase - 1) -- 0 -> 1 -> 0
	return meter.MinPower + (1 - meter.MinPower) * level
end

return ThrowLogic
