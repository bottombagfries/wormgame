--!strict
-- The throw power meter (§6.2 throwing): a slim vertical gauge just right of the crosshair while aiming
-- with something in hand. Its fill sweeps up and down; it turns the "great throw" color near the top.
-- Layout only; InventoryController feeds it the level.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Meter = {
	gui: ScreenGui,
	setVisible: (visible: boolean) -> (),
	set: (power: number) -> (), -- ThrowMeter.MinPower..1
	pulse: () -> (), -- a quick pop when a throw goes out
}

local GAUGE_SIZE = UDim2.fromScale(0.022, 0.24)
local GAUGE_POSITION = UDim2.fromScale(0.57, 0.5)
local GAUGE_ASPECT = 0.12 -- width / height

local ThrowMeter = {}

function ThrowMeter.create(parent: Instance): Meter
	local colors = Theme.Colors
	local gui = Style.screen("ThrowMeter", 3)
	gui.Enabled = false
	gui.Parent = parent

	local gauge = Instance.new("Frame")
	gauge.Name = "Gauge"
	gauge.AnchorPoint = Vector2.new(0, 0.5)
	gauge.Position = GAUGE_POSITION
	gauge.Size = GAUGE_SIZE
	gauge.BackgroundColor3 = colors.Track
	gauge.BackgroundTransparency = 0.15
	gauge.Parent = gui
	Style.aspect(gauge, GAUGE_ASPECT)
	Style.corner(gauge, Theme.Corner.Bar)
	Style.stroke(gauge, colors.WoodDark, Theme.Stroke.Bar)
	local scale = Style.scaler(gauge)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 0)
	fill.BackgroundColor3 = colors.Accent
	fill.Parent = gauge
	Style.corner(fill, Theme.Corner.Bar)

	-- A tick where the "great throw" zone starts.
	local tick = Instance.new("Frame")
	tick.Name = "SweetSpot"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 1 - PardnerConfig.ThrowMeter.SweetSpot)
	tick.Size = UDim2.new(1.6, 0, 0, 2)
	tick.BackgroundColor3 = colors.TextLight
	tick.BorderSizePixel = 0
	tick.Parent = gauge

	local caption = Label.new(gauge, {
		text = "POWER",
		font = Theme.Fonts.Heading,
		color = colors.TextLight,
		size = UDim2.new(6, 0, 0, 18),
		position = UDim2.new(0.5, 0, 1, 6),
		maxTextSize = 16,
	})
	caption.AnchorPoint = Vector2.new(0.5, 0)

	return {
		gui = gui,
		setVisible = function(visible: boolean)
			gui.Enabled = visible
		end,
		set = function(power: number)
			local minPower = PardnerConfig.ThrowMeter.MinPower
			local level = math.clamp((power - minPower) / (1 - minPower), 0, 1)
			fill.Size = UDim2.fromScale(1, level)
			fill.BackgroundColor3 = if power >= PardnerConfig.ThrowMeter.SweetSpot then colors.Good else colors.Accent
		end,
		pulse = function()
			scale.Scale = 1.25
			Style.tween(scale, Theme.Tween.Pop, { Scale = 1 })
		end,
	}
end

return ThrowMeter
