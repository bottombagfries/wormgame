--!strict
-- Builds the pre-match screen (§14): the role reveal, and the worm's ability picker.
-- Layout only; MatchController feeds it. TODO(asset): replace with real UI art.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

export type Screen = {
	gui: ScreenGui,
	show: (headline: string, color: Color3, subtitle: string, showPicker: boolean) -> (),
	hide: () -> (),
	resetPicks: () -> (),
}

local BUTTON_SIZE = UDim2.fromOffset(170, 44)
local GRID_COLUMNS = 4
local BUTTON_COLOR = Color3.fromRGB(70, 70, 80)
local PICKED_COLOR = Color3.fromRGB(170, 70, 60)

local LoadoutScreen = {}

local function makeText(parent: Instance, name: string, y: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, y)
	label.Size = UDim2.new(0.9, 0, 0, textSize + 8)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent
	return label
end

-- onPicksChanged gets the chosen ability ids every time the worm changes their selection.
function LoadoutScreen.create(parent: Instance, onPicksChanged: (ids: { string }) -> ()): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadoutScreen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 6
	gui.Enabled = false

	local headline = makeText(gui, "Headline", 0.18, 56)
	local subtitle = makeText(gui, "Subtitle", 0.3, 24)

	local grid = Instance.new("Frame")
	grid.Name = "Abilities"
	grid.AnchorPoint = Vector2.new(0.5, 0)
	grid.Position = UDim2.fromScale(0.5, 0.42)
	grid.Size = UDim2.fromOffset((BUTTON_SIZE.X.Offset + 10) * GRID_COLUMNS, 120)
	grid.BackgroundTransparency = 1
	grid.Visible = false
	grid.Parent = gui

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = BUTTON_SIZE
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local ids: { string } = {}
	for id, def in Abilities do
		if def.kind == "Choosable" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)

	local picks: { string } = {} -- oldest first
	local buttons: { [string]: TextButton } = {}

	local function refresh()
		for id, button in buttons do
			button.BackgroundColor3 = if table.find(picks, id) then PICKED_COLOR else BUTTON_COLOR
		end
	end

	for order, id in ids do
		local button = Instance.new("TextButton")
		button.Name = id
		button.BackgroundColor3 = BUTTON_COLOR
		button.BorderSizePixel = 0
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 17
		button.Text = `{Abilities[id].displayName} ({Abilities[id].cooldown}s)`
		button.LayoutOrder = order
		button.Parent = grid
		buttons[id] = button

		button.Activated:Connect(function()
			local index = table.find(picks, id)
			if index then
				table.remove(picks, index)
			else
				table.insert(picks, id)
				-- Picking one too many drops the oldest pick.
				while #picks > GameConfig.WormAbilityPicks do
					table.remove(picks, 1)
				end
			end
			refresh()
			onPicksChanged(table.clone(picks))
		end)
	end

	gui.Parent = parent

	return {
		gui = gui,
		show = function(headlineText: string, color: Color3, subtitleText: string, showPicker: boolean)
			headline.Text = headlineText
			headline.TextColor3 = color
			subtitle.Text = subtitleText
			grid.Visible = showPicker
			gui.Enabled = true
		end,
		hide = function()
			gui.Enabled = false
		end,
		resetPicks = function()
			table.clear(picks)
			refresh()
		end,
	}
end

return LoadoutScreen
