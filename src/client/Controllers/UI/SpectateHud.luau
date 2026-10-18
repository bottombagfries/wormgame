--!strict
-- Phase 13 spectate bar (bottom-center): previous / next, who you're watching with a role chip, and Stop.
-- Layout only; SpectateController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Button = require(script.Parent.Components.Button)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Callbacks = {
	onPrevious: () -> (),
	onNext: () -> (),
	onStop: () -> (),
}

export type Hud = {
	gui: ScreenGui,
	setVisible: (visible: boolean) -> (),
	setTarget: (name: string, role: string?) -> (),
}

local SpectateHud = {}

function SpectateHud.create(parent: Instance, callbacks: Callbacks): Hud
	local colors = Theme.Colors
	local gui = Style.screen("SpectateHud", 6)
	gui.Enabled = false

	local root = Instance.new("Frame")
	root.Name = "Bar"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.fromScale(0.5, 0.96)
	root.Size = UDim2.fromScale(0.5, 0.12)
	root.ZIndex = 2
	root.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(330, 80)
	limits.Parent = root
	local body = Style.shadowed(root, Theme.Corner.Panel)
	body.BackgroundColor3 = colors.Paper
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, colors.WoodDark, Theme.Stroke.Panel)
	Style.padding(body, Theme.Padding.Button)

	Label.new(body, {
		text = "SPECTATING",
		font = Theme.Fonts.Heading,
		color = colors.InkSoft,
		size = UDim2.fromScale(0.5, 0.26),
		position = UDim2.fromScale(0.5, 0),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 16,
	}).ZIndex =
		4

	local name = Label.new(body, {
		name = "Target",
		font = Theme.Fonts.Heading,
		size = UDim2.fromScale(0.5, 0.38),
		position = UDim2.fromScale(0.5, 0.26),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 30,
	})
	name.ZIndex = 4

	local chip = Instance.new("Frame")
	chip.Name = "Role"
	chip.AnchorPoint = Vector2.new(0.5, 1)
	chip.Position = UDim2.fromScale(0.5, 1)
	chip.Size = UDim2.fromScale(0.28, 0.3)
	chip.ZIndex = 4
	Style.corner(chip, Theme.Corner.Pill)
	Style.stroke(chip, colors.WoodDark, Theme.Stroke.Button)
	chip.Parent = body
	local chipText = Label.new(chip, {
		font = Theme.Fonts.Display,
		color = colors.TextLight,
		size = UDim2.fromScale(0.9, 0.8),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 20,
		outline = true,
	})
	chipText.ZIndex = 5

	local side = UDim2.fromScale(0.16, 0.7)
	Button.new(body, {
		text = "<",
		variant = "Wood",
		size = side,
		position = UDim2.fromScale(0, 0.5),
		anchor = Vector2.new(0, 0.5),
		onClick = callbacks.onPrevious,
	})
	Button.new(body, {
		text = ">",
		variant = "Wood",
		size = side,
		position = UDim2.fromScale(1, 0.5),
		anchor = Vector2.new(1, 0.5),
		onClick = callbacks.onNext,
	})
	local stop = Button.new(gui, {
		text = "STOP",
		variant = "Danger",
		size = UDim2.fromScale(0.1, 0.05),
		position = UDim2.fromScale(0.5, 0.82),
		anchor = Vector2.new(0.5, 1),
		onClick = callbacks.onStop,
	})
	local stopLimits = stop.button:FindFirstChildOfClass("UISizeConstraint")
	if stopLimits then
		stopLimits.MinSize = Vector2.new(110, stopLimits.MinSize.Y)
	end

	gui.Parent = parent

	return {
		gui = gui,
		setVisible = function(visible: boolean)
			gui.Enabled = visible
		end,
		setTarget = function(text: string, role: string?)
			name.Text = text
			chip.Visible = role ~= nil
			if role then
				local worm = role == "Worm"
				chip.BackgroundColor3 = if worm then colors.Worm else colors.Pardner
				chipText.Text = if worm then "THE WORM" else "PARDNER"
			end
		end,
	}
end

return SpectateHud
