--!strict
-- Builds the mouth-escape minigame (§8.3): the arrow to press, a progress bar with checkpoints,
-- and the auto-escape line. Layout only; MinigameController feeds it. TODO(asset): real UI art.

export type Hud = {
	gui: ScreenGui,
	setVisible: (visible: boolean) -> (),
	setArrow: (arrow: string?) -> (),
	setProgress: (progress: number, checkpoint: number, total: number) -> (),
	setHint: (text: string) -> (),
	flashWrong: () -> (),
}

type ArrowStyle = { glyph: string, key: string, color: Color3 }

-- Color-coded so each direction can be read at a glance.
local ARROWS: { [string]: ArrowStyle } = {
	Up = { glyph = "↑", key = "W", color = Color3.fromRGB(70, 140, 230) },
	Down = { glyph = "↓", key = "S", color = Color3.fromRGB(80, 190, 90) },
	Left = { glyph = "←", key = "A", color = Color3.fromRGB(230, 190, 50) },
	Right = { glyph = "→", key = "D", color = Color3.fromRGB(220, 70, 70) },
}

local PANEL_SIZE = UDim2.fromOffset(360, 250)
local ARROW_SIZE = 130
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local WRONG_COLOR = Color3.fromRGB(150, 30, 30)
local PROGRESS_COLOR = Color3.fromRGB(240, 240, 240)
local CHECKPOINT_COLOR = Color3.fromRGB(120, 220, 120)
local FLASH_SECONDS = 0.2

local MinigameHud = {}

function MinigameHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "MinigameHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.55)
	panel.Size = PANEL_SIZE
	panel.BackgroundColor3 = BACK_COLOR
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(0.5, 0)
	arrow.Position = UDim2.new(0.5, 0, 0, 14)
	arrow.Size = UDim2.fromOffset(ARROW_SIZE, ARROW_SIZE)
	arrow.BorderSizePixel = 0
	arrow.TextColor3 = Color3.new(1, 1, 1)
	arrow.Font = Enum.Font.SourceSansBold
	arrow.TextSize = 100
	arrow.Parent = panel

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.AnchorPoint = Vector2.new(0.5, 0)
	key.Position = UDim2.new(0.5, 0, 0, ARROW_SIZE + 18)
	key.Size = UDim2.fromOffset(300, 24)
	key.BackgroundTransparency = 1
	key.TextColor3 = Color3.new(1, 1, 1)
	key.Font = Enum.Font.SourceSansBold
	key.TextSize = 20
	key.Parent = panel

	local bar = Instance.new("Frame")
	bar.Name = "Progress"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, ARROW_SIZE + 50)
	bar.Size = UDim2.fromOffset(320, 18)
	bar.BackgroundColor3 = Color3.new(0, 0, 0)
	bar.BorderSizePixel = 0
	bar.Parent = panel

	-- The bar can't fall below the checkpoint, so that part is drawn in its own color underneath.
	local checkpointFill = Instance.new("Frame")
	checkpointFill.Name = "Checkpoint"
	checkpointFill.Size = UDim2.fromScale(0, 1)
	checkpointFill.BackgroundColor3 = CHECKPOINT_COLOR
	checkpointFill.BorderSizePixel = 0
	checkpointFill.ZIndex = 2
	checkpointFill.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = PROGRESS_COLOR
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0, ARROW_SIZE + 78)
	hint.Size = UDim2.fromOffset(340, 22)
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Color3.fromRGB(255, 220, 120)
	hint.Font = Enum.Font.SourceSansBold
	hint.TextSize = 17
	hint.Parent = panel

	gui.Parent = parent

	local flashToken = 0

	return {
		gui = gui,
		setVisible = function(visible: boolean)
			gui.Enabled = visible
		end,
		setArrow = function(name: string?)
			local style = if name then ARROWS[name] else nil
			if style then
				arrow.Text = style.glyph
				arrow.BackgroundColor3 = style.color
				key.Text = `Press {style.key} (or the {name} arrow key)`
			else
				arrow.Text = "..."
				arrow.BackgroundColor3 = BACK_COLOR
				key.Text = ""
			end
		end,
		setProgress = function(progress: number, checkpoint: number, total: number)
			local scale = if total > 0 then 1 / total else 0
			fill.Size = UDim2.fromScale(math.clamp(progress * scale, 0, 1), 1)
			checkpointFill.Size = UDim2.fromScale(math.clamp(checkpoint * scale, 0, 1), 1)
		end,
		setHint = function(text: string)
			hint.Text = text
		end,
		flashWrong = function()
			flashToken += 1
			local token = flashToken
			panel.BackgroundColor3 = WRONG_COLOR
			task.delay(FLASH_SECONDS, function()
				if flashToken == token then
					panel.BackgroundColor3 = BACK_COLOR
				end
			end)
		end,
	}
end

return MinigameHud
