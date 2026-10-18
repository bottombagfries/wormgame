--!strict
-- A notice-board panel: paper (or wood) fill, thick dark-wood stroke, rounded corners, hard drop shadow,
-- optional title banner. Put content in `panel.content`.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Label = require(script.Parent.Label)
local Style = require(script.Parent.Style)

export type Variant = "Paper" | "Wood"

export type Options = {
	size: UDim2,
	position: UDim2?,
	anchor: Vector2?,
	title: string?,
	variant: Variant?,
	name: string?,
}

export type Panel = {
	frame: Frame, -- layout root (size / position / constraints)
	body: Frame, -- the visible paper
	content: Frame,
	title: TextLabel?,
	setVisible: (visible: boolean) -> (),
	popIn: () -> (),
}

local TITLE_HEIGHT = 0.16 -- share of the panel's height

local Panel = {}

function Panel.new(parent: Instance, options: Options): Panel
	local wood = options.variant == "Wood"
	local colors = Theme.Colors

	-- `frame` is the layout root (size, position, constraints go here); `body` is the visible paper.
	local frame = Instance.new("Frame")
	frame.Name = options.name or "Panel"
	frame.Size = options.size
	frame.Position = options.position or UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = options.anchor or Vector2.new(0.5, 0.5)
	frame.ZIndex = 2
	frame.Parent = parent
	local body = Style.shadowed(frame, Theme.Corner.Panel)
	body.BackgroundColor3 = if wood then colors.Wood else colors.Paper
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, colors.WoodDark, Theme.Stroke.Panel)

	-- A faint top-lit gradient so the paper doesn't read as a flat box.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(225, 215, 200))
	gradient.Parent = body

	local title: TextLabel? = nil
	local contentTop = 0
	if options.title then
		local banner = Instance.new("Frame")
		banner.Name = "TitleBanner"
		banner.Size = UDim2.fromScale(1, TITLE_HEIGHT)
		banner.BackgroundColor3 = if wood then colors.WoodDark else colors.Wood
		banner.BorderSizePixel = 0
		banner.ZIndex = 3
		Style.corner(banner, Theme.Corner.Panel)
		banner.Parent = body
		title = Label.new(banner, {
			name = "Title",
			text = options.title,
			font = Theme.Fonts.Display,
			color = colors.TextLight,
			size = UDim2.fromScale(0.92, 0.8),
			position = UDim2.fromScale(0.5, 0.5),
			anchor = Vector2.new(0.5, 0.5),
			maxTextSize = Theme.Text.HeadingMax,
		});
		(title :: TextLabel).ZIndex = 4
		contentTop = TITLE_HEIGHT
	end

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromScale(0, contentTop)
	content.Size = UDim2.fromScale(1, 1 - contentTop)
	content.ZIndex = 3
	Style.padding(content, Theme.Padding.Panel)
	content.Parent = body

	local scale = Style.scaler(frame)

	local panel: Panel
	panel = {
		frame = frame,
		body = body,
		content = content,
		title = title,
		setVisible = function(visible: boolean)
			frame.Visible = visible
		end,
		popIn = function()
			frame.Visible = true
			scale.Scale = 0.85
			Style.tween(scale, Theme.Tween.Pop, { Scale = 1 })
		end,
	}
	return panel
end

return Panel
