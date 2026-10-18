--!strict
-- A labeled slider row: caption on the left, a track with a brass knob you drag (mouse or touch), and the
-- value on the right. Reports every change through onChanged.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Label = require(script.Parent.Label)
local Style = require(script.Parent.Style)

export type Options = {
	caption: string,
	min: number,
	max: number,
	step: number,
	value: number,
	format: (value: number) -> string,
	onChanged: (value: number) -> (),
	size: UDim2?,
	order: number?,
}

export type Slider = {
	frame: Frame,
	set: (value: number) -> (),
}

local Slider = {}

function Slider.new(parent: Instance, options: Options): Slider
	local colors = Theme.Colors

	local frame = Instance.new("Frame")
	frame.Name = options.caption
	frame.BackgroundTransparency = 1
	frame.Size = options.size or UDim2.fromScale(1, 0.18)
	frame.LayoutOrder = options.order or 0
	frame.ZIndex = 3
	frame.Parent = parent
	local minHeight = Instance.new("UISizeConstraint")
	minHeight.MinSize = Vector2.new(0, Theme.Sizes.MinTap)
	minHeight.Parent = frame

	Label.new(frame, {
		text = options.caption,
		font = Theme.Fonts.Heading,
		size = UDim2.fromScale(0.36, 0.7),
		position = UDim2.fromScale(0, 0.15),
		align = Enum.TextXAlignment.Left,
		maxTextSize = 22,
	}).ZIndex =
		4
	local valueLabel = Label.new(frame, {
		font = Theme.Fonts.Numbers,
		size = UDim2.fromScale(0.14, 0.7),
		position = UDim2.fromScale(1, 0.15),
		anchor = Vector2.new(1, 0),
		align = Enum.TextXAlignment.Right,
		maxTextSize = 22,
	})
	valueLabel.ZIndex = 4

	local track = Instance.new("TextButton")
	track.Name = "Track"
	track.Text = ""
	track.AutoButtonColor = false
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.fromScale(0.38, 0.5)
	track.Size = UDim2.fromScale(0.46, 0.22)
	track.BackgroundColor3 = colors.Track
	track.ZIndex = 4
	Style.corner(track, Theme.Corner.Pill)
	Style.stroke(track, colors.WoodDark, Theme.Stroke.Bar)
	track.Parent = frame
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = colors.Accent
	fill.Size = UDim2.fromScale(0.5, 1)
	fill.ZIndex = 5
	Style.corner(fill, Theme.Corner.Pill)
	fill.Parent = track
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.fromScale(0.5, 0.5)
	knob.Size = UDim2.fromScale(2.2, 2.2)
	knob.SizeConstraint = Enum.SizeConstraint.RelativeYY
	knob.BackgroundColor3 = colors.PaperLight
	knob.ZIndex = 6
	Style.corner(knob, Theme.Corner.Pill)
	Style.stroke(knob, colors.WoodDark, Theme.Stroke.Button)
	knob.Parent = track

	local value = options.value
	local function show()
		local share = (value - options.min) / (options.max - options.min)
		fill.Size = UDim2.fromScale(share, 1)
		knob.Position = UDim2.fromScale(share, 0.5)
		valueLabel.Text = options.format(value)
	end

	local function setFromX(x: number)
		local share = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local raw = options.min + share * (options.max - options.min)
		local snapped = math.clamp(math.round(raw / options.step) * options.step, options.min, options.max)
		if snapped ~= value then
			value = snapped
			show()
			options.onChanged(value)
		end
	end

	local dragging = false
	track.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local kind = input.UserInputType
		if dragging and (kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	show()
	return {
		frame = frame,
		set = function(newValue: number)
			value = math.clamp(newValue, options.min, options.max)
			show()
		end,
	}
end

return Slider
