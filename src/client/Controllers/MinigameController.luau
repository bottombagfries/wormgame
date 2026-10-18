--!strict
-- The mouth-escape minigame on the grabbed Pardner's client (§8.3). The server owns the sequence
-- and the progress; this shows them and sends each arrow press as an intent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local InputController = require(script.Parent.InputController)
local MinigameHud = require(script.Parent.UI.MinigameHud)

-- Keybind action -> the arrow name the server expects.
local ACTION_ARROWS: { [string]: string } = {
	ArrowUp = "Up",
	ArrowDown = "Down",
	ArrowLeft = "Left",
	ArrowRight = "Right",
}
local AUTO_ACTION = "AutoEscape"
local AUTO_INPUT = "Auto"

local MinigameController = {}

local state: Types.MinigameState = { active = false, sequence = {}, progress = 0, checkpoint = 0, auto = false }
local hud: MinigameHud.Hud
local inputRemote: RemoteEvent

local function onState(newState: Types.MinigameState)
	if newState.active and state.active and newState.progress < state.progress then
		hud.flashWrong()
	end
	state = newState

	hud.setVisible(state.active)
	if state.active then
		hud.setArrow(if state.auto then nil else state.sequence[state.progress + 1])
		hud.setProgress(state.progress, state.checkpoint, #state.sequence)
	end
end

local function update()
	if not state.active then
		return
	end
	local autoEndsAt = state.autoEndsAt
	if state.auto and autoEndsAt then
		local left = math.max(0, autoEndsAt - Workspace:GetServerTimeNow())
		hud.setHint(string.format("Auto-escaping... %.1fs   (G to cancel)", left))
	else
		hud.setHint("G: auto-escape (slower, but no arrows)")
	end
end

local function onAction(action: string)
	if not state.active then
		return
	end
	if action == AUTO_ACTION then
		inputRemote:FireServer(AUTO_INPUT)
		return
	end
	local arrow = ACTION_ARROWS[action]
	if arrow and not state.auto then
		inputRemote:FireServer(arrow)
	end
end

function MinigameController.isActive(): boolean
	return state.active
end

function MinigameController.init()
	inputRemote = Net.event("Request_MinigameInput")
	hud = MinigameHud.create(Players.LocalPlayer:WaitForChild("PlayerGui"))
end

function MinigameController.start()
	Net.event("State_Minigame").OnClientEvent:Connect(onState)
	InputController.actionPressed:connect(onAction)
	RunService.RenderStepped:Connect(update)
end

return MinigameController
