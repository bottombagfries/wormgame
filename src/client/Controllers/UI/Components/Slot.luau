--!strict
-- A square inventory / kit / ability slot: paper tile, key hint in the corner, item text, selected highlight,
-- and a vertical cooldown overlay with seconds remaining.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Label = require(script.Parent.Label)
local Style = require(script.Parent.Style)

export type Options = {
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	key: string?, -- e.g. "1", "T"
	order: number?,
	name: string?,
}

export type Slot = {
	frame: Frame,
	setItem: (text: string?) -> (),
	setSelected: (selected: boolean) -> (),
	setCooldown: (remaining: number, total: number) -> (),
	pop: () -> (),
}

local Slot = {}

function Slot.new(parent: Instance, options: Options): Slot
	local colors = Theme.Colors

	local frame = Instance.new("Frame")
	frame.Name = options.name or "Slot"
	frame.Size = options.size or UDim2.fromScale(Theme.Sizes.SlotSize, Theme.Sizes.SlotSize)
	frame.Position = options.position or UDim2.new()
	frame.AnchorPoint = options.anchor or Vector2.zero
	frame.BackgroundColor3 = colors.PaperDark
	frame.BorderSizePixel = 0
	frame.LayoutOrder = options.order or 0
	frame.ZIndex = 3
	Style.aspect(frame, 1)
	Style.corner(frame, Theme.Corner.Slot)
	local stroke = Style.stroke(frame, colors.WoodDark, Theme.Stroke.Slot)
	frame.Parent = parent

	local item = Label.new(frame, {
		name = "Item",
		font = Theme.Fonts.BodyBold,
		size = UDim2.fromScale(0.9, 0.6),
		position = UDim2.fromScale(0.5, 0.55),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 18,
	})
	item.ZIndex = 4
	item.TextWrapped = true

	local cooldown = Instance.new("Frame")
	cooldown.Name = "Cooldown"
	cooldown.AnchorPoint = Vector2.new(0, 1)
	cooldown.Position = UDim2.fromScale(0, 1)
	cooldown.Size = UDim2.fromScale(1, 0)
	cooldown.BackgroundColor3 = colors.Shadow
	cooldown.BackgroundTransparency = 0.35
	cooldown.BorderSizePixel = 0
	cooldown.ZIndex = 5
	Style.corner(cooldown, Theme.Corner.Slot)
	cooldown.Parent = frame
	local seconds = Label.new(frame, {
		name = "Seconds",
		font = Theme.Fonts.Numbers,
		color = colors.TextLight,
		size = UDim2.fromScale(0.8, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		outline = true,
	})
	seconds.ZIndex = 6

	if options.key then
		local key = Label.new(frame, {
			name = "Key",
			text = options.key,
			font = Theme.Fonts.Numbers,
			color = colors.TextLight,
			size = UDim2.fromScale(0.7, 0.28),
			position = UDim2.fromScale(0.04, 0.03),
			align = Enum.TextXAlignment.Left,
			outline = true,
		})
		key.ZIndex = 7
	end

	local scale = Style.scaler(frame)

	return {
		frame = frame,
		setItem = function(text: string?)
			item.Text = text or ""
			frame.BackgroundColor3 = if text then colors.Paper else colors.PaperDark
		end,
		setSelected = function(selected: boolean)
			stroke.Color = if selected then colors.Accent else colors.WoodDark
			stroke.Thickness = if selected then Theme.Stroke.Slot + 1 else Theme.Stroke.Slot
		end,
		setCooldown = function(remaining: number, total: number)
			local share = if total > 0 then math.clamp(remaining / total, 0, 1) else 0
			cooldown.Size = UDim2.fromScale(1, share)
			seconds.Text = if remaining > 0 then tostring(math.ceil(remaining)) else ""
		end,
		pop = function()
			scale.Scale = 1.15
			Style.tween(scale, Theme.Tween.Pop, { Scale = 1 })
		end,
	}
end

return Slot
