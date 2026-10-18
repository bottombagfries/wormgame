--!strict
-- Phase 13: turns Fx_Notify into toasts. With a kind ("Kill", "Objective", "Sundown", ...) it's an event
-- toast for everyone; without one it's a personal hint above the inventory. Other controllers can show
-- local hints through ToastController.hint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UiSound = require(script.Parent.UI.Components.UiSound)
local Toasts = require(script.Parent.UI.Toasts)

local ToastController = {}

local screen: Toasts.Screen

local SOUNDS: { [string]: string } = {
	Kill = Theme.Sounds.Kill,
	Objective = Theme.Sounds.Objective,
}

function ToastController.hint(text: string)
	screen.hint(text)
end

function ToastController.push(text: string, kind: Types.ToastKind)
	screen.push(text, kind)
	local sound = SOUNDS[kind]
	if sound then
		UiSound.play(sound)
	end
end

function ToastController.init()
	screen = Toasts.create(Players.LocalPlayer:WaitForChild("PlayerGui"))
end

function ToastController.start()
	local function layout()
		local camera = Workspace.CurrentCamera
		screen.setCompact(camera ~= nil and camera.ViewportSize.X < Theme.Sizes.CompactWidth)
	end
	layout()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	end
	Net.event("Fx_Notify").OnClientEvent:Connect(function(text: string, kind: Types.ToastKind?)
		if typeof(text) ~= "string" then
			return
		end
		if kind then
			ToastController.push(text, kind)
		else
			ToastController.hint(text)
		end
	end)
end

return ToastController
