--!strict
-- Builds the lobby panel (§14): status text and the difficulty button (host only).
-- Layout only; MatchController feeds it. TODO(asset): replace with real UI art.

export type Callbacks = {
	onDifficulty: () -> (),
}

export type Screen = {
	gui: ScreenGui,
	setVisible: (visible: boolean) -> (),
	setText: (title: string, subtitle: string) -> (),
	setDifficulty: (name: string, canEdit: boolean) -> (),
}

local PANEL_SIZE = UDim2.fromOffset(420, 190)
local BUTTON_SIZE = UDim2.fromOffset(240, 40)
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local BUTTON_COLOR = Color3.fromRGB(70, 70, 80)

local LobbyScreen = {}

local function makeText(parent: Instance, name: string, y: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.fromOffset(0, y)
	label.Size = UDim2.new(1, 0, 0, textSize + 8)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent
	return label
end

function LobbyScreen.create(parent: Instance, callbacks: Callbacks): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "LobbyScreen"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 60)
	panel.Size = PANEL_SIZE
	panel.BackgroundColor3 = BACK_COLOR
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local title = makeText(panel, "Title", 14, 34)
	local subtitle = makeText(panel, "Subtitle", 68, 20)

	local difficulty = Instance.new("TextButton")
	difficulty.Name = "Difficulty"
	difficulty.AnchorPoint = Vector2.new(0.5, 0)
	difficulty.Position = UDim2.new(0.5, 0, 0, 130)
	difficulty.Size = BUTTON_SIZE
	difficulty.BackgroundColor3 = BUTTON_COLOR
	difficulty.BorderSizePixel = 0
	difficulty.TextColor3 = Color3.new(1, 1, 1)
	difficulty.Font = Enum.Font.SourceSansBold
	difficulty.TextSize = 18
	difficulty.Parent = panel
	difficulty.Activated:Connect(callbacks.onDifficulty)

	gui.Parent = parent

	return {
		gui = gui,
		setVisible = function(visible: boolean)
			gui.Enabled = visible
		end,
		setText = function(titleText: string, subtitleText: string)
			title.Text = titleText
			subtitle.Text = subtitleText
		end,
		setDifficulty = function(name: string, canEdit: boolean)
			difficulty.Text = if canEdit then `Difficulty: {name} (change)` else `Difficulty: {name}`
			difficulty.Active = canEdit
			difficulty.AutoButtonColor = canEdit
		end,
	}
end

return LobbyScreen
