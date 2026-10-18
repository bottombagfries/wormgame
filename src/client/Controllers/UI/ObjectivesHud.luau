--!strict
-- The match panel (§14, restyled in Phase 13): an objectives card top-right (role + difficulty, a
-- checklist with progress, the Train's status) and the sundown clock chip at top-center (sun by day, moon
-- at night). Layout only; HUDController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Types = require(ReplicatedStorage.Shared.Types)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Hud = {
	gui: ScreenGui,
	setHeader: (text: string, role: string) -> (),
	setSundown: (text: string, night: boolean) -> (),
	setObjectives: (list: { Types.ObjectiveProgress }) -> (),
	setStatus: (text: string) -> (),
	setCompact: (compact: boolean) -> (), -- narrow screens: the clock moves under the Roblox buttons
}

local ROW_HEIGHT = 26 -- px per checklist row (the card grows with the list)

local ObjectivesHud = {}

function ObjectivesHud.create(parent: Instance): Hud
	local colors = Theme.Colors
	local gui = Style.screen("ObjectivesHud", 2)

	-- Objectives card --------------------------------------------------------------------------------
	local root = Instance.new("Frame")
	root.Name = "Objectives"
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.fromScale(0.985, 0.02)
	root.Size = UDim2.fromScale(0.25, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.BackgroundTransparency = 1
	root.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(200, 0)
	limits.MaxSize = Vector2.new(360, math.huge)
	limits.Parent = root

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.fromScale(1, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundColor3 = colors.Paper
	body.ZIndex = 2
	body.Parent = root
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, colors.WoodDark, Theme.Stroke.Panel)
	Style.padding(body, Theme.Padding.Button)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	local function line(name: string, order: number, font: Font, color: Color3, height: number): TextLabel
		local label = Label.new(body, {
			name = name,
			font = font,
			color = color,
			size = UDim2.new(1, 0, 0, height),
			align = Enum.TextXAlignment.Left,
			maxTextSize = height - 4,
			order = order,
		})
		label.ZIndex = 3
		return label
	end

	local header = line("Header", 1, Theme.Fonts.Display, colors.Ink, 28)
	local status = line("Status", 1000, Theme.Fonts.BodyBold, colors.AccentDark, 36)
	status.TextWrapped = true

	-- Sundown chip -------------------------------------------------------------------------------
	local chip = Instance.new("Frame")
	chip.Name = "Sundown"
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Position = UDim2.fromScale(0.5, 0.02)
	chip.Size = UDim2.fromScale(0.16, 0.06)
	chip.BackgroundColor3 = colors.Wood
	chip.ZIndex = 2
	chip.Parent = gui
	local chipLimits = Instance.new("UISizeConstraint")
	chipLimits.MinSize = Vector2.new(120, 36)
	chipLimits.Parent = chip
	Style.corner(chip, Theme.Corner.Pill)
	local chipStroke = Style.stroke(chip, colors.Accent, Theme.Stroke.Panel)
	local dial = Instance.new("Frame")
	dial.Name = "Dial"
	dial.AnchorPoint = Vector2.new(0, 0.5)
	dial.Position = UDim2.fromScale(0.06, 0.5)
	dial.Size = UDim2.fromScale(0.6, 0.6)
	dial.ZIndex = 3
	Style.aspect(dial, 1)
	Style.corner(dial, Theme.Corner.Pill)
	dial.Parent = chip
	local clock = Label.new(chip, {
		name = "Clock",
		font = Theme.Fonts.Numbers,
		color = colors.TextLight,
		size = UDim2.fromScale(0.66, 0.7),
		position = UDim2.fromScale(0.95, 0.5),
		anchor = Vector2.new(1, 0.5),
		align = Enum.TextXAlignment.Right,
		maxTextSize = 28,
		outline = true,
	})
	clock.ZIndex = 3
	local chipScale = Style.scaler(chip)

	gui.Parent = parent

	local rows: { [string]: { frame: Frame, box: Frame, text: TextLabel } } = {}
	local wasNight = false

	return {
		gui = gui,
		setHeader = function(text: string, role: string)
			header.Text = text
			header.TextColor3 = if role == "Worm" then colors.Worm else colors.Pardner
		end,
		setSundown = function(text: string, night: boolean)
			clock.Text = text
			dial.BackgroundColor3 = if night then colors.GhostRole else colors.Accent
			chip.BackgroundColor3 = if night then colors.PardnerDark else colors.Wood
			chipStroke.Color = if night then colors.GhostRole else colors.Accent
			if night and not wasNight then
				chipScale.Scale = 1.25
				Style.tween(chipScale, Theme.Tween.Pop, { Scale = 1 })
			end
			wasNight = night
		end,
		setObjectives = function(list: { Types.ObjectiveProgress })
			local seen: { [string]: boolean } = {}
			for index, progress in list do
				seen[progress.id] = true
				local row = rows[progress.id]
				if not row then
					local frame = Instance.new("Frame")
					frame.Name = progress.id
					frame.BackgroundTransparency = 1
					frame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
					frame.ZIndex = 3
					frame.Parent = body
					local box = Instance.new("Frame")
					box.Name = "Check"
					box.AnchorPoint = Vector2.new(0, 0.5)
					box.Position = UDim2.fromScale(0, 0.5)
					box.Size = UDim2.fromScale(0.7, 0.7)
					box.ZIndex = 4
					Style.aspect(box, 1)
					Style.corner(box, UDim.new(0, 4))
					Style.stroke(box, colors.WoodDark, 2)
					box.Parent = frame
					local text = Label.new(frame, {
						size = UDim2.new(1, -ROW_HEIGHT, 0.9, 0),
						position = UDim2.new(0, ROW_HEIGHT, 0.05, 0),
						align = Enum.TextXAlignment.Left,
						maxTextSize = 18,
					})
					text.ZIndex = 4
					row = { frame = frame, box = box, text = text }
					rows[progress.id] = row
				end
				local wasDone = row.box.BackgroundColor3 == colors.Good
				row.frame.LayoutOrder = 10 + index
				row.box.BackgroundColor3 = if progress.done then colors.Good else colors.PaperLight
				row.text.Text = `{progress.displayName}   {progress.current}/{progress.target}`
				row.text.TextColor3 = if progress.done then colors.InkSoft else colors.Ink
				if progress.done and not wasDone then
					local scale = Style.scaler(row.box)
					scale.Scale = 1.5
					Style.tween(scale, Theme.Tween.Pop, { Scale = 1 })
				end
			end
			for id, row in rows do
				if not seen[id] then
					row.frame:Destroy()
					rows[id] = nil
				end
			end
		end,
		setStatus = function(text: string)
			status.Text = text
		end,
		setCompact = function(compact: boolean)
			chip.AnchorPoint = if compact then Vector2.zero else Vector2.new(0.5, 0)
			chip.Position = if compact then UDim2.fromScale(0.02, 0.08) else UDim2.fromScale(0.5, 0.02)
		end,
	}
end

return ObjectivesHud
