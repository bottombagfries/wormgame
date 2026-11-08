--!strict
-- Rock formations for RockSpot markers (Config.Structures.Rocks): long ridges, mesas, arches, tilted slabs
-- and lines of stepping stones. They give Pardners ground that isn't sand (standing on rock = the worm
-- can't feel you, §8.1) and routes across the open desert. The worm swims under them.
--
-- A model in ReplicatedStorage/Assets/Structures named Rock<Kind> (e.g. RockRidge) is used instead of the
-- built shape (§3). TODO(asset): RockRidge / RockMesa / RockArch / RockSlab / RockStones
--
-- Every formation comes back anchored with its pivot at the middle of its base (the marker's CFrame).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)

local Config = Structures.Rocks
local COLOR_JITTER = 0.06 -- each piece's color varies a little so the formation doesn't look flat

type Range = { number }

type Builder = {
	model: Model,
	base: CFrame,
	rng: Random,
	color: Color3,
	material: Enum.Material,
}

local Rocks = {}

local function between(range: Range, rng: Random): number
	return rng:NextNumber(range[1], range[2])
end

local function jitter(color: Color3, rng: Random): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + rng:NextNumber(-COLOR_JITTER, COLOR_JITTER), 0, 1))
end

local function style(b: Builder, part: BasePart, name: string)
	part.Name = name
	part.Anchored = true
	part.Material = b.material
	part.Color = jitter(b.color, b.rng)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = b.model
end

-- A block whose base sits `bottom` studs up (negative = under the sand), at `local` in the formation's space.
local function block(b: Builder, size: Vector3, at: CFrame, bottom: number?)
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = b.base * (at + Vector3.yAxis * ((bottom or -Config.SinkDepth) + size.Y / 2))
	style(b, part, "Rock")
end

-- A ramp from the ground up to `height`, its tall face at `at` and running `length` studs out along `out`
-- (a horizontal unit vector in the formation's space).
local function ramp(b: Builder, at: Vector3, out: Vector3, width: number, height: number, length: number)
	local wedge = Instance.new("WedgePart")
	local sink = Config.SinkDepth
	wedge.Size = Vector3.new(width, height + sink, length)
	local center = at + out * (length / 2) + Vector3.yAxis * ((height - sink) / 2)
	-- A wedge's tall face is its +Z (back) side, so it looks away from `at` along `out`.
	wedge.CFrame = b.base * CFrame.lookAt(center, center + out)
	style(b, wedge, "Ramp")
end

local function heading(angle: number): Vector3
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

-- A bending spine of overlapping blocks, heights wandering a little so it can be walked/jumped along, with a
-- ramp at each end.
local function buildRidge(b: Builder)
	local R = Config.Ridge
	local rng = b.rng
	local pieces = rng:NextInteger(R.Pieces[1], R.Pieces[2])
	local step = between(R.Length, rng) / pieces
	local angle = 0
	local position = -heading(angle) * (step * pieces / 2)
	local height = between(R.Height, rng)
	local first: { at: Vector3, out: Vector3, width: number, height: number }? = nil
	local last = first
	for index = 1, pieces do
		angle += rng:NextNumber(-R.Bend, R.Bend)
		local dir = heading(angle)
		local width = between(R.Width, rng)
		height = math.clamp(height + rng:NextNumber(-2.5, 2.5), R.Height[1], R.Height[2])
		local center = position + dir * (step / 2)
		local length = step * 1.35 -- overlap so there are no gaps at the bends
		block(b, Vector3.new(width, height + Config.SinkDepth, length), CFrame.lookAt(center, center + dir))
		if index == 1 then
			first = { at = center - dir * (length / 2), out = -dir, width = width, height = height }
		end
		last = { at = center + dir * (length / 2), out = dir, width = width, height = height }
		position += dir * step
	end
	for _, finish in { first, last } do
		if finish then
			ramp(b, finish.at, finish.out, finish.width, finish.height, finish.height * 1.8)
		end
	end
end

-- A wide flat-topped block with a ramp up one side and a couple of boulders at its foot.
local function buildMesa(b: Builder)
	local M = Config.Mesa
	local rng = b.rng
	local width, depth = between(M.Width, rng), between(M.Width, rng)
	local height = between(M.Height, rng)
	block(b, Vector3.new(width, height + Config.SinkDepth, depth), CFrame.new())
	-- A slightly smaller cap so the top edge isn't one perfect box.
	block(b, Vector3.new(width * 0.85, 1.5, depth * 0.85), CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), height)
	local rampLength = math.max(M.RampLength, height * 1.6)
	ramp(b, Vector3.new(0, 0, depth / 2), Vector3.zAxis, width * 0.45, height, rampLength)
	for _ = 1, 2 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local size = rng:NextNumber(3, 5)
		local at = Vector3.new(side * (width / 2 + size / 2), 0, rng:NextNumber(-depth / 2, 0))
		block(b, Vector3.new(size, size, size), CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0))
	end
end

-- Two pillars bridged by a slab; the pillars can be climbed.
local function buildArch(b: Builder)
	local A = Config.Arch
	local rng = b.rng
	local span = between(A.Span, rng)
	local height = between(A.Height, rng)
	local pillar = between(A.Pillar, rng)
	for _, side in { -1, 1 } do
		local x = side * (span / 2 + pillar / 2)
		block(b, Vector3.new(pillar, height + Config.SinkDepth, pillar + 1), CFrame.new(x, 0, 0))
	end
	block(b, Vector3.new(span + pillar * 2 + 2, A.Thickness, pillar + 2), CFrame.new(), height)
	-- Rubble against one pillar to help Pardners up.
	local side = if rng:NextNumber() < 0.5 then -1 else 1
	local x = side * (span / 2 + pillar + 2)
	block(b, Vector3.new(4, height * 0.4, 5), CFrame.new(x, 0, 0))
end

-- A tilted slab rising to a squared-off lookout ledge.
local function buildSlab(b: Builder)
	local S = Config.Slab
	local rng = b.rng
	local length = between(S.Length, rng)
	local width = between(S.Width, rng)
	local rise = between(S.Rise, rng)
	local ledge = S.Thickness + 3
	ramp(b, Vector3.new(0, 0, -length / 2 + ledge), Vector3.zAxis, width, rise, length - ledge)
	block(b, Vector3.new(width + 1, rise + Config.SinkDepth, ledge), CFrame.new(0, 0, -length / 2 + ledge / 2))
end

-- Flat-topped stones along a gentle curve, a hop apart.
local function buildStones(b: Builder)
	local St = Config.Stones
	local rng = b.rng
	local count = rng:NextInteger(St.Count[1], St.Count[2])
	local angle = rng:NextNumber(0, math.pi * 2)
	local position = Vector3.zero
	for _ = 1, count do
		local size = between(St.Size, rng)
		local height = between(St.Height, rng)
		local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		block(
			b,
			Vector3.new(size, height + Config.SinkDepth, size * rng:NextNumber(0.8, 1.2)),
			CFrame.new(position) * yaw
		)
		angle += rng:NextNumber(-St.Bend, St.Bend)
		position += heading(angle) * (size / 2 + between(St.Gap, rng))
	end
end

local BUILDERS: { [string]: (Builder) -> () } = {
	Ridge = buildRidge,
	Mesa = buildMesa,
	Arch = buildArch,
	Slab = buildSlab,
	Stones = buildStones,
}

-- A kind picked by Config weight.
function Rocks.pickKind(rng: Random): string
	local kinds = {}
	for kind in Config.Weights do
		table.insert(kinds, kind)
	end
	table.sort(kinds) -- stable order so a seed repeats
	return RandomUtil.weighted(kinds, function(kind)
		return (Config.Weights :: { [string]: number })[kind]
	end, rng)
end

function Rocks.build(kind: string, cframe: CFrame, rng: Random): Model
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Structures")
	local custom = folder and folder:FindFirstChild(`Rock{kind}`)
	if custom and custom:IsA("Model") then
		local model = custom:Clone()
		model:PivotTo(cframe)
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		return model
	end

	local model = Instance.new("Model")
	model.Name = `Rock{kind}`
	local builder: Builder = {
		model = model,
		base = cframe,
		rng = rng,
		color = RandomUtil.pick(Config.Colors, rng),
		material = RandomUtil.pick(Config.Materials, rng),
	}
	local build = BUILDERS[kind] or buildRidge
	build(builder)
	model.WorldPivot = cframe
	return model
end

return Rocks
