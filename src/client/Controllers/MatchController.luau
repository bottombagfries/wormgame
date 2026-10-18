--!strict
-- Client view of the match (§5.1): keeps the latest State_Match, knows the local player's role, and
-- drives the lobby, role/loadout and end screens. Other controllers ask this for phase and role.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local LobbyConfig = require(ReplicatedStorage.Shared.Config.Lobby)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local EndScreen = require(script.Parent.UI.EndScreen)
local LoadoutScreen = require(script.Parent.UI.LoadoutScreen)
local LobbyScreen = require(script.Parent.UI.LobbyScreen)
local RoleCard = require(script.Parent.UI.RoleCard)

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
	activeCount = 0,
	minPlayers = LobbyConfig.MinPlayers,
}

local lobby: LobbyScreen.Screen
local loadout: LoadoutScreen.Screen
local endScreen: EndScreen.Screen
local roleCard: RoleCard.Screen

local function secondsLeft(): number
	local endsAt = state.endsAt
	return if endsAt then math.max(0, math.ceil(endsAt - Workspace:GetServerTimeNow())) else 0
end

local function updateLobby()
	local subtitle
	if state.phase == "Lobby" then
		subtitle = `Waiting for players ({state.activeCount}/{state.minPlayers})`
	elseif state.phase == "Intermission" then
		subtitle = `Next round in {secondsLeft()}s`
	else
		subtitle = "Round in progress - you'll play the next one"
	end
	lobby.setText("LOBBY", subtitle)
	lobby.setDifficulty(state.difficulty, state.hostUserId == player.UserId)
end

-- RoleAssign: the full-screen role card. WormLoadout: the Worm picks; everyone else sees a waiting strip.
local function updateRoleScreens()
	local role = MatchController.getRole()
	local phase = state.phase
	if phase == "RoleAssign" and role ~= "None" then
		roleCard.show(role)
	else
		roleCard.hide()
	end

	if phase == "WormLoadout" and role == "Worm" then
		loadout.showPicker(secondsLeft(), GameConfig.WormLoadoutSeconds)
	elseif phase == "WormLoadout" and role ~= "None" then
		loadout.showWaiting(`The Worm is choosing abilities...  {secondsLeft()}s`)
	else
		loadout.hide()
	end
end

local function update()
	local phase = state.phase
	-- Anyone not in the round (late joiners, AFK) sees the lobby panel the whole time.
	local inLobby = phase == "Lobby" or phase == "Intermission" or MatchController.getRole() == "None"
	lobby.setVisible(inLobby and phase ~= "Ending")
	if inLobby then
		updateLobby()
	end
	updateRoleScreens()
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
		onDifficulty = cycleDifficulty,
	})
	loadout = LoadoutScreen.create(playerGui, function(ids: { string })
		Net.event("Request_SelectAbilities"):FireServer(ids)
	end)
	endScreen = EndScreen.create(playerGui)
	roleCard = RoleCard.create(playerGui)
end

function MatchController.start()
	Net.event("State_Match").OnClientEvent:Connect(onState)
	RunService.RenderStepped:Connect(update)
end

return MatchController
