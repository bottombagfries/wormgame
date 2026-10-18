--!strict
-- A themed button: grows on hover, squashes on press, plays the click / hover / error hooks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Style = require(script.Parent.Style)
local UiSound = require(script.Parent.UiSound)

export type Variant = "Accent" | "Paper" | "Danger" | "Good" | "Wood"

export type Options = {
	text: string,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	variant: Variant?,
	order: number?,
	name: string?,
	onClick: (() -> ())?,
}

export type Button = {
	button: TextButton,
	setText: (text: string) -> (),
	setEnabled: (enabled: boolean) -> (),
	setVariant: (variant: Variant) -> (),
	destroy: () -> (),
}

local Button = {}

local function colorsFor(variant: Variant): (Color3, Color3)
	local c = Theme.Colors
	if variant == "Paper" then
		return c.PaperLight, c.Ink
	elseif variant == "Danger" then
		return c.Danger, c.TextLight
	elseif variant == "Good" then
		return c.Good, c.TextLight
	elseif variant == "Wood" then
		return c.Wood, c.TextLight
	end
	return c.Accent, c.Ink
end

function Button.new(parent: Instance, options: Options): Button
	local variant: Variant = options.variant or "Accent"
	local enabled = true

	local button = Instance.new("TextButton")
	button.Name = options.name or "Button"
	button.AutoButtonColor = false
	button.Size = options.size or UDim2.fromScale(0.4, 0.15)
	button.Position = options.position or UDim2.new()
	button.AnchorPoint = options.anchor or Vector2.zero
	button.LayoutOrder = options.order or 0
	button.FontFace = Theme.Fonts.Heading
	button.Text = options.text
	button.TextWrapped = false
	button.BorderSizePixel = 0
	button.ZIndex = 4
	Style.textLimits(button, 28)
	Style.corner(button, Theme.Corner.Button)
	Style.minHeight(button, Theme.Sizes.MinTap)
	local stroke = Style.stroke(button, Theme.Colors.WoodDark, Theme.Stroke.Button)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = Theme.Padding.Button
	padding.PaddingRight = Theme.Padding.Button
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = button
	local scale = Style.scaler(button)
	button.Parent = parent

	local function paint()
		local fill, text = colorsFor(variant)
		button.BackgroundColor3 = if enabled then fill else Theme.Colors.Disabled
		button.TextColor3 = text
		stroke.Transparency = if enabled then 0 else 0.5
	end
	paint()

	local hovering = false
	local connections = {
		button.MouseEnter:Connect(function()
			hovering = true
			if enabled then
				UiSound.play(Theme.Sounds.Hover)
				Style.tween(scale, Theme.Tween.Fast, { Scale = Theme.Button.HoverScale })
			end
		end),
		button.MouseLeave:Connect(function()
			hovering = false
			Style.tween(scale, Theme.Tween.Fast, { Scale = 1 })
		end),
		button.MouseButton1Down:Connect(function()
			if enabled then
				Style.tween(scale, Theme.Tween.Fast, { Scale = Theme.Button.PressScale })
			end
		end),
		button.MouseButton1Up:Connect(function()
			Style.tween(scale, Theme.Tween.Fast, { Scale = if hovering then Theme.Button.HoverScale else 1 })
		end),
		button.Activated:Connect(function()
			if not enabled then
				UiSound.play(Theme.Sounds.Error)
				return
			end
			UiSound.play(Theme.Sounds.Click)
			if options.onClick then
				options.onClick()
			end
		end),
	}

	return {
		button = button,
		setText = function(text: string)
			button.Text = text
		end,
		setEnabled = function(value: boolean)
			enabled = value
			paint()
		end,
		setVariant = function(value: Variant)
			variant = value
			paint()
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			button:Destroy()
		end,
	}
end

return Button
