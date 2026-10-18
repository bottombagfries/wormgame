--!strict
-- Pure geometry helpers.

local Geometry = {}

function Geometry.flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Geometry.horizontalDistance(a: Vector3, b: Vector3): number
	return Geometry.flat(a - b).Magnitude
end

-- Uniform random point inside a box-shaped part (used for DigArea / LooseItemArea volumes).
function Geometry.randomPointInPart(part: BasePart, rng: Random): Vector3
	local size = part.Size
	local offset = Vector3.new(
		(rng:NextNumber() - 0.5) * size.X,
		(rng:NextNumber() - 0.5) * size.Y,
		(rng:NextNumber() - 0.5) * size.Z
	)
	return part.CFrame:PointToWorldSpace(offset)
end

function Geometry.isPointInBox(cframe: CFrame, size: Vector3, point: Vector3): boolean
	local localPoint = cframe:PointToObjectSpace(point)
	local half = size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

-- Moves a model so the bottom of its bounding box sits on `groundCFrame`, wherever its pivot is.
function Geometry.placeOnGround(model: Model, groundCFrame: CFrame)
	local boundsCFrame, size = model:GetBoundingBox()
	local pivotToBounds = model:GetPivot():ToObjectSpace(boundsCFrame)
	model:PivotTo(groundCFrame * CFrame.new(0, size.Y / 2, 0) * pivotToBounds:Inverse())
end

function Geometry.isPointInPart(part: BasePart, point: Vector3): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

-- Farthest-point sampling: returns indices into `points`, spread as far apart as possible.
function Geometry.farthestPointSample(points: { Vector3 }, count: number, rng: Random): { number }
	local chosen: { number } = {}
	if #points == 0 or count <= 0 then
		return chosen
	end

	local minDistance = table.create(#points, math.huge)
	local current = rng:NextInteger(1, #points)
	for _ = 1, math.min(count, #points) do
		table.insert(chosen, current)
		minDistance[current] = -1 -- never pick again

		local best, bestDistance = current, -1
		for i, point in points do
			if minDistance[i] >= 0 then
				minDistance[i] = math.min(minDistance[i], Geometry.horizontalDistance(point, points[current]))
				if minDistance[i] > bestDistance then
					best, bestDistance = i, minDistance[i]
				end
			end
		end
		current = best
	end
	return chosen
end

return Geometry
