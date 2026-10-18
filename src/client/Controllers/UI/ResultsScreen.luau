--!strict
-- Phase 13 results screen (Ending): a winner banner in the winning side's color, your own outcome, who
-- escaped and who didn't, the round's stats, and a countdown back to the station. Layout only;
-- MatchController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Types = require(ReplicatedStorage.Shared.Types)
local Label = require(script.Parent.Components.Label)
local Panel = require(script.Parent.Components.Panel)
local Style = require(script.Parent.Components.Style)
local UiSound = require(script.Parent.Components.UiSound)

export type Screen = {
	gui: ScreenGui,
	show: (result: Types.MatchResult, outcome: string, endsAt: number?) -> (),
	hide: () -> (),
}

local ResultsScreen = {}

local function clock(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function listText(names: { string }, empty: string): string
	return if #names > 0 then table.concat(names, "\n") else empty
end

function ResultsScreen.create(parent: Instance): Screen
	local colors = Theme.Colors
	local gui = Style.screen("ResultsScreen", 26) -- above toasts
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.Enabled = false

	local scrim = Instance.new("Frame")
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = colors.Scrim
	scrim.BackgroundTransparency = 0.35
	scrim.BorderSizePixel = 0
	scrim.Parent = gui

	-- Winner banner
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.fromScale(0.5, 0.05)
	banner.Size = UDim2.fromScale(1, 0.16)
	banner.BorderSizePixel = 0
	banner.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = banner
	local headline = Label.new(banner, {
		name = "Headline",
		font = Theme.Fonts.Display,
		color = colors.TextLight,
		size = UDim2.fromScale(0.9, 0.62),
		position = UDim2.fromScale(0.5, 0.06),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 90,
		outline = true,
	})
	local headlineScale = Style.scaler(headline)
	local outcomeLabel = Label.new(banner, {
		name = "Outcome",
		font = Theme.Fonts.Heading,
		color = colors.Accent,
		size = UDim2.fromScale(0.9, 0.26),
		position = UDim2.fromScale(0.5, 0.7),
		anchor = Vector2.new(0.5, 0),
		maxTextSize = 30,
		outline = true,
	})

	-- Body: escaped / didn't make it, then stats
	local panel = Panel.new(gui, {
		name = "Summary",
		size = UDim2.fromScale(0.62, 0.62),
		position = UDim2.fromScale(0.5, 0.25),
		anchor = Vector2.new(0.5, 0),
	})
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(330, 0)
	limits.MaxSize = Vector2.new(820, math.huge)
	limits.Parent = panel.frame

	local function column(x: number, title: string, color: Color3): TextLabel
		Label.new(panel.content, {
			text = title,
			font = Theme.Fonts.Heading,
			color = color,
			size = UDim2.fromScale(0.48, 0.08),
			position = UDim2.fromScale(x, 0),
			maxTextSize = 24,
		}).ZIndex =
			4
		local names = Label.new(panel.content, {
			font = Theme.Fonts.BodyBold,
			size = UDim2.fromScale(0.48, 0.4),
			position = UDim2.fromScale(x, 0.09),
			maxTextSize = 20,
		})
		names.TextWrapped = true
		names.TextYAlignment = Enum.TextYAlignment.Top
		names.ZIndex = 4
		return names
	end
	local escapedList = column(0, "ESCAPED", colors.Good)
	local deadList = column(0.52, "DIDN'T MAKE IT", colors.Danger)

	local divider = Instance.new("Frame")
	divider.Position = UDim2.fromScale(0, 0.52)
	divider.Size = UDim2.new(1, 0, 0, 3)
	divider.BackgroundColor3 = colors.WoodDark
	divider.BorderSizePixel = 0
	divider.ZIndex = 4
	divider.Parent = panel.content

	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.BackgroundTransparency = 1
	stats.Position = UDim2.fromScale(0, 0.56)
	stats.Size = UDim2.fromScale(1, 0.34)
	stats.ZIndex = 3
	stats.Parent = panel.content
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromScale(0.32, 0.46)
	grid.CellPadding = UDim2.fromScale(0.02, 0.06)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = stats

	local statLabels: { TextLabel } = {}
	local function stat(order: number, caption: string)
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = colors.PaperLight
		cell.LayoutOrder = order
		cell.ZIndex = 4
		Style.corner(cell, Theme.Corner.Button)
		Style.stroke(cell, colors.WoodDark, Theme.Stroke.Slot)
		cell.Parent = stats
		local value = Label.new(cell, {
			font = Theme.Fonts.Numbers,
			size = UDim2.fromScale(0.9, 0.55),
			position = UDim2.fromScale(0.5, 0.06),
			anchor = Vector2.new(0.5, 0),
			maxTextSize = 30,
		})
		value.ZIndex = 5
		Label.new(cell, {
			text = caption,
			color = colors.InkSoft,
			size = UDim2.fromScale(0.92, 0.32),
			position = UDim2.fromScale(0.5, 0.62),
			anchor = Vector2.new(0.5, 0),
			maxTextSize = 16,
		}).ZIndex =
			5
		statLabels[order] = value
	end
	stat(1, "Fuel delivered")
	stat(2, "Objectives")
	stat(3, "Round time")
	stat(4, "Pardners eaten")
	stat(5, "Other deaths")
	stat(6, "Revives")

	local countdown = Label.new(panel.content, {
		name = "Countdown",
		color = colors.InkSoft,
		size = UDim2.fromScale(1, 0.07),
		position = UDim2.fromScale(0, 0.93),
		maxTextSize = 18,
	})
	countdown.ZIndex = 4

	gui.Parent = parent

	local returnAt: number? = nil
	local ticking = false

	local function tick()
		if ticking then
			return
		end
		ticking = true
		task.spawn(function()
			while gui.Enabled do
				local left = (returnAt or 0) - Workspace:GetServerTimeNow()
				countdown.Text = `Back to the station in {math.max(0, math.ceil(left))}s`
				task.wait(0.25)
			end
			ticking = false
		end)
	end

	return {
		gui = gui,
		show = function(result: Types.MatchResult, outcome: string, endsAt: number?)
			local pardnersWon = result.winner == "Pardners"
			local main = if pardnersWon then colors.Pardner else colors.Worm
			local dark = if pardnersWon then colors.PardnerDark else colors.WormDark
			gradient.Color = ColorSequence.new(main, dark)
			headline.Text = if pardnersWon then "THE PARDNERS ESCAPED!" else "THE WORM WINS"
			outcomeLabel.Text = outcome
			escapedList.Text = listText(result.escaped, "Nobody")
			deadList.Text = listText(result.dead, "Nobody")

			local s = result.stats
			statLabels[1].Text = if s then `{s.fuelDelivered} ({math.floor(s.fuelMeter)}%)` else "-"
			statLabels[2].Text = if s then `{s.objectivesDone}/{s.objectivesTotal}` else "-"
			statLabels[3].Text = if s then clock(s.seconds) else "-"
			statLabels[4].Text = if s then tostring(s.pardnersEaten) else "-"
			statLabels[5].Text = if s then tostring(s.pardnersDied) else "-"
			statLabels[6].Text = if s then tostring(s.revives) else "-"

			returnAt = endsAt
			gui.Enabled = true
			headlineScale.Scale = 1.8
			Style.tween(
				headlineScale,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			panel.popIn()
			UiSound.play(Theme.Sounds.Reveal)
			tick()
		end,
		hide = function()
			gui.Enabled = false
		end,
	}
end

return ResultsScreen
