--!strict
-- Builds the Puzzle Map panel (§10.7), shown while holding a Puzzle Map: where the safe and the code's
-- digit signs are, and what's been recorded. Layout only; SafeController feeds it the text.
-- TODO(asset): replace with an actual drawn map.

export type Hud = {
	gui: ScreenGui,
	setVisible: (visible: boolean) -> (),
	setText: (text: string) -> (),
}

local WIDTH = 300
local MARGIN = 20
local BACK_COLOR = Color3.fromRGB(70, 55, 35)

local PuzzleMapHud = {}

function PuzzleMapHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "PuzzleMapHud"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local panel = Instance.new("TextLabel")
	panel.Name = "Map"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, MARGIN, 0.45, 0)
	panel.Size = UDim2.fromOffset(WIDTH, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = BACK_COLOR
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.TextColor3 = Color3.fromRGB(255, 240, 210)
	panel.Font = Enum.Font.SourceSansBold
	panel.TextSize = 18
	panel.TextXAlignment = Enum.TextXAlignment.Left
	panel.TextYAlignment = Enum.TextYAlignment.Top
	panel.TextWrapped = true
	panel.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	gui.Parent = parent

	return {
		gui = gui,
		setVisible = function(visible: boolean)
			gui.Enabled = visible
		end,
		setText = function(text: string)
			panel.Text = text
		end,
	}
end

return PuzzleMapHud
