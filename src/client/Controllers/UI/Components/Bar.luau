--!strict
-- A stat bar: dark track, colored fill, a light "ghost" fill that lingers then tweens down after a drop, an
-- optional locked section on the right (e.g. stamina capped by health), and a value label.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Label = require(script.Parent.Label)
local Style = require(script.Parent.Style)

export type Options = {
	color: Color3,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	label: string?, -- prefix, e.g. "Health"
	order: number?,
	name: string?,
}

export type Bar = {
	frame: Frame,
	-- value / max; `cap` (<= max) locks the part of the bar above it.
	set: (value: number, max: number, cap: number?) -> (),
	setColor: (color: Color3) -> (),
	pulse: () -> (),
}

local Bar = {}

local function fraction(value: number, max: number): number
	return if max > 0 then math.clamp(value / max, 0, 1) else 0
end

function Bar.new(parent: Instance, options: Options): Bar
	local colors = Theme.Colors

	local track = Instance.new("Frame")
	track.Name = options.name or "Bar"
	track.Size = options.size or UDim2.fromScale(1, Theme.Sizes.BarHeight)
	track.Position = options.position or UDim2.new()
	track.AnchorPoint = options.anchor or Vector2.zero
	track.BackgroundColor3 = colors.Track
	track.BorderSizePixel = 0
	track.LayoutOrder = options.order or 0
	track.ClipsDescendants = true
	track.ZIndex = 3
	Style.corner(track, Theme.Corner.Bar)
	Style.stroke(track, colors.WoodDark, Theme.Stroke.Bar)
	track.Parent = parent

	local function fillFrame(name: string, color: Color3, z: number): Frame
		local fill = Instance.new("Frame")
		fill.Name = name
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.ZIndex = z
		Style.corner(fill, Theme.Corner.Bar)
		fill.Parent = track
		return fill
	end

	local ghost = fillFrame("Ghost", colors.Ghost, 4)
	local fill = fillFrame("Fill", options.color, 5)
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190))
	shine.Parent = fill

	local locked = fillFrame("Locked", colors.WoodDark, 5)
	locked.AnchorPoint = Vector2.new(1, 0)
	locked.Position = UDim2.fromScale(1, 0)
	locked.Size = UDim2.fromScale(0, 1)
	locked.BackgroundTransparency = 0.2

	local text = Label.new(track, {
		name = "Value",
		font = Theme.Fonts.Numbers,
		color = colors.TextLight,
		size = UDim2.fromScale(0.94, 0.86),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		align = Enum.TextXAlignment.Left,
		maxTextSize = 22,
		outline = true,
	})
	text.ZIndex = 6

	local scale = Style.scaler(track)
	local shown = 1
	local ghostToken = 0
	local lastKey = ""

	return {
		frame = track,
		set = function(value: number, max: number, cap: number?)
			-- HUDs call this every frame; only react when something visible changed.
			local key = `{math.floor(value * 10)}:{max}:{cap or -1}`
			if key == lastKey then
				return
			end
			lastKey = key
			local target = fraction(value, max)
			Style.tween(fill, Theme.Tween.Bar, { Size = UDim2.fromScale(target, 1) })
			if target < shown then
				-- Ghost waits, then catches up: shows how much was just lost.
				ghostToken += 1
				local token = ghostToken
				task.delay(Theme.Tween.GhostDelay, function()
					if token == ghostToken then
						Style.tween(ghost, Theme.Tween.Ghost, { Size = UDim2.fromScale(target, 1) })
					end
				end)
			else
				ghost.Size = UDim2.fromScale(target, 1)
			end
			shown = target
			local lockedShare = if cap then 1 - fraction(cap, max) else 0
			locked.Size = UDim2.fromScale(lockedShare, 1)
			local number = math.floor(value + 0.5)
			text.Text = if options.label then `{options.label}  {number}` else tostring(number)
		end,
		setColor = function(color: Color3)
			fill.BackgroundColor3 = color
		end,
		pulse = function()
			scale.Scale = 1.08
			Style.tween(scale, Theme.Tween.Pop, { Scale = 1 })
		end,
	}
end

return Bar
