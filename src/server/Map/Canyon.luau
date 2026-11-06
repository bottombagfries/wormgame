--!strict
-- Canyon cliffs ringing the playable area (Config.Game.Canyon): on each side, columns of terraced rock
-- step back and up from the edge, each terrace capped with a dark strata band, with boulders at the
-- foot. An invisible barrier rises from the edge so nothing gets over the top. All rock is NoClimb
-- (PardnerMovementController) and MapBoundary (ziplines won't hook it). Built once at server start.
-- TODO(asset): CanyonRock - swap the block columns for real cliff meshes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

local CANYON = GameConfig.Canyon
local FLOOR_DROP = 0.05 -- the canyon floor sits this far below the sand so they don't z-fight

local Canyon = {}

local function rock(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("NoClimb", true)
	part:SetAttribute("MapBoundary", true)
	part.Parent = parent
	return part
end

-- One side of the canyon. `edge` is the middle of that side on the ground, `outward` points away from
-- the map and `along` runs along the side; `length` covers the corners too.
local function buildSide(parent: Instance, rng: Random, edge: Vector3, outward: Vector3, along: Vector3, length: number)
	local groundY = edge.Y
	local bottom = groundY - CANYON.Sink

	-- Rock floor under the whole side, just below the sand, so jagged cliff faces never show a gap.
	local floorCenter = edge + outward * (CANYON.Width / 2)
	floorCenter = Vector3.new(floorCenter.X, (bottom + groundY - FLOOR_DROP) / 2, floorCenter.Z)
	rock(
		parent,
		"CanyonFloor",
		Vector3.new(length, groundY - FLOOR_DROP - bottom, CANYON.Width),
		CFrame.lookAt(floorCenter, floorCenter + outward),
		CANYON.Terraces[1].Color,
		Enum.Material.Rock
	)

	local count = math.ceil(length / CANYON.SegmentLength)
	local spacing = length / count
	local columnWidth = spacing * CANYON.SegmentOverlap

	for i = 1, count do
		local offset = along * (-length / 2 + (i - 0.5) * spacing)
		for _, terrace in CANYON.Terraces do
			local setback = terrace.Setback + rng:NextNumber(0, CANYON.Jag)
			local depth = CANYON.Width - setback
			if depth <= 0 then
				continue
			end
			local jitter = 1 + rng:NextNumber(-CANYON.HeightJitter, CANYON.HeightJitter)
			local top = groundY + CANYON.Height * terrace.HeightFraction * jitter
			local flat = edge + offset + outward * (setback + depth / 2)

			local columnCenter = Vector3.new(flat.X, (bottom + top) / 2, flat.Z)
			rock(
				parent,
				"CanyonRock",
				Vector3.new(columnWidth, top - bottom, depth),
				CFrame.lookAt(columnCenter, columnCenter + outward),
				terrace.Color,
				terrace.Material
			)

			-- A slightly proud band along the top edge reads as a rock stratum from the ground.
			local bandCenter = Vector3.new(flat.X, top - CANYON.StrataBand / 2, flat.Z) - outward * 0.2
			rock(
				parent,
				"CanyonStrata",
				Vector3.new(columnWidth + 0.2, CANYON.StrataBand, depth + 0.4),
				CFrame.lookAt(bandCenter, bandCenter + outward),
				CANYON.StrataColor,
				Enum.Material.Slate
			)
		end
	end

	local innerSpan = length - 2 * CANYON.Width
	for _ = 1, CANYON.BouldersPerSide do
		local size = rng:NextNumber(CANYON.BoulderSize.Min, CANYON.BoulderSize.Max)
		local into = rng:NextNumber(0, CANYON.BoulderReach)
		local flat = edge + along * rng:NextNumber(-innerSpan / 2, innerSpan / 2) + outward * (size / 2 - into)
		local spin = CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi))
		rock(
			parent,
			"CanyonBoulder",
			Vector3.new(size, size * rng:NextNumber(0.6, 0.9), size * rng:NextNumber(0.7, 1)),
			CFrame.new(flat.X, groundY + size * 0.25, flat.Z) * spin,
			CANYON.BoulderColor,
			Enum.Material.Rock
		)
	end

	-- Invisible wall from the edge up to BarrierHeight. CanQuery off so cameras and raycasts ignore it.
	local barrierCenter = edge + outward * (CANYON.BarrierThickness / 2)
	local barrierTop = groundY + CANYON.BarrierHeight
	local barrier = rock(
		parent,
		"BoundaryBarrier",
		Vector3.new(length, barrierTop - bottom, CANYON.BarrierThickness),
		CFrame.lookAt(
			Vector3.new(barrierCenter.X, (bottom + barrierTop) / 2, barrierCenter.Z),
			Vector3.new(barrierCenter.X, (bottom + barrierTop) / 2, barrierCenter.Z) + outward
		),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic
	)
	barrier.Transparency = 1
	barrier.CanQuery = false
	barrier.CanTouch = false
	barrier.CastShadow = false
end

-- Builds the canyon around the bounds box (`center` on the ground; X/Z of `size` = playable area).
function Canyon.build(parent: Instance, center: Vector3, size: Vector3)
	local rng = Random.new(CANYON.Seed)
	local hx, hz = size.X / 2, size.Z / 2
	local spanX = size.X + 2 * CANYON.Width
	local spanZ = size.Z + 2 * CANYON.Width
	buildSide(parent, rng, center + Vector3.new(hx, 0, 0), Vector3.xAxis, Vector3.zAxis, spanZ)
	buildSide(parent, rng, center - Vector3.new(hx, 0, 0), -Vector3.xAxis, Vector3.zAxis, spanZ)
	buildSide(parent, rng, center + Vector3.new(0, 0, hz), Vector3.zAxis, Vector3.xAxis, spanX)
	buildSide(parent, rng, center - Vector3.new(0, 0, hz), -Vector3.zAxis, Vector3.xAxis, spanX)
end

return Canyon
