--!strict
-- Builds the Worm HUD (§14): health bar, mode, healing-ring line, pounce cooldown, controls.
-- The full ability bar arrives with the abilities in Phase 11. Layout only; HUDController feeds it.
-- TODO(asset): replace with real UI art.

export type Hud = {
	gui: ScreenGui,
	setHealth: (value: number, max: number) -> (),
	setMode: (text: string) -> (),
	setRing: (text: string) -> (),
	setAbilities: (text: string) -> (), -- one line per ability: key, name, cooldown
}

local WIDTH = 300
local MARGIN = 20
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local HEALTH_COLOR = Color3.fromRGB(170, 70, 60)
local CONTROLS = "WASD move  ·  right-drag to look  ·  abilities aim where the camera looks"

local WormHud = {}

local function makeText(parent: Instance, name: string, order: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, textSize + 6)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = ""
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

function WormHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "WormHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false

	local column = Instance.new("Frame")
	column.Name = "Column"
	column.AnchorPoint = Vector2.new(0, 1)
	column.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
	column.Size = UDim2.fromOffset(WIDTH, 0)
	column.AutomaticSize = Enum.AutomaticSize.Y
	column.BackgroundTransparency = 1
	column.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = column

	local mode = makeText(column, "Mode", 1, 20)
	local ring = makeText(column, "Ring", 2, 17)
	ring.TextColor3 = Color3.fromRGB(255, 220, 120)
	local abilities = makeText(column, "Abilities", 3, 17)

	local bar = Instance.new("Frame")
	bar.Name = "Health"
	bar.Size = UDim2.new(1, 0, 0, 24)
	bar.BackgroundColor3 = BACK_COLOR
	bar.BackgroundTransparency = 0.3
	bar.BorderSizePixel = 0
	bar.LayoutOrder = 4
	bar.Parent = column

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = HEALTH_COLOR
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local healthLabel = makeText(bar, "Label", 0, 16)
	healthLabel.Size = UDim2.fromScale(1, 1)
	healthLabel.AutomaticSize = Enum.AutomaticSize.None
	healthLabel.TextXAlignment = Enum.TextXAlignment.Center
	healthLabel.ZIndex = 2

	local controls = makeText(column, "Controls", 5, 15)
	controls.Text = CONTROLS

	gui.Parent = parent

	return {
		gui = gui,
		setHealth = function(value: number, max: number)
			fill.Size = UDim2.fromScale(if max > 0 then math.clamp(value / max, 0, 1) else 0, 1)
			healthLabel.Text = `Worm health {math.floor(value)} / {max}`
		end,
		setMode = function(text: string)
			mode.Text = text
		end,
		setRing = function(text: string)
			ring.Text = text
		end,
		setAbilities = function(text: string)
			abilities.Text = text
		end,
	}
end

return WormHud
