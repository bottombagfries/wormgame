--!strict
-- The playable area: an axis-aligned box on the ground. The server publishes it (MapService) as
-- Workspace attributes so clients can read it too; the canyon walls are built around it.

local Workspace = game:GetService("Workspace")

local CENTER_ATTRIBUTE = "MapBoundsCenter"
local SIZE_ATTRIBUTE = "MapBoundsSize"

local MapBounds = {}

-- Server only: publish the bounds. `center` is on the ground; only X/Z of `size` matter.
function MapBounds.set(center: Vector3, size: Vector3)
	Workspace:SetAttribute(CENTER_ATTRIBUTE, center)
	Workspace:SetAttribute(SIZE_ATTRIBUTE, size)
end

-- (center, size), or nil until the server has published them.
function MapBounds.get(): (Vector3?, Vector3?)
	local center = Workspace:GetAttribute(CENTER_ATTRIBUTE)
	local size = Workspace:GetAttribute(SIZE_ATTRIBUTE)
	if typeof(center) == "Vector3" and typeof(size) == "Vector3" then
		return center, size
	end
	return nil, nil
end

local function halfExtents(size: Vector3, margin: number): (number, number)
	return math.max(size.X / 2 - margin, 0), math.max(size.Z / 2 - margin, 0)
end

-- `position` pulled horizontally inside the bounds shrunk by `margin` (unchanged if already inside).
function MapBounds.clamp(position: Vector3, margin: number): Vector3
	local center, size = MapBounds.get()
	if not center or not size then
		return position
	end
	local hx, hz = halfExtents(size, margin)
	return Vector3.new(
		math.clamp(position.X, center.X - hx, center.X + hx),
		position.Y,
		math.clamp(position.Z, center.Z - hz, center.Z + hz)
	)
end

-- How far `position` is outside the bounds shrunk by `margin` (0 when inside).
function MapBounds.overshoot(position: Vector3, margin: number): number
	local clamped = MapBounds.clamp(position, margin)
	return Vector3.new(position.X - clamped.X, 0, position.Z - clamped.Z).Magnitude
end

-- `velocity` with any outward horizontal part removed once `position` is at or past the edge.
function MapBounds.limitVelocity(position: Vector3, velocity: Vector3, margin: number): Vector3
	local center, size = MapBounds.get()
	if not center or not size then
		return velocity
	end
	local hx, hz = halfExtents(size, margin)
	local offset = position - center
	local x, z = velocity.X, velocity.Z
	if (offset.X >= hx and x > 0) or (offset.X <= -hx and x < 0) then
		x = 0
	end
	if (offset.Z >= hz and z > 0) or (offset.Z <= -hz and z < 0) then
		z = 0
	end
	return Vector3.new(x, velocity.Y, z)
end

return MapBounds
