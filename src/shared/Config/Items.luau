--!strict
-- Every item in the game (§6). Adding an item = one entry here (+ an Assets entry for its model).
-- Kit items are appended from Config/Kits at the bottom.

local Kits = require(script.Parent.Kits)
local Types = require(script.Parent.Parent.Types)

type ItemDef = Types.ItemDef

local Items: { [string]: ItemDef } = {
	-- Fuel (§6.3)
	MassiveCoal = {
		id = "MassiveCoal",
		displayName = "Massive Coal",
		category = "Fuel",
		size = 3,
		fuel = 12,
		swallowable = true,
	},
	BigCoal = { id = "BigCoal", displayName = "Big Coal", category = "Fuel", size = 2, fuel = 7, swallowable = true },
	SmallCoal = {
		id = "SmallCoal",
		displayName = "Small Coal",
		category = "Fuel",
		size = 1,
		fuel = 3,
		swallowable = true,
	},
	Gramophone = {
		id = "Gramophone",
		displayName = "Gramophone",
		category = "Fuel",
		size = 3,
		fuel = 7,
		swallowable = true,
	},
	Pew = { id = "Pew", displayName = "Pew", category = "Fuel", size = "X", fuel = 6, swallowable = false }, -- TUNE swallowable
	Bench = { id = "Bench", displayName = "Bench", category = "Fuel", size = 3, fuel = 5, swallowable = true },
	DutchOven = {
		id = "DutchOven",
		displayName = "Dutch Oven",
		category = "Fuel",
		size = 3,
		fuel = 5,
		swallowable = true,
	},
	Pulpit = { id = "Pulpit", displayName = "Pulpit", category = "Fuel", size = "X", fuel = 5, swallowable = false }, -- TUNE swallowable
	Table = { id = "Table", displayName = "Table", category = "Fuel", size = "X", fuel = 5, swallowable = false }, -- TUNE swallowable
	Barrel = { id = "Barrel", displayName = "Barrel", category = "Fuel", size = "X", fuel = 4, swallowable = true },
	Chair = { id = "Chair", displayName = "Chair", category = "Fuel", size = 2, fuel = 4, swallowable = true },
	Bed = { id = "Bed", displayName = "Bed", category = "Fuel", size = "X", fuel = 3, swallowable = false }, -- TUNE swallowable
	GrainSack = {
		id = "GrainSack",
		displayName = "Grain Sack",
		category = "Fuel",
		size = "X",
		fuel = 3,
		swallowable = true,
	},
	Bucket = { id = "Bucket", displayName = "Bucket", category = "Fuel", size = 1, fuel = 2, swallowable = true },
	CoffeePot = {
		id = "CoffeePot",
		displayName = "Coffee Pot",
		category = "Fuel",
		size = 1,
		fuel = 2,
		swallowable = true,
	},
	Lantern = { id = "Lantern", displayName = "Lantern", category = "Fuel", size = 1, fuel = 2, swallowable = true },
	Skillet = { id = "Skillet", displayName = "Skillet", category = "Fuel", size = 1, fuel = 2, swallowable = true },
	Stool = { id = "Stool", displayName = "Stool", category = "Fuel", size = 1, fuel = 2, swallowable = true },
	Painting = { id = "Painting", displayName = "Painting", category = "Fuel", size = 2, fuel = 2, swallowable = true },
	CactusFruit = {
		id = "CactusFruit",
		displayName = "Cactus Fruit",
		category = "Utility",
		size = 1,
		fuel = 1,
		swallowable = true,
	},
	Horseshoe = {
		id = "Horseshoe",
		displayName = "Horseshoe",
		category = "Fuel",
		size = 1,
		fuel = 1,
		swallowable = true,
	},
	RustyTinCan = {
		id = "RustyTinCan",
		displayName = "Rusty Tin Can",
		category = "Fuel",
		size = 1,
		fuel = 1,
		swallowable = true,
	},

	-- Objective items (§6.4). Shovel and DandylionBundle are kits.
	TrainKey = {
		id = "TrainKey",
		displayName = "Train Key",
		category = "Objective",
		size = "X",
		swallowable = false, -- TUNE: objective-critical
	},
	Dynamite = {
		id = "Dynamite",
		displayName = "Dynamite",
		category = "Objective",
		size = 2,
		swallowable = true,
		behavior = "Dynamite",
	},
	Scrap = { id = "Scrap", displayName = "Scrap", category = "Objective", size = 3, swallowable = true },
	Tumbleweed = {
		id = "Tumbleweed",
		displayName = "Tumbleweed",
		category = "Objective",
		size = 1,
		swallowable = true,
		behavior = "Tumbleweed",
		physics = { density = 0.2, friction = 0.05, elasticity = 0.4 }, -- TUNE: light, round, rolls far (§6.4)
	},
	SassparillaCrate = {
		id = "SassparillaCrate",
		displayName = "Sassparilla Crate",
		category = "Objective",
		size = "X",
		swallowable = true,
	},
	PuzzleMap = { id = "PuzzleMap", displayName = "Puzzle Map", category = "Objective", size = 1, swallowable = true },
	TrainManual = {
		id = "TrainManual",
		displayName = "Train Manual",
		category = "Objective",
		size = 0,
		swallowable = false,
	},

	-- Utility / misc (§6.5)
	Backpack = {
		id = "Backpack",
		displayName = "Backpack",
		category = "Utility",
		size = 0,
		swallowable = true,
		behavior = "Backpack",
	},
	HeartJar = { id = "HeartJar", displayName = "Heart Jar", category = "Utility", size = 2, swallowable = false }, -- TUNE swallowable
	Ladder = { id = "Ladder", displayName = "Ladder", category = "Utility", size = "X", swallowable = false }, -- TUNE swallowable
	Crate = { id = "Crate", displayName = "Crate", category = "Misc", size = "X", swallowable = true },
	CursedTrinket = {
		id = "CursedTrinket",
		displayName = "Cursed Trinket",
		category = "Misc",
		size = "X",
		swallowable = true,
	},
}

for id, kit in Kits do
	Items[id] = {
		id = id,
		displayName = kit.displayName,
		category = "Kit",
		size = "Kit",
		swallowable = true,
	}
end

return Items
