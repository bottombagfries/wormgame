--!strict
-- Every visual thing in the game, with a greybox fallback (§3).
-- To replace one with real art, drop a Model named exactly the key into ReplicatedStorage/Assets/<folder>.

export type AssetDef = {
	folder: "Items" | "Structures" | "Characters" | "Effects",
	size: Vector3, -- greybox size in studs
	color: Color3,
	shape: Enum.PartType?, -- Block default
	material: Enum.Material?,
}

local v3 = Vector3.new
local rgb = Color3.fromRGB

local COAL = rgb(30, 30, 30)
local WOOD = rgb(140, 100, 60)
local DARK_WOOD = rgb(95, 65, 40)
local METAL = rgb(120, 120, 125)
local RUST = rgb(150, 85, 50)
local CLOTH = rgb(200, 185, 150)
local KIT = rgb(70, 130, 200)
local OBJECTIVE = rgb(230, 190, 40)
local CACTUS = rgb(70, 140, 70)
local WORM = rgb(160, 80, 70)

local Ball = Enum.PartType.Ball

local Assets: { [string]: AssetDef } = {
	-- Fuel items
	MassiveCoal = { folder = "Items", size = v3(3, 3, 3), color = COAL },
	BigCoal = { folder = "Items", size = v3(2, 2, 2), color = COAL },
	SmallCoal = { folder = "Items", size = v3(1, 1, 1), color = COAL },
	Gramophone = { folder = "Items", size = v3(2, 3, 2), color = rgb(190, 150, 60) },
	Pew = { folder = "Items", size = v3(7, 3, 2), color = DARK_WOOD },
	Bench = { folder = "Items", size = v3(5, 2, 1.5), color = WOOD },
	DutchOven = { folder = "Items", size = v3(2, 1.5, 2), color = rgb(45, 45, 50) },
	Pulpit = { folder = "Items", size = v3(2.5, 4, 2), color = DARK_WOOD },
	Table = { folder = "Items", size = v3(5, 3, 3), color = WOOD },
	Barrel = { folder = "Items", size = v3(2.5, 3.5, 2.5), color = WOOD },
	Chair = { folder = "Items", size = v3(2, 3.5, 2), color = WOOD },
	Bed = { folder = "Items", size = v3(4, 2, 7), color = CLOTH },
	GrainSack = { folder = "Items", size = v3(2.5, 1.5, 3.5), color = CLOTH },
	Bucket = { folder = "Items", size = v3(1.2, 1.4, 1.2), color = METAL },
	CoffeePot = { folder = "Items", size = v3(1, 1.4, 0.7), color = rgb(60, 80, 110) },
	Lantern = { folder = "Items", size = v3(0.8, 1.5, 0.8), color = rgb(240, 200, 90), material = Enum.Material.Neon },
	Skillet = { folder = "Items", size = v3(1.5, 0.3, 1.1), color = rgb(40, 40, 40) },
	Stool = { folder = "Items", size = v3(1.5, 1.5, 1.5), color = WOOD },
	Painting = { folder = "Items", size = v3(2.5, 2, 0.35), color = rgb(120, 60, 90) },
	CactusFruit = { folder = "Items", size = v3(1, 1, 1), color = rgb(220, 60, 120), shape = Ball },
	Horseshoe = { folder = "Items", size = v3(1, 0.3, 0.85), color = METAL },
	RustyTinCan = { folder = "Items", size = v3(0.7, 1, 0.7), color = RUST },

	-- Objective items
	TrainKey = { folder = "Items", size = v3(3, 0.5, 1.2), color = OBJECTIVE },
	Dynamite = { folder = "Items", size = v3(0.8, 2, 0.8), color = rgb(200, 40, 40) },
	Scrap = { folder = "Items", size = v3(3, 0.8, 2.5), color = METAL, material = Enum.Material.DiamondPlate },
	Tumbleweed = { folder = "Items", size = v3(2.5, 2.5, 2.5), color = rgb(170, 140, 90), shape = Ball },
	SassparillaCrate = { folder = "Items", size = v3(3, 2, 2), color = rgb(160, 110, 50) },
	PuzzleMap = { folder = "Items", size = v3(1.5, 0.2, 1.2), color = rgb(230, 215, 170) },
	TrainManual = { folder = "Items", size = v3(1.2, 0.4, 1.6), color = OBJECTIVE },

	-- Utility / misc items
	Backpack = { folder = "Items", size = v3(1.5, 2, 1), color = rgb(110, 80, 50) },
	HeartJar = { folder = "Items", size = v3(1.2, 1.8, 1.2), color = rgb(220, 50, 70), material = Enum.Material.Glass },
	Ladder = { folder = "Items", size = v3(2.5, 14, 0.5), color = WOOD },
	Crate = { folder = "Items", size = v3(4, 4, 4), color = WOOD },
	CursedTrinket = { folder = "Items", size = v3(1, 1, 0.3), color = rgb(90, 30, 120) },
	Chest = { folder = "Items", size = v3(3, 2, 2), color = rgb(120, 75, 30) },

	-- Kit items
	BullwormRifle = { folder = "Items", size = v3(0.35, 0.8, 4.5), color = KIT },
	CactusSeedPouch = { folder = "Items", size = v3(1, 1.2, 1), color = KIT },
	Canteen = { folder = "Items", size = v3(1.2, 1.4, 0.6), color = KIT },
	CoffeeTin = { folder = "Items", size = v3(1, 1.3, 1), color = KIT },
	CymbalMonkey = { folder = "Items", size = v3(1.2, 1.6, 1), color = KIT },
	DandylionBundle = { folder = "Items", size = v3(0.8, 2, 0.8), color = rgb(240, 220, 60) },
	SpiritBoard = { folder = "Items", size = v3(2.5, 0.3, 1.8), color = KIT },
	MysteriousConcoction = { folder = "Items", size = v3(0.8, 1.6, 0.8), color = KIT, material = Enum.Material.Glass },
	DeadBook = { folder = "Items", size = v3(1.5, 0.5, 2), color = KIT },
	PogoStick = { folder = "Items", size = v3(1.2, 4, 0.4), color = KIT },
	QuickEscapeKnife = { folder = "Items", size = v3(0.22, 0.5, 2), color = KIT },
	Shovel = { folder = "Items", size = v3(1, 0.4, 5), color = KIT },
	Slingshot = { folder = "Items", size = v3(1.2, 1.8, 0.3), color = KIT },
	SnakeOil = { folder = "Items", size = v3(0.7, 1.5, 0.7), color = KIT, material = Enum.Material.Glass },
	ZiplineCrossbow = { folder = "Items", size = v3(2.5, 0.8, 3.5), color = KIT },

	-- Structures
	HouseTall = { folder = "Structures", size = v3(22, 28, 22), color = WOOD },
	HouseSmall = { folder = "Structures", size = v3(20, 14, 20), color = WOOD },
	HouseMedium = { folder = "Structures", size = v3(28, 16, 24), color = WOOD },
	HouseLarge = { folder = "Structures", size = v3(38, 18, 30), color = WOOD },
	HouseTwoStory = { folder = "Structures", size = v3(30, 30, 26), color = WOOD },
	Shelter = { folder = "Structures", size = v3(16, 10, 12), color = DARK_WOOD },
	LookoutTower = { folder = "Structures", size = v3(12, 40, 12), color = DARK_WOOD },
	Church = { folder = "Structures", size = v3(30, 34, 50), color = rgb(235, 230, 215) },
	Watertower = { folder = "Structures", size = v3(14, 44, 14), color = RUST },
	Traincar = { folder = "Structures", size = v3(34, 12, 10), color = rgb(110, 50, 45) },
	Train = { folder = "Structures", size = v3(90, 5, 14), color = rgb(40, 40, 45) }, -- low enough to jump onto
	TrainFurnace = {
		folder = "Structures",
		size = v3(6, 6, 8),
		color = rgb(230, 90, 30),
		material = Enum.Material.Neon,
	},
	TrainLever = { folder = "Structures", size = v3(1, 4, 1), color = rgb(200, 40, 40) },
	TrainHorn = { folder = "Structures", size = v3(2, 3, 2), color = rgb(210, 180, 60) },
	TownWell = { folder = "Structures", size = v3(8, 6, 8), color = METAL },
	QuarryMinecart = { folder = "Structures", size = v3(6, 4, 4), color = METAL },
	Stagecoach = { folder = "Structures", size = v3(14, 10, 8), color = rgb(130, 40, 40) },
	SignalFire = { folder = "Structures", size = v3(6, 5, 6), color = DARK_WOOD },
	BrokenTrack = { folder = "Structures", size = v3(12, 1, 8), color = RUST },
	Safe = { folder = "Structures", size = v3(4, 5, 4), color = rgb(60, 65, 70) },
	VendingMachine = { folder = "Structures", size = v3(4, 7, 3), color = rgb(180, 50, 50) },
	SafeDigitSign = { folder = "Structures", size = v3(3, 5, 0.6), color = rgb(200, 190, 160) },
	CactusTall = { folder = "Structures", size = v3(3.5, 16, 2.1), color = CACTUS },
	CactusSmall = { folder = "Structures", size = v3(2, 5, 2), color = CACTUS },
	Skeleton = { folder = "Structures", size = v3(2, 1, 6), color = rgb(235, 230, 215) },
	TrainKeyhole = { folder = "Structures", size = v3(1.5, 3, 1.5), color = OBJECTIVE },

	-- Characters
	WormHead = { folder = "Characters", size = v3(10, 10, 10), color = WORM, shape = Ball },
	WormSegment = { folder = "Characters", size = v3(9, 9, 9), color = WORM, shape = Ball },
	Cattlebug = { folder = "Characters", size = v3(3.8, 2.5, 5), color = rgb(90, 70, 110) },
	Dandylion = { folder = "Effects", size = v3(1, 1, 1), color = rgb(250, 225, 60), shape = Ball },
	CactusSeed = { folder = "Effects", size = v3(0.6, 0.6, 0.6), color = CACTUS, shape = Ball },
	RifleTracer = {
		folder = "Effects",
		size = v3(0.2, 0.2, 1),
		color = rgb(255, 240, 180),
		material = Enum.Material.Neon,
	},
	ZiplineRope = { folder = "Effects", size = v3(0.3, 0.3, 1), color = rgb(120, 90, 60) },
	Balloon = { folder = "Characters", size = v3(20, 30, 20), color = rgb(210, 90, 60), shape = Ball },
	BalloonLadder = { folder = "Structures", size = v3(2, 80, 0.4), color = WOOD }, -- stretched a little to reach the ground
	Ghost = {
		folder = "Characters",
		size = v3(2.5, 2.5, 2.5),
		color = rgb(200, 230, 255),
		shape = Ball,
		material = Enum.Material.ForceField,
	},

	-- Effects
	Crater = { folder = "Effects", size = v3(18, 0.2, 18), color = rgb(60, 50, 40) },
	DigHole = { folder = "Effects", size = v3(5, 0.2, 5), color = rgb(90, 70, 45) },
	-- Worm ability zones: greyboxes are flat discs (cylinders on their side) sized by code.
	SinkholeZone = {
		folder = "Effects",
		size = v3(0.4, 10, 10),
		color = rgb(70, 55, 35),
		shape = Enum.PartType.Cylinder,
	},
	SandtrapZone = {
		folder = "Effects",
		size = v3(0.3, 10, 10),
		color = rgb(160, 130, 80),
		shape = Enum.PartType.Cylinder,
	},
	Tornado = { folder = "Effects", size = v3(40, 60, 40), color = rgb(210, 180, 120), shape = Enum.PartType.Cylinder },
	BileBomb = { folder = "Effects", size = v3(1.5, 1.5, 1.5), color = rgb(120, 200, 60), shape = Ball },
	MagmaPatch = { -- a disc, like the other ability zones
		folder = "Effects",
		size = v3(0.3, 14, 14),
		color = rgb(255, 110, 30),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
	},
	TarSpire = { folder = "Effects", size = v3(4, 14, 4), color = rgb(20, 20, 20) },
}

return Assets
