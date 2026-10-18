--!strict
-- The Worm's timed ability pick (WormLoadout, §14), and the strip Pardners see while the Worm chooses.
-- Built from the shared components; MatchController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Bar = require(script.Parent.Components.Bar)
local Label = require(script.Parent.Components.Label)
local Panel = require(script.Parent.Components.Panel)
local Style = require(script.Parent.Components.Style)
local UiSound = require(script.Parent.Components.UiSound)

export type Screen = {
	gui: ScreenGui,
	showPicker: (secondsLeft: number, totalSeconds: number) -> (),
	showWaiting: (text: string) -> (),
	hide: () -> (),
	resetPicks: () -> (),
}

local LoadoutScreen = {}

-- onPicksChanged gets the chosen ability ids every time the worm changes their selection.
function LoadoutScreen.create(parent: Instance, onPicksChanged: (ids: { string }) -> ()): Screen
	local colors = Theme.Colors
	local gui = Style.screen("LoadoutScreen", 15)
	gui.Enabled = false

	-- The Worm's picker ---------------------------------------------------------------------------
	local panel = Panel.new(gui, {
		name = "Picker",
		title = `PICK {GameConfig.WormAbilityPicks} ABILITIES`,
		size = UDim2.fromScale(0.62, 0.86),
	})
	Style.aspect(panel.frame, 0.95)
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(330, 0)
	limits.Parent = panel.frame

	local timer = Bar.new(panel.content, {
		label = "Time",
		color = colors.Worm,
		size = UDim2.fromScale(1, 0.07),
	})
	local count = Label.new(panel.content, {
		name = "Count",
		font = Theme.Fonts.Heading,
		size = UDim2.fromScale(1, 0.06),
		position = UDim2.fromScale(0, 0.085),
		maxTextSize = 24,
	})

	local grid = Instance.new("Frame")
	grid.Name = "Abilities"
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromScale(0, 0.17)
	grid.Size = UDim2.fromScale(1, 0.83)
	grid.ZIndex = 3
	grid.Parent = panel.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(0.485, 0.23)
	layout.CellPadding = UDim2.fromScale(0.03, 0.025)
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
	local cards: { [string]: { button: TextButton, stroke: UIStroke, badge: TextLabel } } = {}

	local function refresh()
		for id, card in cards do
			local index = table.find(picks, id)
			card.button.BackgroundColor3 = if index then colors.Worm else colors.PaperLight
			card.stroke.Color = if index then colors.Accent else colors.WoodDark
			card.stroke.Thickness = if index then Theme.Stroke.Slot + 1 else Theme.Stroke.Slot
			card.badge.Text = if index then tostring(index) else ""
			for _, child in card.button:GetChildren() do
				if child:IsA("TextLabel") and child ~= card.badge then
					child.TextColor3 = if index then colors.TextLight else colors.Ink
				end
			end
		end
		count.Text = `Picked {#picks} / {GameConfig.WormAbilityPicks}`
	end

	for order, id in ids do
		local def = Abilities[id]
		local button = Instance.new("TextButton")
		button.Name = id
		button.Text = ""
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.LayoutOrder = order
		button.ZIndex = 4
		Style.corner(button, Theme.Corner.Button)
		local stroke = Style.stroke(button, colors.WoodDark, Theme.Stroke.Slot)
		local scale = Style.scaler(button)
		button.Parent = grid

		local name = Label.new(button, {
			text = def.displayName,
			font = Theme.Fonts.Heading,
			size = UDim2.fromScale(0.72, 0.36),
			position = UDim2.fromScale(0.06, 0.06),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 22,
		})
		name.ZIndex = 5
		local cooldown = Label.new(button, {
			text = `{def.cooldown}s`,
			font = Theme.Fonts.Numbers,
			size = UDim2.fromScale(0.2, 0.3),
			position = UDim2.fromScale(0.94, 0.08),
			anchor = Vector2.new(1, 0),
			align = Enum.TextXAlignment.Right,
			maxTextSize = 18,
		})
		cooldown.ZIndex = 5
		local description = Label.new(button, {
			text = def.description or "",
			size = UDim2.fromScale(0.88, 0.48),
			position = UDim2.fromScale(0.06, 0.46),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 16,
		})
		description.TextWrapped = true
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.ZIndex = 5
		local badge = Label.new(button, {
			name = "Badge",
			font = Theme.Fonts.Numbers,
			color = colors.Accent,
			size = UDim2.fromScale(0.14, 0.3),
			position = UDim2.fromScale(0.94, 0.94),
			anchor = Vector2.new(1, 1),
			align = Enum.TextXAlignment.Right,
			outline = true,
		})
		badge.ZIndex = 6
		cards[id] = { button = button, stroke = stroke, badge = badge }

		button.MouseEnter:Connect(function()
			UiSound.play(Theme.Sounds.Hover)
			Style.tween(scale, Theme.Tween.Fast, { Scale = Theme.Button.HoverScale })
		end)
		button.MouseLeave:Connect(function()
			Style.tween(scale, Theme.Tween.Fast, { Scale = 1 })
		end)
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
			UiSound.play(Theme.Sounds.Click)
			scale.Scale = Theme.Button.PressScale
			Style.tween(scale, Theme.Tween.Pop, { Scale = 1 })
			refresh()
			onPicksChanged(table.clone(picks))
		end)
	end
	refresh()

	-- What Pardners see meanwhile ----------------------------------------------------------------
	local strip = Instance.new("Frame")
	strip.Name = "Waiting"
	strip.AnchorPoint = Vector2.new(0.5, 0)
	strip.Position = UDim2.fromScale(0.5, 0.12)
	strip.Size = UDim2.fromScale(0.5, 0.08)
	strip.ZIndex = 2
	strip.Parent = gui
	local stripLimits = Instance.new("UISizeConstraint")
	stripLimits.MinSize = Vector2.new(300, 44)
	stripLimits.Parent = strip
	local stripBody = Style.shadowed(strip, Theme.Corner.Panel)
	stripBody.BackgroundColor3 = colors.Wood
	Style.corner(stripBody, Theme.Corner.Panel)
	Style.stroke(stripBody, colors.WoodDark, Theme.Stroke.Panel)
	local waiting = Label.new(stripBody, {
		font = Theme.Fonts.Heading,
		color = colors.TextLight,
		size = UDim2.fromScale(0.92, 0.7),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 28,
	})
	waiting.ZIndex = 4

	gui.Parent = parent

	local mode: string? = nil
	return {
		gui = gui,
		showPicker = function(secondsLeft: number, totalSeconds: number)
			if mode ~= "picker" then
				mode = "picker"
				strip.Visible = false
				panel.popIn()
			end
			timer.set(secondsLeft, totalSeconds)
			gui.Enabled = true
		end,
		showWaiting = function(text: string)
			mode = "waiting"
			panel.setVisible(false)
			strip.Visible = true
			waiting.Text = text
			gui.Enabled = true
		end,
		hide = function()
			mode = nil
			gui.Enabled = false
		end,
		resetPicks = function()
			table.clear(picks)
			refresh()
		end,
	}
end

return LoadoutScreen
