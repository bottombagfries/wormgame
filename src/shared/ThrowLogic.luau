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

-- power is 0..1; multiplier is for kit bonuses (Slingshot).
function ThrowLogic.velocity(direction: Vector3, power: number, multiplier: number?): Vector3
	return direction * (PardnerConfig.ThrowPower * math.clamp(power, 0, 1) * (multiplier or 1))
end

return ThrowLogic
