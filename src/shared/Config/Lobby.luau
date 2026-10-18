--!strict
-- Phase 13: the lobby (an abandoned desert train station built far from the map), the round loop's
-- timings, the Worm role roll and AFK. All TUNE.

local v3 = Vector3.new
local rgb = Color3.fromRGB

return {
	-- Round loop: Lobby (waiting) -> Intermission -> RoleAssign (reveal) -> WormLoadout -> Playing -> Ending.
	IntermissionSeconds = 20, -- countdown once enough non-AFK players are in the lobby
	MinPlayers = 2, -- non-AFK players needed to start (Debug.AllowSoloMatch lowers it to 1)
	RoleRevealSeconds = 4, -- the full-screen "YOU ARE ..." card
	ResultsSeconds = 12, -- the results screen before everyone is sent back to the lobby

	-- Worm role roll: every eligible (non-AFK) player has a weight; the Worm is drawn by weight. Each round
	-- someone plays and isn't the Worm their weight grows; being the Worm resets it.
	RoleRoll = {
		BaseWeight = 1,
		WeightPerRound = 1, -- added for each round played as a Pardner
		MaxWeight = 10,
	},

	-- The full-screen role card shown during RoleAssign (colors come from Config/Theme).
	RoleCards = {
		Worm = {
			title = "YOU ARE THE WORM",
			description = "Swim under the sand. Feel them run. Eat every last Pardner before the Train leaves.",
		},
		Pardner = {
			title = "YOU ARE A PARDNER",
			description = "Scavenge, finish the objectives and fuel the Train. Keep still on the sand - it can feel you.",
		},
		WaitSeconds = 0.6, -- the description fades in this long after the title lands
	},

	-- Where the station sits. The map is a 1024-stud square centered on the origin, so this is well clear.
	Origin = v3(0, 0, 3000),

	-- Each piece is placed through AssetService, so a real model can replace any greybox. `position` is
	-- where the bottom-center of the piece sits, relative to Origin; `yaw` is in degrees.
	Pieces = {
		{ id = "LobbyGround", position = v3(0, -2, 0) },
		{ id = "LobbyTrack", position = v3(0, 0, -16) },
		{ id = "LobbyPlatform", position = v3(0, 0, 0) },
		{ id = "LobbyDepot", position = v3(0, 0, 17) },
		{ id = "LobbyBoard", position = v3(0, 3, 6.5) },
		{ id = "LobbyTicketBooth", position = v3(-34, 3, 3) },
		{ id = "LobbyBench", position = v3(-18, 3, 4) },
		{ id = "LobbyBench", position = v3(16, 3, 4) },
		{ id = "LobbyBench", position = v3(30, 3, 4) },
		{ id = "LobbyLamp", position = v3(-40, 3, -6.5) },
		{ id = "LobbyLamp", position = v3(-17, 3, -6.5) },
		{ id = "LobbyLamp", position = v3(11, 3, -6.5) },
		{ id = "LobbyLamp", position = v3(36, 3, -6.5) },
		{ id = "Barrel", position = v3(40, 3, 5) },
		{ id = "Barrel", position = v3(42.5, 3, 3.5), yaw = 30 },
		{ id = "Crate", position = v3(-42, 3, -4), yaw = 20 },
		{ id = "Crate", position = v3(-44, 3, 1), yaw = -10 },
		-- Leftovers around the station, reusing the map's models
		{ id = "Watertower", position = v3(58, 0, 34), yaw = 15 },
		{ id = "Traincar", position = v3(-38, 0, -34), yaw = 6 },
		{ id = "Stagecoach", position = v3(-52, 0, 34), yaw = 35 },
		{ id = "CactusTall", position = v3(-64, 0, 14), yaw = 40 },
		{ id = "CactusTall", position = v3(30, 0, 40), yaw = 110 },
		{ id = "CactusTall", position = v3(60, 0, -36), yaw = 200 },
		{ id = "CactusSmall", position = v3(8, 0, -40), yaw = 70 },
		{ id = "CactusSmall", position = v3(-66, 0, -14), yaw = 150 },
	},

	-- The big departures board. Its text is drawn on the face that looks toward -Z (at the platform).
	Board = {
		Id = "LobbyBoard",
		ScreenPart = "Screen", -- a part with this name in a real model holds the text; else the PrimaryPart
		PixelsPerStud = 40,
		LastResultPrefix = "LAST TRAIN: ",
		NoLastResult = "No trains yet today",
	},

	-- Spawn pads on the platform (positions are the pad's bottom-center, relative to Origin).
	SpawnPads = {
		Size = v3(6, 0.4, 6),
		Color = rgb(214, 160, 58),
		Positions = { v3(-24, 3, -3), v3(-10, 3, -3), v3(4, 3, -3), v3(18, 3, -3) },
	},

	-- Invisible walls around the station: a box this size centered on Origin.
	Walls = {
		Size = v3(150, 60, 110),
		Center = v3(0, 0, 4),
		Thickness = 2,
	},
}
