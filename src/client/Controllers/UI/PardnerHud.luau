--!strict
-- Builds the Pardner HUD screen: health / stamina / grip bars, aim crosshair, compass.
-- Layout only; HUDController feeds it values. TODO(asset): replace with real UI art.

export type Hud = {
	gui: ScreenGui,
	setHealth: (value: number, max: number) -> (),
	setStamina: (value: number, cap: number, max: number) -> (),
	setGrip: (value: number, max: number) -> (),
	setAiming: (aiming: boolean) -> (),
	setHeading: (text: string) -> (),
}

local BAR_SIZE = UDim2.fromOffset(260, 22)
local BAR_GAP = 6
local MARGIN = 20
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local HEALTH_COLOR = Color3.fromRGB(200, 60, 60)
local STAMINA_COLOR = Color3.fromRGB(90, 190, 90)
local GRIP_COLOR = Color3.fromRGB(230, 180, 60)
local LOCKED_COLOR = Color3.fromRGB(90, 30, 30)

local PardnerHud = {}

local function fraction(value: number, max: number): number
	return if max > 0 then math.clamp(value / max, 0, 1) else 0
end

local function makeBar(parent: Instance, name: string, color: Color3, order: number)
	local back = Instance.new("Frame")
	back.Name = name
	back.Size = BAR_SIZE
	back.BackgroundColor3 = BACK_COLOR
	back.BackgroundTransparency = 0.3
	back.BorderSizePixel = 0
	back.LayoutOrder = order
	back.Parent = parent

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back

	-- Covers the right-hand part of the bar that is currently unavailable.
	local locked = Instance.new("Frame")
	locked.Name = "Locked"
	locked.AnchorPoint = Vector2.new(1, 0)
	locked.Position = UDim2.fromScale(1, 0)
	locked.Size = UDim2.fromScale(0, 1)
	locked.BackgroundColor3 = LOCKED_COLOR
	locked.BorderSizePixel = 0
	locked.Parent = back

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 16
	label.ZIndex = 2
	label.Parent = back

	return fill, locked, label
end

function PardnerHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "PardnerHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local bars = Instance.new("Frame")
	bars.Name = "Bars"
	bars.AnchorPoint = Vector2.new(0, 1)
	bars.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
	bars.Size = UDim2.fromOffset(BAR_SIZE.X.Offset, BAR_SIZE.Y.Offset * 3 + BAR_GAP * 2)
	bars.BackgroundTransparency = 1
	bars.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, BAR_GAP)
	layout.Parent = bars

	local healthFill, _, healthLabel = makeBar(bars, "Health", HEALTH_COLOR, 1)
	local staminaFill, staminaLocked, staminaLabel = makeBar(bars, "Stamina", STAMINA_COLOR, 2)
	local gripFill, _, gripLabel = makeBar(bars, "Grip", GRIP_COLOR, 3)

	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(6, 6)
	crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshair.BorderSizePixel = 0
	crosshair.Visible = false
	crosshair.Parent = gui

	local crosshairCorner = Instance.new("UICorner")
	crosshairCorner.CornerRadius = UDim.new(1, 0)
	crosshairCorner.Parent = crosshair

	local compass = Instance.new("TextLabel")
	compass.Name = "Compass"
	compass.AnchorPoint = Vector2.new(0.5, 0)
	compass.Position = UDim2.new(0.5, 0, 0, MARGIN * 2)
	compass.Size = UDim2.fromOffset(80, 30)
	compass.BackgroundColor3 = BACK_COLOR
	compass.BackgroundTransparency = 0.3
	compass.BorderSizePixel = 0
	compass.TextColor3 = Color3.new(1, 1, 1)
	compass.Font = Enum.Font.SourceSansBold
	compass.TextSize = 22
	compass.Visible = false
	compass.Parent = gui

	gui.Parent = parent

	return {
		gui = gui,
		setHealth = function(value: number, max: number)
			healthFill.Size = UDim2.fromScale(fraction(value, max), 1)
			healthLabel.Text = `Health {math.ceil(value)} / {math.ceil(max)}`
		end,
		setStamina = function(value: number, cap: number, max: number)
			staminaFill.Size = UDim2.fromScale(fraction(value, max), 1)
			staminaLocked.Size = UDim2.fromScale(1 - fraction(cap, max), 1)
			staminaLabel.Text = `Stamina {math.floor(value + 0.5)} / {math.floor(cap + 0.5)}`
		end,
		setGrip = function(value: number, max: number)
			gripFill.Size = UDim2.fromScale(fraction(value, max), 1)
			gripLabel.Text = `Grip {math.floor(value + 0.5)}`
		end,
		setAiming = function(aiming: boolean)
			crosshair.Visible = aiming
			compass.Visible = aiming
		end,
		setHeading = function(text: string)
			compass.Text = text
		end,
	}
end

return PardnerHud
