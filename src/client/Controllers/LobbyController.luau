--!strict
-- Phase 13 lobby HUD for anyone at the station (between rounds, or not in the current one): round status,
-- player count, your Worm chance, and the Shop / Cosmetics / Settings / Spectate / AFK buttons. AFK and
-- difficulty are requests; the server decides (MatchService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Net = require(ReplicatedStorage.Shared.Net)
local Label = require(script.Parent.UI.Components.Label)
local Modal = require(script.Parent.UI.Components.Modal)
local LobbyHud = require(script.Parent.UI.LobbyHud)
local MatchController = require(script.Parent.MatchController)
local SpectateController = require(script.Parent.SpectateController)

local URGENT_SECONDS = 5 -- the countdown turns brass and pops for the last few seconds

local LobbyController = {}

local player = Players.LocalPlayer

local hud: LobbyHud.Hud
local modals: { [string]: Modal.Modal } = {}

local function formatClock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function isAfk(): boolean
	return player:GetAttribute("Afk") == true
end

local function openOnly(name: string)
	for key, modal in modals do
		if key == name then
			modal.open()
		else
			modal.close()
		end
	end
end

local function cycleDifficulty()
	local state = MatchController.getState()
	if state.hostUserId ~= player.UserId then
		return
	end
	local order = GameConfig.DifficultyOrder
	local index = table.find(order, state.difficulty) or 0
	Net.event("Request_SetDifficulty"):FireServer(order[index % #order + 1])
end

local function update()
	local state = MatchController.getState()
	local phase = state.phase
	local inRound = MatchController.getRole() ~= "None"
	local visible = not inRound and phase ~= "Ending" and not SpectateController.isSpectating()
	hud.setVisible(visible)
	if not visible then
		return
	end

	local text, urgent = "", false
	if phase == "Lobby" then
		text = `Waiting for players  {state.activeCount}/{state.minPlayers}`
	elseif phase == "Intermission" then
		local left = (state.endsAt or 0) - Workspace:GetServerTimeNow()
		text = `Next round in {formatClock(left)}`
		urgent = left <= URGENT_SECONDS
	else
		text = "Round in progress - you're up next"
	end
	if isAfk() then
		text ..= "  (AFK)"
	end
	hud.setStatus(text, urgent)
	hud.setLastResult(if state.lastResult then `Last round: {state.lastResult}` else "")
	hud.setPlayers(state.activeCount, state.playerCount)
	local chance = player:GetAttribute("WormChance")
	hud.setWormChance(if typeof(chance) == "number" then chance else 0, isAfk())
	hud.setAfk(isAfk())
	hud.setSpectateEnabled(SpectateController.canSpectate())
	hud.setDifficulty(
		state.difficulty,
		state.hostUserId == player.UserId and (phase == "Lobby" or phase == "Intermission")
	)
end

-- A modal with a single line of text (screens that aren't built yet).
local function placeholder(parent: Instance, name: string, title: string, text: string): Modal.Modal
	local modal = Modal.new(parent, { name = name, title = title, size = UDim2.fromScale(0.42, 0.4), aspect = 1.4 })
	Label.new(modal.content, { text = text, maxTextSize = 26 }).TextWrapped = true
	return modal
end

-- Registers a lobby window (step 6 swaps the placeholders for real screens).
function LobbyController.setModal(name: string, modal: Modal.Modal)
	local old = modals[name]
	if old then
		old.gui:Destroy()
	end
	modals[name] = modal
end

function LobbyController.init()
	local playerGui = player:WaitForChild("PlayerGui")
	hud = LobbyHud.create(playerGui, {
		onShop = function()
			openOnly("Shop")
		end,
		onCosmetics = function()
			openOnly("Cosmetics")
		end,
		onSettings = function()
			openOnly("Settings")
		end,
		onSpectate = function()
			openOnly("")
			SpectateController.begin()
		end,
		onAfk = function()
			Net.event("Request_SetAfk"):FireServer(not isAfk())
		end,
		onDifficulty = cycleDifficulty,
	})
	modals.Cosmetics = placeholder(
		playerGui,
		"CosmeticsScreen",
		"COSMETICS",
		"Hats, trails and worm skins are on their way. Nothing here will ever change how the game plays."
	)
	modals.Shop = placeholder(playerGui, "ShopScreen", "SHOP", "The general store is closed for now.")
	modals.Settings = placeholder(playerGui, "SettingsScreen", "SETTINGS", "Settings are coming soon.")
end

function LobbyController.start()
	RunService.RenderStepped:Connect(update)
end

return LobbyController
