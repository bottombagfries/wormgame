--!strict
-- Match-level settings, debug toggles, and the greybox map layout.

return {
	DisplayName = "Untitled Worm Game", -- TUNE: player-facing title (never the original game's name)

	-- Match flow (§5.1)
	WormCount = 1,
	MinPlayers = 2, -- TUNE
	LobbySeconds = 20, -- TUNE: countdown once enough players are in; skipped when everyone is ready
	RoleAssignSeconds = 4, -- TUNE: how long the "You are a ..." reveal stays up
	WormLoadoutSeconds = 20,
	WormAbilityPicks = 2,
	EndingSeconds = 12, -- TUNE
	RespawnSeconds = 3, -- TUNE: for anyone who dies outside a match (lobby, spectators)
	MatchTickSeconds = 0.25, -- TUNE: how often MatchService and ObjectiveService re-check state
	DefaultDifficulty = "Normal",
	DifficultyOrder = { "Easy", "Normal", "Hard", "Wormfood" }, -- the host's lobby button cycles these
	ReviveLimit = -1, -- -1 = unlimited
	EnableBalloon = true,

	-- Balloon pilot (§11): airdrops, and the escape ladder when exactly one Pardner is left. All TUNE.
	Balloon = {
		Height = 90, -- above the ground it's over
		Speed = 45, -- studs/s
		ArriveDistance = 2,
		MinPardners = 2, -- the escape ladder only comes in matches that started with at least this many
		CheckSeconds = 0.5, -- how often the alive count is checked
		LadderWidth = 2,
		LadderHoldSeconds = 1, -- hold F at the foot of the ladder to climb aboard (= escape)
		LadderPromptHeight = 3, -- the prompt sits this far up the ladder
	},
	EnableWormlings = false,

	-- Objective count (§5.3). Index = pardner count, clamped to the last entry.
	ObjectiveCountMode = "Auto", -- "Auto" | "Flat"
	ObjectiveCountFlat = 3, -- TUNE
	ObjectiveCountByPardners = { 1, 1, 2, 3, 3, 4, 5, 6, 7 },

	-- Sundown (§5.4)
	Sundown = {
		Enabled = true,
		Seconds = 15 * 60,
		MinSeconds = 5 * 60,
		MaxSeconds = 40 * 60,
		AirdropFraction = 0.66, -- the balloon pilot drops chests this far into the day
		AirdropChests = 5,
		DayClockTime = 14, -- TUNE: Lighting.ClockTime during the day
		NightClockTime = 0, -- TUNE
	},

	-- Train & escape (§11)
	Train = {
		DepartSeconds = 120,
		EarlyDepartSeconds = 5,
		HornDisorientSeconds = 10,
		HornCooldownSeconds = 180,
		HornLeverLockSeconds = 12,
		HornRadius = 250, -- TUNE
		VendingSeconds = 120, -- the vending machine makes 1 of each active product this often (§7)
		VendingOffset = Vector3.new(6, 0, -14), -- TUNE: from the caboose end (Train's -X end), on the ground
		VendingHoldSeconds = 0.5, -- TUNE

		OnTrainHeight = 14, -- TUNE: a Pardner this far above the Train's top still counts as "on the Train"
		FurnacePadding = 1, -- TUNE: the furnace swallows items this far outside its model
		PromptDistance = 10, -- TUNE
		PromptSlack = 6, -- TUNE: extra studs the server allows on prompt distance
		LeverHoldSeconds = 0.5, -- TUNE
		HornHoldSeconds = 0.5, -- TUNE

		-- Where greybox parts sit on the Train when its model has no part with that name.
		-- X/Z are from the middle of the Train's top; they rest on the deck. All TUNE.
		FurnaceOffset = Vector3.new(34, 0, 0),
		LeverOffset = Vector3.new(24, 0, 4),
		HornOffset = Vector3.new(24, 0, -4),
		KeyholeOffset = Vector3.new(20, 0, 4),
		KeyholeHoldSeconds = 0.5, -- TUNE
	},

	-- Until ranch spawning exists (Phase 8), everyone spawns here, relative to the TrainSpot.
	TemporarySpawnOffset = Vector3.new(0, 0, 45), -- TUNE
	TemporarySpawnSize = Vector3.new(12, 1, 12),

	-- Default token bucket for Request_* remotes (§13)
	RateLimit = {
		PerSecond = 10, -- TUNE
		Burst = 20, -- TUNE
	},

	Debug = {
		Enabled = true,
		ShowMarkers = true, -- label every map marker
		MarkerTransparency = 0.5,
		LabelMaxDistance = 120,
		LogBootstrap = true,
		AllowSoloMatch = true, -- a match can start with one player (a Pardner, no Worm)
		NoWorm = false, -- everyone is a Pardner (for testing death and revive with two players)
		SpawnTestItems = true, -- a row of greybox items by the spawn
		TestItems = {
			"SmallCoal",
			"SmallCoal",
			"SmallCoal",
			"BigCoal",
			"MassiveCoal",
			"MassiveCoal",
			"MassiveCoal",
			"Barrel",
			"Crate",
			"Backpack",
			"Dynamite",
			"Dynamite",
			"Dynamite",
			"TrainKey",
			"Shovel",
			"Canteen",
			"Scrap",
			"Scrap",
			"Tumbleweed",
			"Tumbleweed",
		},
		TestItemOrigin = Vector3.new(-39, 0, 26),
		TestItemSpacing = 6,
		TestItemDropHeight = 2,
		SpawnTestWall = true, -- Phase 2 checkpoint: a wall to climb next to the spawn
		TestWallPosition = Vector3.new(60, 0, 45), -- ground point under the wall's center
		TestWallSize = Vector3.new(6, 40, 24),
		ChatCommands = true, -- Studio only: !hurt <n>, !heal <n>, !give <ItemId>
		ChatCommandDefaultAmount = 25,
		GiveDistance = 4, -- !give <ItemId> drops the item this far in front of you
		ChurchNearTrain = true, -- put the Church next to the Train instead of at a far-off ChurchSpot
		SpawnTestHouse = true, -- an extra house (with loot) next to the spawn, to blow up
		TestHouseOffset = Vector3.new(90, 0, 60), -- from the TrainSpot
		AlwaysDropScrap = false, -- destroyed structures drop scrap even without the Repair Tracks objective
		-- Objectives that are always picked, on top of the normal count (for testing one objective solo).
		ForceObjectives = {}, -- e.g. { "OpenSafe" }
		ShowBuried = true, -- a see-through marker over everything buried (key, horseshoes)
		BuriedMarkerColor = Color3.fromRGB(255, 80, 200),
		SpawnAtTrain = true, -- Pardners start at the lobby spawn by the Train instead of at the ranches
		LogMapSummary = true, -- print what MapService spawned for each marker type
		TestChurchOffset = Vector3.new(-90, 0, 70), -- from the TrainSpot
		DrawHitboxes = false,
		DrawRings = false,
		DrawPingRadius = false,
	},

	-- Auto-built map used when Workspace/MapTemplate is empty (§4). All TUNE.
	GreyboxMap = {
		Size = 1024,
		Thickness = 8,
		GroundY = 0,
		SandColor = Color3.fromRGB(218, 190, 130),
		Seed = 1337,
		MarkerSize = Vector3.new(4, 1, 4),

		EdgeMargin = 60, -- keep scattered markers this far from the map edge
		CenterClearRadius = 90, -- ...and this far from the train
		MinSeparation = 45, -- between scattered structure markers
		CactusSeparation = 12,
		ScatterAttempts = 30,

		TrackHalfLength = 420, -- track runs along X through the TrainSpot
		RanchRingRadius = 400,
		TownCenter = Vector3.new(-250, 0, -230),
		TownColumns = 5,
		TownSpacing = 48,
		QuarryPosition = Vector3.new(300, 0, -300),

		DigAreas = {
			{ Position = Vector3.new(220, 0, 220), Size = Vector3.new(300, 8, 300) },
			{ Position = Vector3.new(-260, 0, 200), Size = Vector3.new(260, 8, 260) },
		},
		LooseItemAreas = {
			{ Position = Vector3.new(0, 0, 0), Size = Vector3.new(900, 8, 900) },
		},

		Counts = {
			RanchSpot = 6,
			TownHouseSpot = 15,
			ChurchSpot = 2,
			LookoutSpot = 8,
			TraincarSpot = 12,
			BrokenTrackSpot = 10,
			StagecoachSpot = 5,
			SignalFireSpot = 10,
			CactusSpot = 60,
		},
	},
}
