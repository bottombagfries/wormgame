--!strict
-- Objective definitions (§10). Behavior modules arrive in Phases 4 and 9.

local Types = require(script.Parent.Parent.Types)

local Objectives: { [string]: Types.ObjectiveDef } = {
	FuelTrain = {
		id = "FuelTrain",
		displayName = "Fuel the Train",
		always = true,
		countsTowardTotal = true,
		enabledByDefault = true,
	},
	FindTrainKey = {
		id = "FindTrainKey",
		displayName = "Find the Train Key",
		always = false,
		countsTowardTotal = true,
		enabledByDefault = true,
		-- Decoy horseshoes per match come from Difficulty.horseshoes; digging tuning is Kits.Shovel.params.
		params = {
			SkeletonOffset = Vector3.new(0, 0, 4), -- TUNE: the skeleton lies next to the dug-up key
			BuryAttempts = 20, -- TUNE: tries to find sand inside a DigArea for each buried thing
			FallbackOffset = Vector3.new(0, 0, 40), -- from the TrainSpot, when the map has no DigArea
		},
	},
	LightSignalFires = {
		id = "LightSignalFires",
		displayName = "Light the Signal Fires",
		always = false,
		countsTowardTotal = true,
		enabledByDefault = true,
		-- Fires per match come from Difficulty.signalFires; burn time is ItemTuning.TumbleweedBurnSeconds.
		params = {
			LightRadius = 7, -- TUNE: a tumbleweed (held or loose) this close to the furnace catches fire
			FireRadius = 7, -- TUNE: a burning tumbleweed this close to an unlit signal fire lights it
			LitColor = Color3.fromRGB(230, 120, 40),
			FallbackOffset = Vector3.new(120, 0, 120), -- from the TrainSpot, when the map has no SignalFireSpot
			FireSize = 12, -- the Fire effect's Size on a lit signal fire
			LabelSize = UDim2.fromOffset(160, 24),
			LabelHeight = 5, -- studs above the fire
		},
	},
	HerdCattlebugs = {
		id = "HerdCattlebugs",
		displayName = "Herd the Cattlebugs",
		always = false,
		countsTowardTotal = true,
		enabledByDefault = true,
		-- Bugs per match come from Difficulty.cattlebugs; flower limits from Kits.DandylionBundle.params.
		params = {
			PenOffset = Vector3.new(-20, 0, 30), -- TUNE: pen center from the caboose end (Train's -X end)
			PenRadius = 10, -- TUNE: a bug this close to the pen's center is delivered
			PenColor = Color3.fromRGB(120, 180, 90),
			Bundles = 2, -- dandylion bundles waiting behind the caboose at the start (§7)
			BundleOffset = Vector3.new(-6, 0, 16), -- TUNE: from the caboose end (kept outside the pen)
			FallbackOffset = Vector3.new(0, 0, -150), -- from the TrainSpot, when no loose-loot sand is found
			BugSpeed = 8, -- TUNE: studs/s
			WanderRadius = 30, -- TUNE: a wandering bug picks a new spot within this
			WanderSeconds = 6, -- TUNE: ...at least this often
			ArriveDistance = 1, -- TUNE: a wander spot counts as reached this close
			PennedColor = Color3.fromRGB(120, 180, 90),
			LabelSize = UDim2.fromOffset(200, 24),
			LabelHeight = 3,
		},
	},
	RepairTracks = {
		id = "RepairTracks",
		displayName = "Repair the Tracks",
		always = false,
		countsTowardTotal = true,
		enabledByDefault = true,
		-- Broken tracks per match come from Difficulty.brokenTracks; traincars from Structures.Traincar.PerMatch.
		params = {
			ScrapPerTrack = 2,
			RepairRadius = 8, -- TUNE: scrap dropped this close to a broken track is used up
			MinTrainDistance = 60, -- TUNE: broken tracks are never picked this close to the Train
			TraincarBuryFraction = 0.5, -- traincars are half buried (§7)
			RepairedColor = Color3.fromRGB(110, 110, 115),
			LabelSize = UDim2.fromOffset(160, 24),
			LabelHeight = 4, -- studs above the track
		},
	},
	DeliverSassparilla = {
		id = "DeliverSassparilla",
		displayName = "Deliver Sassparilla",
		always = false,
		countsTowardTotal = true,
		enabledByDefault = true,
		-- Bottles needed come from Difficulty.sassparillaBottles; coaches/crates from Structures.Stagecoach;
		-- bottles per crate and breakage from ItemTuning.
		params = {
			DropOffGap = 20, -- TUNE: the drop-off zone's center is this far past the caboose (Train's -X end)
			DropOffRadius = 10, -- TUNE: a loose crate this close to it is delivered
			RingColor = Color3.fromRGB(160, 110, 50),
			CrateGap = 3, -- TUNE: crates wait this far from the stagecoach's side
			BreakCooldown = 0.3, -- TUNE: one impact can only break bottles once
			FallbackOffset = Vector3.new(-150, 0, 150), -- from the TrainSpot, when the map has no StagecoachSpot
			LabelSize = UDim2.fromOffset(200, 24),
			LabelHeight = 3, -- studs above the drop-off ring
		},
	},
	OpenSafe = {
		id = "OpenSafe",
		displayName = "Open the Safe",
		always = false,
		countsTowardTotal = true,
		enabledByDefault = true,
		-- Digits in the code come from Difficulty.safeDigits.
		params = {
			DigitSigns = 12, -- signs placed on the sand; only safeDigits of them make the code (§10.7)
			PuzzleMaps = 3, -- TUNE: puzzle maps waiting at the caboose at the start (§7)
			MapOffset = Vector3.new(-12, 0, -18), -- TUNE: from the caboose end
			PromptHoldSeconds = 0.3, -- TUNE
			WrongCodeCooldown = 1, -- TUNE: seconds before the keypad takes another try
			FallbackSafeOffset = Vector3.new(0, 0, 60), -- from the TrainSpot, when there are no ranch houses
			SignLabelSize = UDim2.fromOffset(60, 60),
			SignLabelHeight = 2,
		},
	},
	EscapeBalloon = {
		id = "EscapeBalloon",
		displayName = "Escape Balloon",
		always = true, -- only when Config.Game.EnableBalloon
		countsTowardTotal = false,
		enabledByDefault = true,
	},
}

return Objectives
