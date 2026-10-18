--!strict
-- The ghost HUD (§8.4, restyled in Phase 13): a pale card at bottom-center with the controls, the push
-- cooldown line and the charge bar. Layout only; GhostController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Bar = require(script.Parent.Components.Bar)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Hud = {
	gui: ScreenGui,
	setStatus: (text: string) -> (),
	setCharge: (fraction: number) -> (), -- 0 hides the bar
}

local CONTROLS = "You are a ghost · WASD fly · Space up · Shift down · hold E on an item to push it"

local GhostHud = {}

function GhostHud.create(parent: Instance): Hud
	local colors = Theme.Colors
	local gui = Style.screen("GhostHud", 2)
	gui.Enabled = false

	local root = Instance.new("Frame")
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.fromScale(0.5, 0.975)
	root.Size = UDim2.fromScale(0.46, 0.13)
	root.ZIndex = 2
	root.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(300, 84)
	limits.MaxSize = Vector2.new(640, 130)
	limits.Parent = root
	local body = Style.shadowed(root, Theme.Corner.Panel)
	body.BackgroundColor3 = colors.GhostRole
	body.BackgroundTransparency = 0.15
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, colors.PardnerDark, Theme.Stroke.Panel)
	Style.padding(body, Theme.Padding.Button)

	local controls = Label.new(body, {
		text = CONTROLS,
		font = Theme.Fonts.BodyBold,
		color = colors.PardnerDark,
		size = UDim2.fromScale(1, 0.34),
		maxTextSize = 18,
	})
	controls.TextWrapped = true
	controls.ZIndex = 4
	local status = Label.new(body, {
		font = Theme.Fonts.Heading,
		color = colors.Ink,
		size = UDim2.fromScale(1, 0.3),
		position = UDim2.fromScale(0, 0.36),
		maxTextSize = 20,
	})
	status.ZIndex = 4
	local charge = Bar.new(body, {
		label = "Push",
		color = colors.Pardner,
		size = UDim2.fromScale(1, 0.26),
		position = UDim2.fromScale(0, 0.72),
	})
	charge.frame.Visible = false

	gui.Parent = parent

	return {
		gui = gui,
		setStatus = function(text: string)
			status.Text = text
		end,
		setCharge = function(fraction: number)
			charge.frame.Visible = fraction > 0
			charge.set(math.clamp(fraction, 0, 1) * 100, 100)
		end,
	}
end

return GhostHud
