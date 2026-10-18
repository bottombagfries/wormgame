--!strict
-- Match flow (§5.1): Lobby -> RoleAssign -> WormLoadout -> Playing -> Ending -> Lobby.
-- Owns roles, match settings, the worm's ability picks and the sundown clock (§5.4).
--
-- Replication: State_Match carries a Types.MatchState; each player also gets attributes
--   Role ("Pardner" | "Worm" | "None"), Ready (boolean), Abilities (comma-separated ids, worms only).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ItemService = require(script.Parent.ItemService)
local AbilityService = require(script.Parent.AbilityService)
local ExplosionService = require(script.Parent.ExplosionService)
local MapService = require(script.Parent.MapService)
local NPCService = require(script.Parent.NPCService)
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
	return if Debug.Enabled and Debug.AllowSoloMatch then 1 else GameConfig.MinPlayers
end

local function countReady(players: { Player }): number
	local ready = 0
	for _, player in players do
		if player:GetAttribute("Ready") == true then
			ready += 1
		end
	end
	return ready
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
		readyCount = countReady(players),
		minPlayers = minPlayers(),
		result = result,
	}
end

local function broadcast()
	matchRemote:FireAllClients(buildState())
end

local function enterPhase(newPhase: Types.MatchPhase, phaseEndsAt: number?)
	phase = newPhase
	endsAt = phaseEndsAt
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

-- Worms have no humanoid character, so they are skipped. With `atRanches`, Pardners are moved to a
-- random ranch spawn (§4) once their character exists; everyone else uses the lobby spawn.
local function respawnEveryone(atRanches: boolean?)
	local spawns = MapService.getPardnerSpawns()
	for _, player in Players:GetPlayers() do
		if not WormService.isWorm(player) then
			task.spawn(function()
				local ok = pcall(player.LoadCharacter, player)
				local character = player.Character
				local ranch = atRanches and roles[player] == "Pardner" and #spawns > 0
				if ok and character and ranch then
					character:PivotTo(RandomUtil.pick(spawns) * CFrame.new(0, Structures.Ranch.SpawnHeight, 0))
				end
			end)
		end
	end
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

-- Waits for enough players, then for the countdown or for everyone to press Ready.
local function runLobby()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Ready", false)
	end
	enterPhase("Lobby", nil)

	local lastSignature = ""
	while true do
		local players = Players:GetPlayers()
		local ready = countReady(players)
		if #players >= minPlayers() then
			local countdownEnds = endsAt or now() + GameConfig.LobbySeconds
			endsAt = countdownEnds
			if ready == #players or now() >= countdownEnds then
				return
			end
		else
			endsAt = nil
		end

		local signature = `{#players}:{ready}:{endsAt or 0}:{settings.difficulty}`
		if signature ~= lastSignature then
			lastSignature = signature
			broadcast()
		end
		task.wait(TICK)
	end
end

-- WormCount random worms, but always at least one Pardner.
local function runRoleAssign()
	local players = RandomUtil.shuffle(Players:GetPlayers())
	local wormCount = math.max(0, math.min(GameConfig.WormCount, #players - 1))
	if Debug.Enabled and Debug.NoWorm then
		wormCount = 0
	end
	table.clear(loadouts)
	for index, player in players do
		local role: Types.Role = if index <= wormCount then "Worm" else "Pardner"
		setRole(player, role)
		if role == "Pardner" then
			PardnerService.add(player)
		end
	end
	enterPhase("RoleAssign", now() + GameConfig.RoleAssignSeconds)
	task.wait(GameConfig.RoleAssignSeconds)
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
	respawnEveryone(not (Debug.Enabled and Debug.SpawnAtTrain))

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
			notifyRemote:FireAllClients("The sun has set. The Worm grows stronger...")
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
	MapService.clearRuntime()
	ExplosionService.clearAll()
	TrainService.reset(1)

	night = false
	sundownAt = nil
	result = nil
	trainOutcome = nil
	Lighting.ClockTime = GameConfig.Sundown.DayClockTime
end

local function runEnding(matchResult: Types.MatchResult)
	result = matchResult
	enterPhase("Ending", now() + GameConfig.EndingSeconds)
	task.wait(GameConfig.EndingSeconds)
	cleanupMatch()
	respawnEveryone()
end

local function runMatch()
	runLobby()
	runRoleAssign()
	runWormLoadout()
	runEnding(runPlaying())
end

-- Request handlers ------------------------------------------------------------------------------

local function onReady(player: Player, state: any)
	if phase == "Lobby" and typeof(state) == "boolean" then
		player:SetAttribute("Ready", state)
	end
end

local function onSetDifficulty(player: Player, name: any)
	if phase ~= "Lobby" or player ~= host or typeof(name) ~= "string" or not Difficulty[name] then
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
	Net.onRequest("Request_Ready", onReady)
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
		player:SetAttribute("Ready", false)
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
				task.wait(ERROR_RETRY_SECONDS)
			end
		end
	end)
end

return MatchService
