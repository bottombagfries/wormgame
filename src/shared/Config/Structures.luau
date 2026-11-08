--!strict
-- Structures (§7). HP values are TUNE. hp = nil means indestructible.

local Types = require(script.Parent.Parent.Types)

local Defs: { [string]: Types.StructureDef } = {
	House = { id = "House", hp = 3, scrap = 1, wormDamageable = true },
	Shelter = { id = "Shelter", hp = 1, scrap = 0, wormDamageable = true },
	LookoutTower = { id = "LookoutTower", hp = 3, scrap = 1, wormDamageable = true },
	Church = { id = "Church", hp = 4, scrap = 2, wormDamageable = true },
	Watertower = { id = "Watertower", hp = 4, scrap = 1, wormDamageable = true },
	Traincar = { id = "Traincar", hp = 1, scrap = 3, wormDamageable = false }, -- dynamite only
	Cactus = { id = "Cactus", hp = 1, scrap = 0, wormDamageable = true }, -- TUNE
	Rock = { id = "Rock", hp = 1, scrap = 0, wormDamageable = false }, -- dynamite only (§6.7)
	Train = { id = "Train", scrap = 0, wormDamageable = false },
}

return {
	Defs = Defs,

	-- Damage dealt to structures
	PounceDamage = 1,
	BodyslamDamage = 1,

	-- When a structure collapses, Pardners inside it or standing up to this far above it die (§7).
	OnTopHeight = 8, -- TUNE
	ScrapScatter = 6, -- TUNE: scrap lands within this many studs of the structure's center

	-- Greybox shapes for structures with no real model yet (Map/StructureBuilder). Sizes come from Config/Assets.
	--   Shell    = floor, four walls with a doorway on the front (-Z), roof. Walk-in; loot goes on the floor.
	--   Platform = four legs and a deck on top.
	--   Tank     = a Platform with a block on the deck (water tower).
	--   (anything else is the plain AssetService box)
	Greybox = {
		Kinds = {
			HouseTall = "Shell",
			HouseSmall = "Shell",
			HouseMedium = "Shell",
			HouseLarge = "Shell",
			HouseTwoStory = "Shell",
			Church = "Shell",
			Shelter = "Platform",
			LookoutTower = "Platform",
			Watertower = "Tank",
		},
		WallThickness = 1,
		DoorWidth = 6, -- TUNE
		DoorHeight = 8, -- TUNE
		LegThickness = 1.5,
		DeckThickness = 1,
		TankFraction = 0.35, -- TUNE: share of a Tank's height that is the tank
		LootMargin = 2, -- TUNE: loot is kept this far from the walls
	},

	House = {
		Variants = { "Tall", "Small", "Medium", "Large", "TwoStory" },
		Tiers = 3,
		Colors = { -- TUNE
			Color3.fromRGB(150, 110, 80),
			Color3.fromRGB(170, 70, 60),
			Color3.fromRGB(110, 130, 110),
			Color3.fromRGB(200, 180, 140),
			Color3.fromRGB(90, 100, 130),
		},
		Trims = { Color3.fromRGB(240, 235, 220), Color3.fromRGB(60, 45, 35) }, -- TUNE
		-- Parts with these names in a house model get the body / trim color (greyboxes use them too).
		BodyPartNames = { "Wall", "Body" },
		TrimPartNames = { "Roof", "Trim" },
		LadderChance = 0.5, -- TUNE (ladders not built yet)
	},

	Ranch = {
		HouseVariant = "Large",
		ShelterOffset = Vector3.new(30, 0, 0), -- TUNE: from the ranch marker, in its space
		SpawnGap = 6, -- TUNE: Pardners spawn this far in front of the ranch house door
		SpawnHeight = 4, -- TUNE: ...and this far above the ground, so they drop onto the sand
	},

	Church = {
		ReviveRadius = 14, -- TUNE
		ReviveHeight = 10, -- TUNE: a jar this far above/below the ring still counts
		RingGap = 4, -- TUNE: the ring sits this far in front of the Church
		RingColor = Color3.fromRGB(255, 215, 60),
		PewsMin = 4,
		PewsMax = 6,
	},

	Watertower = {
		Offset = Vector3.new(0, 0, -30), -- TUNE: from the TrainSpot, in its space
	},

	LookoutTower = {
		PerMatch = 3,
		Chests = 2,
		ChestSpacing = 5, -- TUNE: chests sit this far apart on the deck
	},

	Quarry = {
		Minecarts = 3, -- TUNE
		MinecartSpacing = 10, -- TUNE
		MaxDynamite = 8, -- TUNE: the +1 every 90 s stops while this many quarry dynamite are lying around
		DynamiteRadius = 25, -- TUNE: "lying around" = within this distance of the quarry
	},

	Traincar = {
		PerMatch = 6,
	},

	Stagecoach = {
		PerMatch = 2,
		Crates = 2,
	},

	Well = {
		TokenSeconds = 35,
		MaxTokens = 2,
		TokenItems = { "Bucket", "Chair", "CoffeePot", "Lantern", "Skillet", "Stool" },
		NoTokenItem = "RustyTinCan",
		CursedTrinketChance = 1 / 200,
		UseCooldown = 3, -- TUNE: stops the prompt being spammed for endless tin cans
		DropGap = 3, -- TUNE: items appear this far in front of the well
		HoldSeconds = 0.5, -- TUNE
	},

	Chest = {
		HoldSeconds = 1, -- TUNE: hold the prompt this long to open
		DropGap = 3, -- TUNE: contents appear this far in front of the chest
	},

	-- Rock formations on RockSpot markers (Map/Rocks): somewhere off the sand for Pardners to stand, hide
	-- and travel on. A model in Assets/Structures named Rock<Kind> (e.g. RockRidge) replaces the built
	-- shape. Kinds are picked by weight. All sizes in studs, TUNE.
	Rocks = {
		Weights = { Ridge = 4, Mesa = 2, Arch = 1, Slab = 2, Stones = 2 },
		Colors = {
			Color3.fromRGB(176, 112, 76),
			Color3.fromRGB(158, 96, 66),
			Color3.fromRGB(190, 140, 100),
			Color3.fromRGB(140, 104, 84),
		},
		Materials = { Enum.Material.Rock, Enum.Material.Sandstone, Enum.Material.Slate },
		-- Long, low spine of overlapping blocks with ramps at both ends: a sand-free path.
		Ridge = { Length = { 36, 70 }, Width = { 7, 11 }, Height = { 4, 9 }, Pieces = { 3, 6 }, Bend = 0.35 },
		-- Wide flat top with a ramp up one side.
		Mesa = { Width = { 16, 24 }, Height = { 9, 14 }, RampLength = 14 },
		-- Two pillars and a slab across the top.
		Arch = { Span = { 16, 26 }, Height = { 13, 18 }, Pillar = { 6, 8 }, Thickness = 4 },
		-- A big tilted slab: walk up it to a lookout edge.
		Slab = { Length = { 24, 34 }, Width = { 10, 14 }, Rise = { 7, 12 }, Thickness = 3 },
		-- A curving line of flat-topped stones to hop across.
		Stones = { Count = { 4, 7 }, Size = { 4, 7 }, Height = { 2.5, 5 }, Gap = { 5, 7 }, Bend = 0.4 },
		SinkDepth = 1, -- pieces start this far under the sand so no gap shows
	},

	Placement = {
		Attempts = 12, -- TUNE: tries to find a free spot for loose loot
		LootLift = 0.5, -- TUNE: items spawn this far above the floor/ground
	},
}
