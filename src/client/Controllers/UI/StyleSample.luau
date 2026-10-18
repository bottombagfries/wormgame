--!strict
-- Phase 13 step 1: a sample screen showing every shared component in the theme, for style review.
-- Shown when Config.Game.Debug.ShowUiSample is on (HUDController builds it).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Bar = require(script.Parent.Components.Bar)
local Button = require(script.Parent.Components.Button)
local Label = require(script.Parent.Components.Label)
local Panel = require(script.Parent.Components.Panel)
local Slot = require(script.Parent.Components.Slot)
local Style = require(script.Parent.Components.Style)

local StyleSample = {}

local function list(parent: Instance, horizontal: boolean): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.Padding = Theme.Padding.Gap
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = parent
	return layout
end

local function row(parent: Instance, height: number, order: number): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, height)
	frame.LayoutOrder = order
	frame.Parent = parent
	return frame
end

function StyleSample.create(parent: Instance): ScreenGui
	local gui = Style.screen("StyleSample", 50)

	local panel = Panel.new(gui, {
		name = "SamplePanel",
		title = "STYLE CHECK",
		size = UDim2.fromScale(0.4, 0.9),
		position = UDim2.fromScale(0.5, 0.5),
	})
	Style.aspect(panel.frame, 0.72)
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(340, 0)
	limits.Parent = panel.frame
	list(panel.content, false)

	Label.new(panel.content, {
		text = "Paper on wood, wanted-poster headings, brass accent.",
		size = UDim2.fromScale(1, 0.06),
		order = 1,
		maxTextSize = 22,
	})

	local specs = { { "PLAY", "Accent" }, { "SETTINGS", "Paper" }, { "LEAVE", "Danger" }, { "LOCKED", "Accent" } }
	for rowIndex = 0, 1 do
		local buttons = row(panel.content, 0.11, 2 + rowIndex)
		list(buttons, true)
		for column = 1, 2 do
			local spec = specs[rowIndex * 2 + column]
			local button = Button.new(buttons, {
				text = spec[1],
				variant = spec[2] :: any,
				size = UDim2.fromScale(0.46, 1),
				order = column,
			})
			if spec[1] == "LOCKED" then
				button.setEnabled(false)
			end
		end
	end

	local bars = row(panel.content, 0.3, 4)
	list(bars, false)
	local health =
		Bar.new(bars, { label = "Health", color = Theme.Colors.Health, size = UDim2.fromScale(0.9, 0.28), order = 1 })
	local stamina =
		Bar.new(bars, { label = "Stamina", color = Theme.Colors.Stamina, size = UDim2.fromScale(0.9, 0.28), order = 2 })
	local fuel =
		Bar.new(bars, { label = "Fuel", color = Theme.Colors.Fuel, size = UDim2.fromScale(0.9, 0.28), order = 3 })
	health.set(100, 100)
	stamina.set(70, 100, 80)
	fuel.set(45, 100)
	task.delay(0.6, function()
		health.set(62, 100) -- shows the ghost fill trailing behind
	end)

	local slots = row(panel.content, 0.17, 5)
	list(slots, true)
	local names = { "Small Coal", "Lantern", nil, "Shovel" }
	for index = 1, 4 do
		local slot = Slot.new(
			slots,
			{ key = if index == 4 then "T" else tostring(index), size = UDim2.fromScale(1, 1), order = index }
		)
		slot.setItem(names[index])
		slot.setSelected(index == 2)
		if index == 4 then
			slot.setCooldown(6, 10)
		end
	end

	local roles = row(panel.content, 0.1, 6)
	list(roles, true)
	for index, spec in { { "THE WORM", Theme.Colors.Worm }, { "PARDNER", Theme.Colors.Pardner } } do
		local chip = Instance.new("Frame")
		chip.Size = UDim2.fromScale(0.4, 1)
		chip.BackgroundColor3 = spec[2]
		chip.LayoutOrder = index
		chip.ZIndex = 3
		Style.corner(chip, Theme.Corner.Button)
		Style.stroke(chip, Theme.Colors.WoodDark, Theme.Stroke.Button)
		chip.Parent = roles
		local text = Label.new(chip, {
			text = spec[1],
			font = Theme.Fonts.Display,
			color = Theme.Colors.TextLight,
			size = UDim2.fromScale(0.9, 0.7),
			position = UDim2.fromScale(0.5, 0.5),
			anchor = Vector2.new(0.5, 0.5),
			outline = true,
		})
		text.ZIndex = 4
	end

	gui.Parent = parent
	panel.popIn()
	return gui
end

return StyleSample
