--!strict
-- Client view of the match (§5.1): keeps the latest State_Match, knows the local player's role, and
-- drives the lobby, role/loadout and end screens. Other controllers ask this for phase and role.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local EndScreen = require(script.Parent.UI.EndScreen)
local LoadoutScreen = require(script.Parent.UI.LoadoutScreen)
local LobbyScreen = require(script.Parent.UI.LobbyScreen)

local PARDNER_COLOR = Color3.fromRGB(120, 220, 120)
local WORM_COLOR = Color3.fromRGB(230, 90, 80)
local NEUTRAL_COLOR = Color3.new(1, 1, 1)

local MatchController = {}

local changed: Signal.Signal<Types.MatchState> = Signal.new()
MatchController.changed = changed

local player = Players.LocalPlayer

local state: Types.MatchState = {
	phase = "Lobby",
	night = false,
	difficulty = GameConfig.DefaultDifficulty,
	hostUserId = 0,
	playerCount = 0,
	readyCount = 0,
	minPlayers = GameConfig.MinPlayers,
}

local lobby: LobbyScreen.Screen
local loadout: LoadoutScreen.Screen
local endScreen: EndScreen.Screen

local function secondsLeft(): number
	local endsAt = state.endsAt
	return if endsAt then math.max(0, math.ceil(endsAt - Workspace:GetServerTimeNow())) else 0
end

local function updateLobby()
	local subtitle
	if state.playerCount < state.minPlayers then
		subtitle = `Waiting for players ({state.playerCount}/{state.minPlayers})`
	else
		subtitle = `Match starts in {secondsLeft()}s   ({state.readyCount}/{state.playerCount} ready)`
	end
	lobby.setText("LOBBY", subtitle)
	lobby.setReady(player:GetAttribute("Ready") == true)
	lobby.setDifficulty(state.difficulty, state.hostUserId == player.UserId)
end

local function updateLoadout()
	local role = MatchController.getRole()
	local picking = state.phase == "WormLoadout"

	local headline, color = "SPECTATING", NEUTRAL_COLOR
	if role == "Worm" then
		headline, color = "YOU ARE THE WORM", WORM_COLOR
	elseif role == "Pardner" then
		headline, color = "YOU ARE A PARDNER", PARDNER_COLOR
	end

	local subtitle = ""
	if picking and role == "Worm" then
		subtitle = `Pick {GameConfig.WormAbilityPicks} abilities   ({secondsLeft()}s)`
	elseif picking then
		subtitle = `The Worm is choosing abilities...   ({secondsLeft()}s)`
	elseif role == "Pardner" then
		subtitle = "Fuel the Train and escape"
	elseif role == "Worm" then
		subtitle = "Don't let them leave"
	end
	loadout.show(headline, color, subtitle, picking and role == "Worm")
end

local function update()
	local phase = state.phase
	lobby.setVisible(phase == "Lobby")
	if phase == "Lobby" then
		updateLobby()
	end
	if phase == "RoleAssign" or phase == "WormLoadout" then
		updateLoadout()
	else
		loadout.hide()
	end
end

-- The end screen's line about the local player.
local function personalOutcome(result: Types.MatchResult): string
	local role = player:GetAttribute("Role")
	if role == "Worm" then
		return if result.winner == "Worm" then "Nobody got away. You win!" else "They got away."
	elseif role == "Pardner" then
		local escaped = table.find(result.escaped, player.DisplayName) ~= nil
		return if escaped then "You escaped!" else "You were left behind."
	end
	return ""
end

local function onState(newState: Types.MatchState)
	local previous = state.phase
	state = newState

	if newState.phase ~= previous then
		if newState.phase == "RoleAssign" then
			loadout.resetPicks()
		end
		local result = newState.result
		if newState.phase == "Ending" and result then
			endScreen.show(result, personalOutcome(result))
		else
			endScreen.hide()
		end
	end
	changed:fire(newState)
end

local function cycleDifficulty()
	if state.hostUserId ~= player.UserId then
		return
	end
	local order = GameConfig.DifficultyOrder
	local index = table.find(order, state.difficulty) or 0
	Net.event("Request_SetDifficulty"):FireServer(order[index % #order + 1])
end

function MatchController.getState(): Types.MatchState
	return state
end

-- "Pardner", "Worm" or "None".
function MatchController.getRole(): string
	local role = player:GetAttribute("Role")
	return if typeof(role) == "string" then role else "None"
end

-- A living Pardner (dead ones are ghosts).
function MatchController.isPardner(): boolean
	return MatchController.getRole() == "Pardner" and player:GetAttribute("Dead") ~= true
end

-- A dead Pardner, flying around as a ghost.
function MatchController.isGhost(): boolean
	return MatchController.getRole() == "Pardner" and player:GetAttribute("Dead") == true
end

function MatchController.init()
	local playerGui = player:WaitForChild("PlayerGui")
	lobby = LobbyScreen.create(playerGui, {
		onReady = function()
			Net.event("Request_Ready"):FireServer(player:GetAttribute("Ready") ~= true)
		end,
		onDifficulty = cycleDifficulty,
	})
	loadout = LoadoutScreen.create(playerGui, function(ids: { string })
		Net.event("Request_SelectAbilities"):FireServer(ids)
	end)
	endScreen = EndScreen.create(playerGui)
end

function MatchController.start()
	Net.event("State_Match").OnClientEvent:Connect(onState)
	RunService.RenderStepped:Connect(update)
end

return MatchController
