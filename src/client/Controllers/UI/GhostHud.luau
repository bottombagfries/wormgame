--!strict
-- Builds the ghost HUD (§8.4): controls, push cooldown and the charge bar.
-- Layout only; GhostController feeds it. TODO(asset): replace with real UI art.

export type Hud = {
	gui: ScreenGui,
	setStatus: (text: string) -> (),
	setCharge: (fraction: number) -> (), -- 0 hides the bar
}

local WIDTH = 420
local MARGIN = 20
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local CHARGE_COLOR = Color3.fromRGB(200, 230, 255)
local CONTROLS = "You are a ghost  ·  WASD fly  ·  Space up  ·  Shift down  ·  hold E on an item to push it"

local GhostHud = {}

local function makeText(parent: Instance, name: string, y: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.fromOffset(0, y)
	label.Size = UDim2.new(1, 0, 0, textSize + 6)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent
	return label
end

function GhostHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "GhostHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -MARGIN)
	panel.Size = UDim2.fromOffset(WIDTH, 76)
	panel.BackgroundTransparency = 1
	panel.Parent = gui

	local controls = makeText(panel, "Controls", 0, 16)
	controls.Text = CONTROLS
	local status = makeText(panel, "Status", 24, 18)
	status.TextColor3 = Color3.fromRGB(255, 220, 120)

	local bar = Instance.new("Frame")
	bar.Name = "Charge"
	bar.Position = UDim2.fromOffset(0, 54)
	bar.Size = UDim2.new(1, 0, 0, 14)
	bar.BackgroundColor3 = BACK_COLOR
	bar.BackgroundTransparency = 0.3
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = panel

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = CHARGE_COLOR
	fill.BorderSizePixel = 0
	fill.Parent = bar

	gui.Parent = parent

	return {
		gui = gui,
		setStatus = function(text: string)
			status.Text = text
		end,
		setCharge = function(fraction: number)
			bar.Visible = fraction > 0
			fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		end,
	}
end

return GhostHud
