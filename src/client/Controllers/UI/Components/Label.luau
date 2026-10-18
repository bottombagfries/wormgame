--!strict
-- A themed TextLabel: scaled text with size limits, transparent background.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Style = require(script.Parent.Style)

export type Options = {
	text: string?,
	font: Font?, -- default Theme.Fonts.Body
	color: Color3?, -- default Theme.Colors.Ink
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	align: Enum.TextXAlignment?,
	maxTextSize: number?,
	outline: boolean?, -- dark outline for light text drawn over the world
	order: number?,
	name: string?,
}

local Label = {}

function Label.new(parent: Instance, options: Options): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = options.name or "Label"
	label.BackgroundTransparency = 1
	label.Size = options.size or UDim2.fromScale(1, 1)
	label.Position = options.position or UDim2.new()
	label.AnchorPoint = options.anchor or Vector2.zero
	label.FontFace = options.font or Theme.Fonts.Body
	label.TextColor3 = options.color or Theme.Colors.Ink
	label.TextXAlignment = options.align or Enum.TextXAlignment.Center
	label.Text = options.text or ""
	label.LayoutOrder = options.order or 0
	Style.textLimits(label, options.maxTextSize)
	if options.outline then
		Style.stroke(label, Theme.Colors.Shadow, Theme.Stroke.Text, true)
	end
	label.Parent = parent
	return label
end

return Label
