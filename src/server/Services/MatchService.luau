--!strict
-- Round loop (§5.1, Phase 13): Lobby (waiting) -> Intermission -> RoleAssign (role card) -> WormLoadout ->
-- Playing -> Ending (results) -> Lobby, all on one server. The map is loaded for the round and unloaded
-- after; between rounds everyone waits at the lobby station (Map/Lobby).
-- Owns roles, match settings, the worm's ability picks and the sundown clock (§5.4).
--
-- Replication: State_Match carries a Types.MatchState; each player also gets attributes
--   Role ("Pardner" | "Worm" | "None"), Afk (boolean), Abilities (comma-separated ids, worms only).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local LobbyConfig = require(ReplicatedStorage.Shared.Config.Lobby)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local RoleRoll = require(ReplicatedStorage.Shared.RoleRoll)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ItemService = require(script.Parent.ItemService)
local AbilityService = require(script.Parent.AbilityService)
local ExplosionService = require(script.Parent.ExplosionService)
local MapService = require(script.Parent.MapService)
local NPCService = require(script.Parent.NPCService)
local Lobby = require(script.Parent.Parent.Map.Lobby)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)
local ObjectiveService = require(script.Parent.ObjectiveService)
local PardnerService = require(script.Parent.PardnerService)
local ReviveService = require(script.Parent.ReviveService)
local StructureService = require(script.Parent.StructureService)
local TrainService = require(script.Parent.TrainService)
local WormService = require(script.Parent.WormService)

local Debug = GameConfig.Debug
local TICK = GameConfig.MatchTickSeconds
local NO_ROLE = "None"
local ERROR_RETRY_SECONDS = 2

local MatchService = {}

-- Fires once per match when night falls.
local sundown: Signal.Signal<> = Signal.new()
local phaseChanged: Signal.Signal<Types.MatchPhase> = Signal.new()
MatchService.sundown = sundown
MatchService.phaseChanged = phaseChanged

local matchRemote: RemoteEvent
local notifyRemote: RemoteEvent

local phase: Types.MatchPhase = "Lobby"
local endsAt: number? = nil
local sundownAt: number? = nil
local night = false
local result: Types.MatchResult? = nil
local settings: Types.MatchSettings
local host: Player? = nil
local roles: { [Player]: Types.Role } = {}
local loadouts: { [Player]: { string } } = {}
local trainOutcome: { Player }? = nil -- who escaped, once the Train has left
local lastResult: string? = nil -- one line about the previous round (lobby board + HUD)
-- Worm roll weight per UserId for this server session (Config.Lobby.RoleRoll). TODO: save with data saving.
local wormWeights: { [number]: number } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function defaultSettings(): Types.MatchSettings
	local enabled = {}
	for id, def in Objectives do
		enabled[id] = def.enabledByDefault
	end
	return {
		difficulty = GameConfig.DefaultDifficulty,
		sundownSeconds = if GameConfig.Sundown.Enabled then GameConfig.Sundown.Seconds else 0,
		objectiveCountMode = if GameConfig.ObjectiveCountMode == "Flat" then "Flat" else "Auto",
		objectiveCountFlat = GameConfig.ObjectiveCountFlat,
		enabledObjectives = enabled,
		reviveLimit = GameConfig.ReviveLimit,
		enableBalloon = GameConfig.EnableBalloon,
		enableWormlings = GameConfig.EnableWormlings,
	}
end

local function minPlayers(): number
	return if Debug.Enabled and Debug.AllowSoloMatch then 1 else LobbyConfig.MinPlayers
end

-- Players who can be put in the next round (not AFK).
local function activePlayers(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Afk") ~= true then
			table.insert(list, player)
		end
	end
	return list
end

-- How many Worms a round with `playerCount` players gets: WormCount, but always at least one Pardner.
local function wormSlots(playerCount: number): number
	if Debug.Enabled and Debug.NoWorm then
		return 0
	end
	return math.max(0, math.min(GameConfig.WormCount, playerCount - 1))
end

local function wormWeight(player: Player): number
	return wormWeights[player.UserId] or LobbyConfig.RoleRoll.BaseWeight
end

-- Every player's WormChance attribute (0-100, rounded) for the next roll; AFK players get 0.
local function refreshWormChances()
	local players = activePlayers()
	local weights = {}
	for _, player in players do
		weights[player] = wormWeight(player)
	end
	local chances = RoleRoll.chances(weights, wormSlots(#players))
	for _, player in Players:GetPlayers() do
		player:SetAttribute("WormChance", math.round(chances[player] or 0))
	end
end

local function buildState(): Types.MatchState
	local players = Players:GetPlayers()
	if not host or host.Parent ~= Players then
		host = players[1]
	end
	return {
		phase = phase,
		endsAt = endsAt,
		sundownAt = sundownAt,
		night = night,
		difficulty = settings.difficulty,
		hostUserId = if host then host.UserId else 0,
		playerCount = #players,
		activeCount = #activePlayers(),
		minPlayers = minPlayers(),
		result = result,
		lastResult = lastResult,
	}
end

local function broadcast()
	matchRemote:FireAllClients(buildState())
end

local function updateBoard()
	local text
	if phase == "Lobby" then
		text = `WAITING FOR PLAYERS  {#activePlayers()}/{minPlayers()}`
	elseif phase == "Intermission" then
		local left = math.max(0, math.ceil((endsAt or now()) - now()))
		text = string.format("NEXT TRAIN IN %d:%02d", left // 60, left % 60)
	elseif phase == "Ending" then
		text = "TRAIN ARRIVING"
	else
		text = "TRAIN IN PROGRESS"
	end
	Lobby.setStatus(text)
end

local function enterPhase(newPhase: Types.MatchPhase, phaseEndsAt: number?)
	phase = newPhase
	endsAt = phaseEndsAt
	updateBoard()
	broadcast()
	phaseChanged:fire(newPhase)
end

local function setRole(player: Player, role: Types.Role?)
	roles[player] = role :: any
	player:SetAttribute("Role", role or NO_ROLE)
	if not role then
		loadouts[player] = nil
		player:SetAttribute("Abilities", nil)
	end
end

local function playersWithRole(role: Types.Role): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if roles[player] == role then
			table.insert(list, player)
		end
	end
	return list
end

local function names(players: { Player }): { string }
	local list = {}
	for _, player in players do
		table.insert(list, player.DisplayName)
	end
	return list
end

-- The teleport to the map: each Pardner gets a fresh character at a random ranch spawn (§4), or beside
-- the Train with Debug.SpawnAtTrain. Worms have no humanoid character (WormService builds theirs).
local function sendPardnersToMap(pardners: { Player })
	local spawns = MapService.getPardnerSpawns()
	local atTrain = (Debug.Enabled and Debug.SpawnAtTrain) or #spawns == 0
	for _, player in pardners do
		task.spawn(function()
			local ok = pcall(player.LoadCharacter, player)
			local character = player.Character
			if ok and character then
				character:PivotTo(
					if atTrain
						then MapService.getTrainSpawn()
						else RandomUtil.pick(spawns) * CFrame.new(0, Structures.Ranch.SpawnHeight, 0)
				)
			end
		end)
	end
end

-- Back to the station: a fresh character on a lobby spawn pad.
local function sendToLobby(players: { Player })
	for _, player in players do
		if player.Parent == Players then
			task.spawn(pcall, player.LoadCharacter, player)
		end
	end
end

-- The board's big line and the round summary (also sent to clients as lastResult).
local function describeResult(matchResult: Types.MatchResult): string
	local total = #matchResult.escaped + #matchResult.dead
	if matchResult.winner == "Pardners" then
		return `Pardners escaped ({#matchResult.escaped} of {total})`
	end
	return "The Worm ate everyone"
end

local function choosableAbilities(): { string }
	local ids = {}
	for id, def in Abilities do
		if def.kind == "Choosable" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

local function setLoadout(player: Player, ids: { string })
	loadouts[player] = ids
	player:SetAttribute("Abilities", table.concat(ids, ","))
end

-- Phases ----------------------------------------------------------------------------------------

-- Lobby ("Waiting for players") until enough active players are in, then the Intermission countdown.
-- Dropping below the minimum during the countdown goes back to waiting.
local function runLobby()
	if MapService.isMapLoaded() then
		MapService.unloadMap()
		TrainService.setActive(false)
	end
	enterPhase("Lobby", nil)

	local lastSignature = ""
	while true do
		local enough = #activePlayers() >= minPlayers()
		if enough and phase ~= "Intermission" then
			enterPhase("Intermission", now() + LobbyConfig.IntermissionSeconds)
		elseif not enough and phase ~= "Lobby" then
			enterPhase("Lobby", nil)
		end
		if phase == "Intermission" and now() >= (endsAt or 0) then
			return
		end

		local signature = `{#Players:GetPlayers()}:{#activePlayers()}:{settings.difficulty}`
		if signature ~= lastSignature then
			lastSignature = signature
			refreshWormChances()
			broadcast()
		end
		updateBoard()
		task.wait(TICK)
	end
end

-- WormCount Worms drawn by weight (Config.Lobby.RoleRoll), but always at least one Pardner. Only active
-- (non-AFK) players take part; everyone else stays in the lobby. The map is loaded here, while the role
-- card is up. Weights: Pardners gain WeightPerRound, Worms go back to BaseWeight.
local function runRoleAssign()
	MapService.loadMap()
	TrainService.setActive(true)
	local players = activePlayers()
	local weights = {}
	for _, player in players do
		weights[player] = wormWeight(player)
	end
	local worms = RoleRoll.pick(weights, wormSlots(#players), Random.new())

	local Roll = LobbyConfig.RoleRoll
	table.clear(loadouts)
	for _, player in players do
		local role: Types.Role = if table.find(worms, player) then "Worm" else "Pardner"
		setRole(player, role)
		if role == "Pardner" then
			PardnerService.add(player)
			wormWeights[player.UserId] = math.min(Roll.MaxWeight, wormWeight(player) + Roll.WeightPerRound)
		else
			wormWeights[player.UserId] = Roll.BaseWeight
		end
	end
	refreshWormChances()
	enterPhase("RoleAssign", now() + LobbyConfig.RoleRevealSeconds)
	task.wait(LobbyConfig.RoleRevealSeconds)
end

-- Worms pick their abilities; anything left unpicked when time runs out is filled at random.
local function runWormLoadout()
	local worms = playersWithRole("Worm")
	if #worms == 0 then
		return
	end

	local deadline = now() + GameConfig.WormLoadoutSeconds
	enterPhase("WormLoadout", deadline)
	while now() < deadline do
		local allPicked = true
		for _, worm in playersWithRole("Worm") do
			local picks = loadouts[worm]
			if not picks or #picks < GameConfig.WormAbilityPicks then
				allPicked = false
			end
		end
		if allPicked then
			break
		end
		task.wait(TICK)
	end

	for _, worm in playersWithRole("Worm") do
		local picks = table.clone(loadouts[worm] or {})
		for _, id in RandomUtil.shuffle(choosableAbilities()) do
			if #picks >= GameConfig.WormAbilityPicks then
				break
			end
			if not table.find(picks, id) then
				table.insert(picks, id)
			end
		end
		setLoadout(worm, picks)
	end
end

local function runPlaying(): Types.MatchResult
	ItemService.clearAll()
	ExplosionService.clearAll()
	MapService.populate(settings)
	TrainService.spawnContents()
	if Debug.Enabled and Debug.SpawnTestItems then
		ItemService.spawnTestItems()
	end
	for _, worm in playersWithRole("Worm") do
		WormService.add(worm)
	end

	-- Re-added so anything that happened before the match (a fall in the lobby) is forgotten.
	local pardners = playersWithRole("Pardner")
	for _, pardner in pardners do
		PardnerService.remove(pardner)
		PardnerService.add(pardner)
	end
	sendPardnersToMap(pardners)

	ReviveService.begin(settings)
	ObjectiveService.begin({
		pardnerCount = #pardners,
		difficulty = settings.difficulty,
		settings = settings,
	})
	-- Scrap only matters for Repair Tracks (§5.3).
	StructureService.setScrapEnabled(
		ObjectiveService.isActive("RepairTracks") or (Debug.Enabled and Debug.AlwaysDropScrap)
	)

	night = false
	WormService.setNight(false)
	Lighting.ClockTime = GameConfig.Sundown.DayClockTime
	local startedAt = now()
	sundownAt = if settings.sundownSeconds > 0 then startedAt + settings.sundownSeconds else nil
	local airdropAt = if settings.sundownSeconds > 0
		then startedAt + settings.sundownSeconds * GameConfig.Sundown.AirdropFraction
		else nil
	trainOutcome = nil
	-- The balloon only comes for a last survivor if there were others to lose (§11).
	NPCService.beginMatch(settings.enableBalloon and #pardners >= GameConfig.Balloon.MinPardners)
	enterPhase("Playing", nil)

	while true do
		task.wait(TICK)

		local escaped = trainOutcome
		if escaped then
			-- Whoever is not on the Train when it leaves is dead (§11).
			local dead = {}
			for _, player in playersWithRole("Pardner") do
				if not table.find(escaped, player) then
					table.insert(dead, player)
				end
			end
			return {
				winner = if #escaped > 0 then "Pardners" else "Worm",
				escaped = names(escaped),
				dead = names(dead),
			}
		end

		-- No Pardner left alive (or in the game): nobody can carry a heart jar, so the Worm wins (§5.1).
		if PardnerService.getAliveCount() == 0 then
			return { winner = "Worm", escaped = {}, dead = names(playersWithRole("Pardner")) }
		end

		-- 66 % of the way to sundown: the balloon pilot's supply drop (§5.4).
		local dropAt = airdropAt
		if dropAt and now() >= dropAt then
			airdropAt = nil
			NPCService.airdrop(GameConfig.Sundown.AirdropChests)
		end

		-- Sundown (§5.4). Night cooldowns (AbilityService), faster outer-ring healing (WormService), whole-map
		-- Sonar (SonarScream) and no Church revives (ReviveService) all key off the night flag set here.
		local sunsetAt = sundownAt
		if sunsetAt and not night and now() >= sunsetAt then
			night = true
			WormService.setNight(true)
			ReviveService.setNight(true)
			PardnerService.sundownTopUp()
			Lighting.ClockTime = GameConfig.Sundown.NightClockTime -- TODO(asset): proper night lighting
			SoundCue.play("Sundown")
			notifyRemote:FireAllClients("Sundown! The Worm grows stronger...", "Sundown")
			broadcast()
			sundown:fire()
		end
	end
end

local function cleanupMatch()
	ObjectiveService.finish()
	ReviveService.finish()
	AbilityService.clear()
	NPCService.endMatch()
	WormService.removeAll()
	WormService.setNight(false)
	for _, player in PardnerService.getPardners() do
		PardnerService.remove(player)
	end
	for _, player in Players:GetPlayers() do
		setRole(player, nil)
	end
	table.clear(roles)
	table.clear(loadouts)
	ItemService.clearAll()
	MapService.unloadMap()
	ExplosionService.clearAll()
	TrainService.reset(1)
	TrainService.setActive(false)

	night = false
	sundownAt = nil
	result = nil
	trainOutcome = nil
	Lighting.ClockTime = GameConfig.Sundown.DayClockTime
end

-- Results, then everyone who played (and anyone without a character) goes back to the lobby.
local function runEnding(matchResult: Types.MatchResult)
	result = matchResult
	lastResult = describeResult(matchResult)
	Lobby.setLastResult(lastResult)
	enterPhase("Ending", now() + LobbyConfig.ResultsSeconds)
	updateBoard()
	task.wait(LobbyConfig.ResultsSeconds)

	local returning = {}
	for _, player in Players:GetPlayers() do
		if roles[player] or not player.Character then
			table.insert(returning, player)
		end
	end
	cleanupMatch()
	sendToLobby(returning)
end

local function runMatch()
	runLobby()
	runRoleAssign()
	runWormLoadout()
	runEnding(runPlaying())
end

-- Request handlers ------------------------------------------------------------------------------

-- AFK players are skipped by the role roll and stay in the lobby (they can still spectate).
local function onSetAfk(player: Player, state: any)
	if typeof(state) == "boolean" then
		player:SetAttribute("Afk", state)
		refreshWormChances()
		broadcast()
	end
end

local function onSetDifficulty(player: Player, name: any)
	local inLobby = phase == "Lobby" or phase == "Intermission"
	if not inLobby or player ~= host or typeof(name) ~= "string" or not Difficulty[name] then
		return
	end
	settings.difficulty = name
end

local function onSelectAbilities(player: Player, ids: any)
	if phase ~= "WormLoadout" or roles[player] ~= "Worm" or typeof(ids) ~= "table" then
		return
	end
	if #ids > GameConfig.WormAbilityPicks then
		return
	end
	local picks: { string } = {}
	for _, id in ids do
		local def = if typeof(id) == "string" then Abilities[id] else nil
		if not def or def.kind ~= "Choosable" or table.find(picks, id) then
			return
		end
		table.insert(picks, id)
	end
	setLoadout(player, picks)
end

-- Public API ------------------------------------------------------------------------------------

function MatchService.getPhase(): Types.MatchPhase
	return phase
end

function MatchService.getSettings(): Types.MatchSettings
	return settings
end

function MatchService.getRole(player: Player): Types.Role?
	return roles[player]
end

function MatchService.getPlayersWithRole(role: Types.Role): { Player }
	return playersWithRole(role)
end

-- The worm's chosen ability ids (empty until WormLoadout has finished).
function MatchService.getLoadout(player: Player): { string }
	return loadouts[player] or {}
end

function MatchService.isNight(): boolean
	return night
end

function MatchService.init()
	matchRemote = Net.event("State_Match")
	notifyRemote = Net.event("Fx_Notify")
	settings = defaultSettings()
	-- Dead Pardners must not respawn on their own; every character is loaded by this service.
	Players.CharacterAutoLoads = false
end

function MatchService.start()
	Net.onRequest("Request_SetAfk", onSetAfk)
	Net.onRequest("Request_SetDifficulty", onSetDifficulty)
	Net.onRequest("Request_SelectAbilities", onSelectAbilities)

	TrainService.departed:connect(function(escaped: { Player })
		if phase == "Playing" then
			trainOutcome = escaped
		end
	end)
	-- Climbing the balloon's ladder is an escape too; the Pardners win (§5.1).
	NPCService.balloonEscaped:connect(function(player: Player)
		if phase == "Playing" and not trainOutcome then
			trainOutcome = { player }
		end
	end)

	-- Anyone who joins mid-match watches until the next lobby.
	local function onPlayerAdded(player: Player)
		setRole(player, nil)
		matchRemote:FireClient(player, buildState())

		-- Characters are loaded by hand (CharacterAutoLoads is off). A Pardner who dies mid-match
		-- becomes a ghost (ReviveService); anyone else who dies simply respawns.
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Connect(function()
				task.wait(GameConfig.RespawnSeconds)
				local ghost = phase == "Playing" and PardnerService.isPardner(player)
				if player.Parent and player.Character == character and not ghost then
					pcall(player.LoadCharacter, player)
				end
			end)
		end)
		if not player.Character then
			task.spawn(function()
				pcall(player.LoadCharacter, player)
			end)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		roles[player] = nil
		loadouts[player] = nil
	end)

	task.spawn(function()
		while true do
			local ok, message = xpcall(runMatch, debug.traceback)
			if not ok then
				warn(`[MatchService] Match loop error, returning to the lobby:\n{message}`)
				cleanupMatch()
				sendToLobby(Players:GetPlayers())
				task.wait(ERROR_RETRY_SECONDS)
			end
		end
	end)
end

return MatchService
