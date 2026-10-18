--!strict
-- Phase 13 lobby HUD: the round status strip (top-center) with last round's result and the host's
-- difficulty button, an info card (bottom-right: players, your Worm chance), and the menu buttons down the
-- left side (Shop, Cosmetics, Settings, Spectate, AFK). Layout only; LobbyController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Button = require(script.Parent.Components.Button)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Callbacks = {
	onShop: () -> (),
	onCosmetics: () -> (),
	onSettings: () -> (),
	onSpectate: () -> (),
	onAfk: () -> (),
	onDifficulty: () -> (),
}

export type Hud = {
	gui: ScreenGui,
	setVisible: (visible: boolean) -> (),
	setStatus: (text: string, urgent: boolean) -> (),
	setLastResult: (text: string) -> (),
	setPlayers: (active: number, total: number) -> (),
	setWormChance: (percent: number, afk: boolean) -> (),
	setAfk: (afk: boolean) -> (),
	setSpectateEnabled: (enabled: boolean) -> (),
	setDifficulty: (name: string, canEdit: boolean) -> (),
}

local LobbyHud = {}

local function woodBox(parent: Instance, name: string, size: UDim2, position: UDim2, anchor: Vector2): Frame
	local root = Instance.new("Frame")
	root.Name = name
	root.Size = size
	root.Position = position
	root.AnchorPoint = anchor
	root.ZIndex = 2
	root.Parent = parent
	local body = Style.shadowed(root, Theme.Corner.Panel)
	body.BackgroundColor3 = Theme.Colors.Wood
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, Theme.Colors.WoodDark, Theme.Stroke.Panel)
	return body
end

-- Raises the minimum size, reusing a UISizeConstraint the component already has (only one is honored).
local function minSize(gui: GuiObject, x: number, y: number)
	local constraint = gui:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(math.max(x, constraint.MinSize.X), math.max(y, constraint.MinSize.Y))
	constraint.Parent = gui
end

function LobbyHud.create(parent: Instance, callbacks: Callbacks): Hud
	local colors = Theme.Colors
	local gui = Style.screen("LobbyHud", 5)
	gui.Enabled = false

	-- Status strip --------------------------------------------------------------------------------
	local strip = woodBox(gui, "Status", UDim2.fromScale(0.42, 0.075), UDim2.fromScale(0.5, 0.03), Vector2.new(0.5, 0))
	minSize(strip.Parent :: Frame, 280, 44)
	local status = Label.new(strip, {
		name = "Text",
		font = Theme.Fonts.Heading,
		color = colors.TextLight,
		size = UDim2.fromScale(0.92, 0.7),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 32,
	})
	status.ZIndex = 4
	local statusScale = Style.scaler(strip.Parent :: Frame)

	local lastResult = Label.new(gui, {
		name = "LastResult",
		font = Theme.Fonts.BodyBold,
		color = colors.PaperLight,
		size = UDim2.fromScale(0.5, 0.035),
		position = UDim2.fromScale(0.5, 0.115),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 20,
		outline = true,
	})
	local difficulty = Button.new(gui, {
		name = "Difficulty",
		text = "",
		variant = "Paper",
		size = UDim2.fromScale(0.34, 0.05),
		position = UDim2.fromScale(0.5, 0.16),
		anchor = Vector2.new(0.5, 0),
		onClick = callbacks.onDifficulty,
	})
	minSize(difficulty.button, 180, 0)

	-- Info card ----------------------------------------------------------------------------------
	local cardRoot = Instance.new("Frame")
	cardRoot.Name = "Info"
	cardRoot.AnchorPoint = Vector2.new(1, 1)
	cardRoot.Position = UDim2.fromScale(0.985, 0.97)
	cardRoot.Size = UDim2.fromScale(0.18, 0.13)
	cardRoot.ZIndex = 2
	cardRoot.Parent = gui
	minSize(cardRoot, 150, 76)
	local card = Style.shadowed(cardRoot, Theme.Corner.Panel)
	card.BackgroundColor3 = colors.Paper
	Style.corner(card, Theme.Corner.Panel)
	Style.stroke(card, colors.WoodDark, Theme.Stroke.Panel)
	Style.padding(card, Theme.Padding.Button)

	local function row(y: number, caption: string): TextLabel
		local captionLabel = Label.new(card, {
			text = caption,
			font = Theme.Fonts.BodyBold,
			color = colors.InkSoft,
			size = UDim2.fromScale(0.62, 0.42),
			position = UDim2.fromScale(0, y),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 18,
		})
		captionLabel.ZIndex = 4
		local value = Label.new(card, {
			font = Theme.Fonts.Numbers,
			size = UDim2.fromScale(0.38, 0.46),
			position = UDim2.fromScale(1, y),
			anchor = Vector2.new(1, 0),
			align = Enum.TextXAlignment.Right,
			maxTextSize = 26,
		})
		value.ZIndex = 4
		return value
	end
	local players = row(0.02, "Players")
	local chance = row(0.52, "Worm chance")
	chance.TextColor3 = colors.Worm

	-- Menu buttons -------------------------------------------------------------------------------
	local menu = Instance.new("Frame")
	menu.Name = "Menu"
	menu.BackgroundTransparency = 1
	menu.AnchorPoint = Vector2.new(0, 0.5)
	menu.Position = UDim2.fromScale(0.015, 0.55)
	menu.Size = UDim2.fromScale(0.15, 0.46)
	menu.Parent = gui
	minSize(menu, 130, 0)
	local layout = Instance.new("UIListLayout")
	layout.Padding = Theme.Padding.Gap
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = menu

	local buttonSize = UDim2.fromScale(1, 0.17)
	Button.new(menu, { text = "SHOP", variant = "Accent", size = buttonSize, order = 1, onClick = callbacks.onShop })
	Button.new(
		menu,
		{ text = "COSMETICS", variant = "Paper", size = buttonSize, order = 2, onClick = callbacks.onCosmetics }
	)
	Button.new(
		menu,
		{ text = "SETTINGS", variant = "Paper", size = buttonSize, order = 3, onClick = callbacks.onSettings }
	)
	local spectate = Button.new(
		menu,
		{ text = "SPECTATE", variant = "Paper", size = buttonSize, order = 4, onClick = callbacks.onSpectate }
	)
	local afk = Button.new(
		menu,
		{ text = "AFK: OFF", variant = "Wood", size = buttonSize, order = 5, onClick = callbacks.onAfk }
	)

	gui.Parent = parent

	local lastStatus = ""
	return {
		gui = gui,
		setVisible = function(visible: boolean)
			gui.Enabled = visible
		end,
		setStatus = function(text: string, urgent: boolean)
			if text == lastStatus then
				return
			end
			lastStatus = text
			status.Text = text
			status.TextColor3 = if urgent then colors.Accent else colors.TextLight
			if urgent then
				statusScale.Scale = 1.08
				Style.tween(statusScale, Theme.Tween.Pop, { Scale = 1 })
			end
		end,
		setLastResult = function(text: string)
			lastResult.Text = text
		end,
		setPlayers = function(active: number, total: number)
			players.Text = if active == total then tostring(total) else `{active}/{total}`
		end,
		setWormChance = function(percent: number, isAfk: boolean)
			chance.Text = if isAfk then "AFK" else `{percent}%`
		end,
		setAfk = function(isAfk: boolean)
			afk.setText(if isAfk then "AFK: ON" else "AFK: OFF")
			afk.setVariant(if isAfk then "Good" else "Wood")
		end,
		setSpectateEnabled = function(enabled: boolean)
			spectate.setEnabled(enabled)
		end,
		setDifficulty = function(name: string, canEdit: boolean)
			difficulty.setText(`Difficulty: {name}`)
			difficulty.setEnabled(canEdit)
		end,
	}
end

return LobbyHud
