--!strict
-- Loot tables (§6.6 chests, §7 caboose, §7.1 houses, loose sand loot).

type LootTable = { [string]: number } -- itemId -> count

-- House[variant][tier]
local House: { [string]: { LootTable } } = {
	Tall = {
		{ SmallCoal = 1, Bed = 1, RustyTinCan = 4, Stool = 1 },
		{ SmallCoal = 1, Bed = 1, Gramophone = 1, Table = 1, Stool = 1, Bucket = 1, Bench = 1 },
		{
			Stool = 2,
			SmallCoal = 1,
			Painting = 1,
			RustyTinCan = 4,
			Bucket = 1,
			Barrel = 1,
			Lantern = 1,
			Bench = 1,
			CoffeePot = 1,
			Table = 1,
			Bed = 1,
		},
	},
	Small = {
		{ SmallCoal = 1, GrainSack = 1, Bench = 1, Bucket = 1, Barrel = 1, Bed = 1 },
		{
			SmallCoal = 1,
			Painting = 1,
			RustyTinCan = 4,
			DutchOven = 1,
			Skillet = 1,
			GrainSack = 1,
			Bucket = 1,
			Stool = 1,
			Bed = 1,
		},
		{ Lantern = 1, Bench = 1, Painting = 2, Gramophone = 1, Bed = 1, Table = 1, Chair = 1, SmallCoal = 3 },
	},
	Medium = {
		{ SmallCoal = 1, GrainSack = 1, Barrel = 1, Lantern = 1, RustyTinCan = 3, Bucket = 1, Stool = 1, Bed = 1 },
		{ SmallCoal = 1, Bench = 1, Chair = 2, RustyTinCan = 2, Table = 1, Painting = 1, Bed = 1 },
		{
			SmallCoal = 1,
			Bucket = 1,
			DutchOven = 1,
			Bench = 2,
			RustyTinCan = 3,
			Chair = 1,
			Table = 1,
			Lantern = 1,
			GrainSack = 1,
			Stool = 1,
			Bed = 1,
			Painting = 1,
		},
	},
	Large = {
		{ Bed = 1, SmallCoal = 1, Painting = 1, RustyTinCan = 1, Bucket = 1, Chair = 1, Table = 1 },
		{
			RustyTinCan = 4,
			GrainSack = 2,
			CoffeePot = 1,
			Skillet = 1,
			Bench = 1,
			Table = 1,
			SmallCoal = 1,
			Chair = 1,
			Bed = 1,
		},
		{
			Barrel = 1,
			GrainSack = 1,
			RustyTinCan = 5,
			Chair = 2,
			Table = 1,
			DutchOven = 1,
			Stool = 1,
			SmallCoal = 1,
			Bed = 1,
			Painting = 1,
			Bucket = 1,
		},
	},
	TwoStory = {
		{
			SmallCoal = 1,
			Gramophone = 1,
			Table = 3,
			Painting = 3,
			Chair = 3,
			Bucket = 1,
			Stool = 1,
			Bed = 1,
			DutchOven = 1,
		},
		-- TUNE: T2/T3 are not on the wiki; T1 with small variations.
		{
			SmallCoal = 2,
			Gramophone = 1,
			Table = 3,
			Painting = 3,
			Chair = 3,
			Bucket = 1,
			Stool = 1,
			Bed = 1,
			DutchOven = 1,
			Lantern = 1,
		},
		{
			SmallCoal = 2,
			Gramophone = 1,
			Table = 3,
			Painting = 3,
			Chair = 4,
			Bucket = 1,
			Stool = 2,
			Bed = 2,
			DutchOven = 1,
			Lantern = 1,
			Bench = 1,
		},
	},
}

return {
	House = House,

	-- Random sand loot spawned inside LooseItemArea volumes. All TUNE.
	Loose = {
		Tumbleweed = 12,
		Backpack = 6,
		Crate = 8,
		Chest = 10,
	},

	Chest = {
		-- Randomly spawned and airdrop chests may also hold one of these alongside their kit.
		ExtraChance = 0.35, -- TUNE
		ExtraItems = { "Dynamite", "CactusFruit", "SmallCoal", "BigCoal", "MassiveCoal" },
	},

	-- The caboose is the Train's -X end (§7). Ladders are not built yet.
	Caboose = {
		Shovels = 8,
		Crates = 3,
		MaxLadders = 4,
		ShovelGap = 4, -- TUNE: shovels lie on the ground this far past the caboose end, in a row
		ShovelSpacing = 2, -- TUNE
		CrateSpacing = 6, -- TUNE: crates sit on the deck in a row from the caboose end
	},

	Cactus = {
		FruitChance = 0.3, -- TUNE
	},
}
