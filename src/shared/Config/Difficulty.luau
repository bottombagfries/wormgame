--!strict
-- Difficulty table (§5.2).

local Types = require(script.Parent.Parent.Types)

local Difficulty: { [string]: Types.DifficultyDef } = {
	Easy = {
		horseshoes = 0,
		signalFires = 1,
		cattlebugs = 1,
		brokenTracks = 1,
		sassparillaBottles = 12,
		safeDigits = 2,
		fuelPointsBase = 30, -- TUNE
		fuelPointsPerPardner = 3, -- TUNE
		wormlingLimit = 3,
		wormlingSpawnSeconds = 90,
		wormlingHatchMult = 0.75,
	},
	Normal = {
		horseshoes = 2,
		signalFires = 3,
		cattlebugs = 3,
		brokenTracks = 3,
		sassparillaBottles = 18,
		safeDigits = 3,
		fuelPointsBase = 45, -- TUNE
		fuelPointsPerPardner = 5, -- TUNE
		wormlingLimit = 6,
		wormlingSpawnSeconds = 60,
		wormlingHatchMult = 1,
	},
	Hard = {
		horseshoes = 4,
		signalFires = 5,
		cattlebugs = 5,
		brokenTracks = 5,
		sassparillaBottles = 30,
		safeDigits = 5,
		fuelPointsBase = 60, -- TUNE
		fuelPointsPerPardner = 7, -- TUNE
		wormlingLimit = 8,
		wormlingSpawnSeconds = 40,
		wormlingHatchMult = 1.25,
	},
	Wormfood = {
		horseshoes = 7,
		signalFires = 8,
		cattlebugs = 8,
		brokenTracks = 8,
		sassparillaBottles = 48,
		safeDigits = 8,
		fuelPointsBase = 80, -- TUNE
		fuelPointsPerPardner = 9, -- TUNE
		wormlingLimit = 12,
		wormlingSpawnSeconds = 20,
		wormlingHatchMult = 2,
	},
}

return Difficulty
