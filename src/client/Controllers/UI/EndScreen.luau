--!strict
-- Builds the end-of-match screen: winner, who escaped, who died (§14).
-- Layout only; HUDController shows and hides it. TODO(asset): replace with real UI art.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

export type Screen = {
	gui: ScreenGui,
	show: (result: Types.MatchResult, personalText: string) -> (), -- personalText: the viewer's own outcome
	hide: () -> (),
}

local PARDNER_COLOR = Color3.fromRGB(120, 220, 120)
local WORM_COLOR = Color3.fromRGB(230, 90, 80)

local EndScreen = {}

local function makeText(parent: Instance, name: string, y: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, y)
	label.Size = UDim2.new(0.8, 0, 0, textSize + 8)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.TextWrapped = true
	label.Text = ""
	label.Parent = parent
	return label
end

local function listNames(names: { string }): string
	return if #names > 0 then table.concat(names, ", ") else "nobody"
end

function EndScreen.create(parent: Instance): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "EndScreen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Enabled = false

	local back = Instance.new("Frame")
	back.Name = "Backdrop"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.new(0, 0, 0)
	back.BackgroundTransparency = 0.35
	back.BorderSizePixel = 0
	back.Parent = gui

	local headline = makeText(back, "Headline", 0.25, 56)
	local personal = makeText(back, "Personal", 0.4, 32)
	local escaped = makeText(back, "Escaped", 0.52, 24)
	local dead = makeText(back, "Dead", 0.6, 24)

	gui.Parent = parent

	return {
		gui = gui,
		show = function(result: Types.MatchResult, personalText: string)
			local pardnersWon = result.winner == "Pardners"
			headline.Text = if pardnersWon then "THE PARDNERS ESCAPED" else "THE WORM WINS"
			headline.TextColor3 = if pardnersWon then PARDNER_COLOR else WORM_COLOR
			personal.Text = personalText
			escaped.Text = `Escaped: {listNames(result.escaped)}`
			dead.Text = `Dead: {listNames(result.dead)}`
			gui.Enabled = true
		end,
		hide = function()
			gui.Enabled = false
		end,
	}
end

return EndScreen
