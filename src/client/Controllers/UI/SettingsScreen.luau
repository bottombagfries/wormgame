--!strict
-- Phase 13 Settings window: music and SFX volume, camera sensitivity, and the Worm's first-person mouth
-- view. Changes go straight to SettingsController (kept for the session).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsConfig = require(ReplicatedStorage.Shared.Config.Settings)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Button = require(script.Parent.Components.Button)
local Label = require(script.Parent.Components.Label)
local Modal = require(script.Parent.Components.Modal)
local Slider = require(script.Parent.Components.Slider)

type Values = { [string]: any }

local SettingsScreen = {}

local function percent(value: number): string
	return `{math.round(value * 100)}%`
end

function SettingsScreen.create(parent: Instance, values: Values, set: (key: string, value: any) -> ()): Modal.Modal
	local modal = Modal.new(parent, {
		name = "SettingsScreen",
		title = "SETTINGS",
		size = UDim2.fromScale(0.5, 0.62),
		aspect = 1.25,
		minWidth = 340,
	})
	local list = Instance.new("UIListLayout")
	list.Padding = Theme.Padding.Gap
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = modal.content

	local step = SettingsConfig.SliderStep
	Slider.new(modal.content, {
		caption = "Music",
		min = 0,
		max = 1,
		step = step,
		value = values.MusicVolume,
		format = percent,
		order = 1,
		onChanged = function(value)
			set("MusicVolume", value)
		end,
	})
	Slider.new(modal.content, {
		caption = "Sound effects",
		min = 0,
		max = 1,
		step = step,
		value = values.SfxVolume,
		format = percent,
		order = 2,
		onChanged = function(value)
			set("SfxVolume", value)
		end,
	})
	Slider.new(modal.content, {
		caption = "Camera speed",
		min = SettingsConfig.CameraSensitivityMin,
		max = SettingsConfig.CameraSensitivityMax,
		step = step,
		value = values.CameraSensitivity,
		format = function(value)
			return string.format("%.2fx", value)
		end,
		order = 3,
		onChanged = function(value)
			set("CameraSensitivity", value)
		end,
	})

	-- Mouth view toggle
	local row = Instance.new("Frame")
	row.Name = "MouthView"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 0.18)
	row.LayoutOrder = 4
	row.ZIndex = 3
	row.Parent = modal.content
	Label.new(row, {
		text = "Worm mouth view (first person)",
		font = Theme.Fonts.Heading,
		size = UDim2.fromScale(0.62, 0.7),
		position = UDim2.fromScale(0, 0.15),
		align = Enum.TextXAlignment.Left,
		maxTextSize = 22,
	}).ZIndex =
		4
	local toggle: Button.Button
	local function paint()
		local on = values.WormMouthView == true
		toggle.setText(if on then "ON" else "OFF")
		toggle.setVariant(if on then "Good" else "Paper")
	end
	toggle = Button.new(row, {
		text = "",
		size = UDim2.fromScale(0.3, 0.9),
		position = UDim2.fromScale(1, 0.5),
		anchor = Vector2.new(1, 0.5),
		onClick = function()
			set("WormMouthView", not values.WormMouthView)
			paint()
		end,
	})
	paint()

	Label.new(modal.content, {
		text = "Settings last until you leave the server.",
		color = Theme.Colors.InkSoft,
		size = UDim2.fromScale(1, 0.08),
		order = 5,
		maxTextSize = 16,
	}).ZIndex =
		4

	return modal
end

return SettingsScreen
