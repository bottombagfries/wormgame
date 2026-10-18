--!strict
-- Client view of the match (§5.1): keeps the latest State_Match, knows the local player's role, and
-- drives the role card, loadout and end screens (the lobby HUD is LobbyController). Other controllers ask this for phase and role.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local LobbyConfig = require(ReplicatedStorage.Shared.Config.Lobby)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ResultsScreen = require(script.Parent.UI.ResultsScreen)
local LoadoutScreen = require(script.Parent.UI.LoadoutScreen)
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

local loadout: LoadoutScreen.Screen
local endScreen: ResultsScreen.Screen
local roleCard: RoleCard.Screen

local function secondsLeft(): number
	local endsAt = state.endsAt
	return if endsAt then math.max(0, math.ceil(endsAt - Workspace:GetServerTimeNow())) else 0
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
			endScreen.show(result, personalOutcome(result), newState.endsAt)
		else
			endScreen.hide()
		end
	end
	changed:fire(newState)
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
	loadout = LoadoutScreen.create(playerGui, function(ids: { string })
		Net.event("Request_SelectAbilities"):FireServer(ids)
	end)
	endScreen = ResultsScreen.create(playerGui)
	roleCard = RoleCard.create(playerGui)
end

function MatchController.start()
	Net.event("State_Match").OnClientEvent:Connect(onState)
	RunService.RenderStepped:Connect(updateRoleScreens)
end

return MatchController
