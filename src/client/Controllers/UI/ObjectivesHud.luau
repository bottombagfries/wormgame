--!strict
-- Builds the match panel (top right): role, sundown clock, objective checklist, Train status.
-- Layout only; HUDController feeds it. TODO(asset): replace with real UI art.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

export type Hud = {
	gui: ScreenGui,
	setHeader: (text: string) -> (),
	setSundown: (text: string) -> (),
	setObjectives: (list: { Types.ObjectiveProgress }) -> (),
	setStatus: (text: string) -> (),
}

local PANEL_WIDTH = 300
local MARGIN = 20
local PADDING = 10
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local DONE_COLOR = Color3.fromRGB(120, 220, 120)

local ObjectivesHud = {}

local function makeText(parent: Instance, name: string, textSize: number, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, textSize + 6)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = ""
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

function ObjectivesHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "ObjectivesHud"
	gui.ResetOnSpawn = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -MARGIN, 0, MARGIN)
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = BACK_COLOR
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, PADDING)
	padding.PaddingBottom = UDim.new(0, PADDING)
	padding.PaddingLeft = UDim.new(0, PADDING)
	padding.PaddingRight = UDim.new(0, PADDING)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = panel

	local header = makeText(panel, "Header", 18, 1)
	local sundown = makeText(panel, "Sundown", 16, 2)
	local status = makeText(panel, "Status", 16, 1000)
	status.TextColor3 = Color3.fromRGB(255, 220, 120)

	local rows: { TextLabel } = {}

	gui.Parent = parent

	return {
		gui = gui,
		setHeader = function(text: string)
			header.Text = text
		end,
		setSundown = function(text: string)
			sundown.Text = text
		end,
		setObjectives = function(list: { Types.ObjectiveProgress })
			for _, row in rows do
				row:Destroy()
			end
			table.clear(rows)
			for index, progress in list do
				local row = makeText(panel, progress.id, 17, 10 + index)
				local mark = if progress.done then "[x]" else "[ ]"
				row.Text = `{mark} {progress.displayName}   {progress.current} / {progress.target}`
				row.TextColor3 = if progress.done then DONE_COLOR else Color3.new(1, 1, 1)
				table.insert(rows, row)
			end
		end,
		setStatus = function(text: string)
			status.Text = text
		end,
	}
end

return ObjectivesHud
