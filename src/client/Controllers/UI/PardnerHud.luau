--!strict
-- The Pardner HUD (§14, restyled in Phase 13): a vitals card bottom-left (health / stamina with the locked
-- part / grip), the aim crosshair, and a compass chip at top-center while aiming. On narrow screens the
-- vitals sit above the inventory row instead of beside it. Layout only; HUDController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Bar = require(script.Parent.Components.Bar)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Hud = {
	gui: ScreenGui,
	setHealth: (value: number, max: number) -> (),
	setStamina: (value: number, cap: number, max: number) -> (),
	setGrip: (value: number, max: number) -> (),
	setAiming: (aiming: boolean) -> (),
	setHeading: (text: string) -> (),
	setCompact: (compact: boolean) -> (),
}

local LOW_HEALTH = 0.25 -- the health bar pulses when it drops below this share
local WIDE_POSITION = UDim2.fromScale(0.015, 0.975)
local COMPACT_POSITION = UDim2.fromScale(0.015, 0.84)

local PardnerHud = {}

function PardnerHud.create(parent: Instance): Hud
	local colors = Theme.Colors
	local gui = Style.screen("PardnerHud", 2)

	local root = Instance.new("Frame")
	root.Name = "Vitals"
	root.AnchorPoint = Vector2.new(0, 1)
	root.Position = WIDE_POSITION
	root.Size = UDim2.fromScale(0.24, 0.15)
	root.ZIndex = 2
	root.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(200, 90)
	limits.MaxSize = Vector2.new(380, 150)
	limits.Parent = root
	local body = Style.shadowed(root, Theme.Corner.Panel)
	body.BackgroundColor3 = colors.Wood
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, colors.WoodDark, Theme.Stroke.Panel)
	Style.padding(body, Theme.Padding.Button)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.06, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = body

	local barSize = UDim2.fromScale(1, 0.28)
	local health = Bar.new(body, { label = "Health", color = colors.Health, size = barSize, order = 1 })
	local stamina = Bar.new(body, { label = "Stamina", color = colors.Stamina, size = barSize, order = 2 })
	local grip = Bar.new(body, { label = "Grip", color = colors.Grip, size = barSize, order = 3 })

	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(10, 10)
	crosshair.BackgroundTransparency = 1
	crosshair.Visible = false
	crosshair.Parent = gui
	Style.corner(crosshair, Theme.Corner.Pill)
	Style.stroke(crosshair, colors.PaperLight, 2)

	local compass = Instance.new("Frame")
	compass.Name = "Compass"
	compass.AnchorPoint = Vector2.new(0.5, 0)
	compass.Position = UDim2.fromScale(0.5, 0.1)
	compass.Size = UDim2.fromScale(0.07, 0.05)
	compass.BackgroundColor3 = colors.WoodDark
	compass.Visible = false
	compass.Parent = gui
	local compassLimits = Instance.new("UISizeConstraint")
	compassLimits.MinSize = Vector2.new(64, 32)
	compassLimits.Parent = compass
	Style.corner(compass, Theme.Corner.Pill)
	Style.stroke(compass, colors.Accent, Theme.Stroke.Button)
	local heading = Label.new(compass, {
		font = Theme.Fonts.Heading,
		color = colors.Accent,
		size = UDim2.fromScale(0.8, 0.75),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 24,
	})

	gui.Parent = parent

	local lastHealthShare = 1
	return {
		gui = gui,
		setHealth = function(value: number, max: number)
			health.set(value, max)
			local share = if max > 0 then value / max else 0
			if share < LOW_HEALTH and share < lastHealthShare then
				health.pulse()
			end
			lastHealthShare = share
		end,
		setStamina = function(value: number, cap: number, max: number)
			stamina.set(value, max, cap)
		end,
		setGrip = function(value: number, max: number)
			grip.set(value, max)
		end,
		setAiming = function(aiming: boolean)
			crosshair.Visible = aiming
			compass.Visible = aiming
		end,
		setHeading = function(text: string)
			heading.Text = text
		end,
		setCompact = function(compact: boolean)
			root.Position = if compact then COMPACT_POSITION else WIDE_POSITION
		end,
	}
end

return PardnerHud
