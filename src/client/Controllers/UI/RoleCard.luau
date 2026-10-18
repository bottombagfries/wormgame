--!strict
-- Phase 13: the full-screen role card shown during RoleAssign ("YOU ARE THE WORM" / "YOU ARE A PARDNER").
-- A role-colored backdrop slides in, the title slams down, then the description fades in. Text comes from
-- Config.Lobby.RoleCards, colors and motion from Config/Theme.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.Config.Lobby)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)
local UiSound = require(script.Parent.Components.UiSound)

export type Screen = {
	gui: ScreenGui,
	show: (role: string) -> (),
	hide: () -> (),
}

local SLAM_SCALE = 2.2
local SLAM_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local RoleCard = {}

function RoleCard.create(parent: Instance): Screen
	local colors = Theme.Colors
	local gui = Style.screen("RoleCard", 20)
	gui.ScreenInsets = Enum.ScreenInsets.None -- the backdrop covers the whole screen
	gui.Enabled = false

	local scrim = Instance.new("Frame")
	scrim.Name = "Scrim"
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = colors.Scrim
	scrim.BackgroundTransparency = 0.25
	scrim.BorderSizePixel = 0
	scrim.Parent = gui

	-- A wide role-colored band across the middle, like a poster strip.
	local band = Instance.new("Frame")
	band.Name = "Band"
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.5)
	band.Size = UDim2.fromScale(1, 0.46)
	band.BorderSizePixel = 0
	band.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = band
	local edgeTop = Instance.new("Frame")
	edgeTop.Size = UDim2.new(1, 0, 0, 6)
	edgeTop.BackgroundColor3 = colors.Accent
	edgeTop.BorderSizePixel = 0
	edgeTop.Parent = band
	local edgeBottom = edgeTop:Clone()
	edgeBottom.AnchorPoint = Vector2.new(0, 1)
	edgeBottom.Position = UDim2.fromScale(0, 1)
	edgeBottom.Parent = band

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundTransparency = 1
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.9, 0.9)
	inner.Parent = band
	local title = Label.new(inner, {
		name = "Title",
		font = Theme.Fonts.Display,
		color = colors.TextLight,
		size = UDim2.fromScale(1, 0.5),
		position = UDim2.fromScale(0.5, 0.08),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 110,
		outline = true,
	})
	local titleScale = Style.scaler(title)
	local description = Label.new(inner, {
		name = "Description",
		font = Theme.Fonts.BodyBold,
		color = colors.PaperLight,
		size = UDim2.fromScale(0.85, 0.3),
		position = UDim2.fromScale(0.5, 0.64),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 30,
		outline = true,
	})
	description.TextWrapped = true

	gui.Parent = parent

	local showing: string? = nil
	return {
		gui = gui,
		show = function(role: string)
			if showing == role then
				return
			end
			showing = role
			local card = LobbyConfig.RoleCards[role] or LobbyConfig.RoleCards.Pardner
			local worm = role == "Worm"
			local main = if worm then colors.Worm else colors.Pardner
			local dark = if worm then colors.WormDark else colors.PardnerDark
			gradient.Color = ColorSequence.new(main, dark)
			title.Text = card.title
			description.Text = card.description
			gui.Enabled = true

			band.Size = UDim2.fromScale(1, 0)
			Style.tween(band, Theme.Tween.Pop, { Size = UDim2.fromScale(1, 0.46) })
			titleScale.Scale = SLAM_SCALE
			title.TextTransparency = 1
			Style.tween(titleScale, SLAM_INFO, { Scale = 1 })
			Style.tween(title, Theme.Tween.Normal, { TextTransparency = 0 })
			description.TextTransparency = 1
			task.delay(LobbyConfig.RoleCards.WaitSeconds, function()
				if showing == role then
					Style.tween(description, Theme.Tween.Normal, { TextTransparency = 0 })
				end
			end)
			UiSound.play(Theme.Sounds.Reveal)
		end,
		hide = function()
			showing = nil
			gui.Enabled = false
		end,
	}
end

return RoleCard
