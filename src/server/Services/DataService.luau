--!strict
-- Saved player data (Config/Progression): Settings-window values, the chosen worm skin and lifetime stats,
-- in one DataStore key per player. Loads on join (with retries and a simple session lock so two servers
-- never write the same player at once), autosaves, saves on leave and on shutdown. If the DataStore can't
-- be reached (e.g. Studio with API access off) the player gets an in-memory profile that is never saved,
-- and the client is told so. Game-pass ownership is not stored here: Roblox is asked (CosmeticsService).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local SettingsConfig = require(ReplicatedStorage.Shared.Config.Settings)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

type Record = { profile: Types.Profile, lockId: string?, lockAt: number? }
type Entry = { profile: Types.Profile, saving: boolean, dirty: boolean }

local DataService = {}

-- Fires (player, profile) once a player's data is ready (loaded or in-memory).
DataService.loaded = Signal.new() :: Signal.Signal<Player, Types.Profile>

local store: DataStore? = nil
local entries: { [Player]: Entry } = {}
local stateRemote: RemoteEvent
local sessionId = HttpService:GenerateGUID(false)

local function defaultProfile(): Types.Profile
	return {
		version = Progression.SchemaVersion,
		settings = {},
		wormSkin = nil,
		stats = {},
	}
end

-- Fills anything missing (older saves, new fields) without touching what's there.
local function reconcile(data: any): Types.Profile
	local profile = defaultProfile()
	if typeof(data) ~= "table" then
		return profile
	end
	profile.wormSkin = if typeof(data.wormSkin) == "string" then data.wormSkin else nil
	for _, key in { "settings", "stats" } do
		if typeof(data[key]) == "table" then
			(profile :: any)[key] = data[key]
		end
	end
	return profile
end

-- Only known settings, of the right type, clamped to their ranges (Config/Settings).
local function cleanSettings(raw: any): { [string]: any }
	local clean = {}
	if typeof(raw) ~= "table" then
		return clean
	end
	for name, default in SettingsConfig.Defaults do
		local value = raw[name]
		if typeof(value) == typeof(default) and (typeof(value) ~= "number" or value == value) then
			if name == "CameraSensitivity" then
				value = math.clamp(value, SettingsConfig.CameraSensitivityMin, SettingsConfig.CameraSensitivityMax)
			elseif typeof(value) == "number" then
				value = math.clamp(value, 0, 1)
			end
			clean[name] = value
		end
	end
	return clean
end

local function key(player: Player): string
	return `{Progression.KeyPrefix}{player.UserId}`
end

local function publish(player: Player)
	local entry = entries[player]
	if entry then
		stateRemote:FireClient(player, {
			settings = entry.profile.settings,
			stats = entry.profile.stats,
			saving = entry.saving,
		})
	end
end

-- Claims the player's record for this server and returns their profile, or nil if the store failed.
local function load(player: Player): Types.Profile?
	local dataStore = store
	if not dataStore then
		return nil
	end
	local delay = Progression.RetryBaseSeconds
	local lockWaits = 0
	for _ = 1, Progression.LoadRetries + Progression.LockWaitTries do
		local lockedElsewhere = false
		local ok, result = pcall(function()
			return dataStore:UpdateAsync(key(player), function(old: any)
				local record = if typeof(old) == "table" then old :: Record else nil
				local now = os.time()
				if
					record
					and record.lockId
					and record.lockId ~= sessionId
					and now - (record.lockAt or 0) < Progression.LockSeconds
					and lockWaits < Progression.LockWaitTries
				then
					lockedElsewhere = true
					return nil -- leave it alone; try again shortly
				end
				return { profile = reconcile(record and record.profile), lockId = sessionId, lockAt = now }
			end)
		end)
		if ok and not lockedElsewhere and typeof(result) == "table" then
			return reconcile(result.profile)
		elseif lockedElsewhere then
			lockWaits += 1
			task.wait(Progression.LockWaitSeconds)
		elseif
			string.find(tostring(result), "StudioAccessToApisNotAllowed", 1, true)
			or string.find(tostring(result), "API access is not enabled", 1, true)
		then
			-- Studio with "Enable Studio Access to API Services" off: retrying can't help.
			warn("[DataService] Studio has no DataStore access (Game Settings > Security); data won't be saved")
			store = nil
			return nil
		else
			warn(`[DataService] Load failed for {player.Name}: {result}`)
			task.wait(delay)
			delay *= 2
		end
		if player.Parent == nil then
			return nil
		end
	end
	return nil
end

local function save(player: Player, release: boolean)
	local entry = entries[player]
	local dataStore = store
	if not entry or not entry.saving or not dataStore then
		return
	end
	local profile = entry.profile
	local ok, err = pcall(function()
		dataStore:UpdateAsync(key(player), function(old: any)
			local record = if typeof(old) == "table" then old :: Record else nil
			-- Someone else took the data over (we were considered dead): don't clobber their copy.
			if record and record.lockId and record.lockId ~= sessionId then
				return nil
			end
			return {
				profile = profile,
				lockId = if release then nil else sessionId,
				lockAt = if release then nil else os.time(),
			}
		end)
	end)
	if ok then
		entry.dirty = false
	else
		warn(`[DataService] Save failed for {player.Name}: {err}`)
	end
end

local function onPlayerAdded(player: Player)
	local profile = load(player)
	if player.Parent == nil then
		return
	end
	local saving = profile ~= nil
	if not profile then
		warn(`[DataService] Using a temporary profile for {player.Name}; nothing will be saved this session`)
	end
	local ready = profile or defaultProfile()
	entries[player] = { profile = ready, saving = saving, dirty = false }
	publish(player)
	DataService.loaded:fire(player, ready)
end

local function onPlayerRemoving(player: Player)
	save(player, true)
	entries[player] = nil
end

-- API ---------------------------------------------------------------------------------------------

function DataService.get(player: Player): Types.Profile?
	local entry = entries[player]
	return entry and entry.profile
end

-- Any change to a profile goes through here so it gets published and saved.
function DataService.update(player: Player, change: (profile: Types.Profile) -> ())
	local entry = entries[player]
	if not entry then
		return
	end
	change(entry.profile)
	entry.dirty = true
	publish(player)
end

-- Remembers the worm skin the player picked (CosmeticsService checks they may use it).
function DataService.setWormSkin(player: Player, skinId: string)
	DataService.update(player, function(profile)
		profile.wormSkin = skinId
	end)
end

-- Lifetime stats: Played, PardnerRounds, WormRounds, Escapes, PardnerDeaths, WormWins.
function DataService.addStats(player: Player, deltas: { [string]: number })
	DataService.update(player, function(profile)
		for stat, amount in deltas do
			profile.stats[stat] = (profile.stats[stat] or 0) + amount
		end
	end)
end

function DataService.init()
	stateRemote = Net.event("State_Profile")
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Progression.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn(`[DataService] DataStores unavailable ({result}); player data won't be saved`)
	end
end

function DataService.start()
	-- The Settings window sends its values (debounced) whenever one changes.
	Net.onRequest("Request_SaveSettings", function(player: Player, raw: any)
		local clean = cleanSettings(raw)
		DataService.update(player, function(profile)
			profile.settings = clean
		end)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Progression.AutosaveSeconds)
			for player, entry in entries do
				if entry.dirty then
					task.spawn(save, player, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in entries do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
