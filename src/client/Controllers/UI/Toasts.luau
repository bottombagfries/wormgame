--!strict
-- Phase 13 toasts: a stack of short event notes under the top-center timer ("X was eaten", "Objective
-- complete", "Sundown!"), each with a stripe in its kind's color, sliding in and fading out; plus a single
-- personal hint line above the inventory. Layout only; ToastController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Types = require(ReplicatedStorage.Shared.Types)
local Label = require(script.Parent.Components.Label)
local Style = require(script.Parent.Components.Style)

export type Screen = {
	gui: ScreenGui,
	push: (text: string, kind: Types.ToastKind) -> (),
	hint: (text: string) -> (),
	setCompact: (compact: boolean) -> (), -- narrow screens: toasts stack up from mid-screen instead
}

local TOAST_HEIGHT = 0.05
local BIG_HEIGHT = 0.08

local Toasts = {}

local function kindColor(kind: Types.ToastKind): Color3
	local colors = Theme.Colors
	if kind == "Kill" then
		return colors.Danger
	elseif kind == "Objective" then
		return colors.Good
	elseif kind == "Sundown" then
		return colors.Warning
	elseif kind == "Revive" then
		return colors.Pardner
	elseif kind == "Event" then
		return colors.Accent
	end
	return colors.InkSoft
end

function Toasts.create(parent: Instance): Screen
	local colors = Theme.Colors
	local gui = Style.screen("Toasts", 25)

	local stack = Instance.new("Frame")
	stack.Name = "Stack"
	stack.BackgroundTransparency = 1
	stack.AnchorPoint = Vector2.new(0.5, 0)
	stack.Position = UDim2.fromScale(0.5, 0.1)
	stack.Size = UDim2.fromScale(0.44, 0.4)
	stack.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(280, 0)
	limits.Parent = stack
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = stack

	local hintLabel = Label.new(gui, {
		name = "Hint",
		font = Theme.Fonts.BodyBold,
		color = colors.PaperLight,
		size = UDim2.fromScale(0.6, 0.035),
		position = UDim2.fromScale(0.5, 0.74),
		anchor = Vector2.new(0.5, 1),
		maxTextSize = 22,
		outline = true,
	})
	local hintToken = 0

	gui.Parent = parent

	local order = 0
	local live: { Frame } = {}

	local function remove(toast: Frame)
		local index = table.find(live, toast)
		if index then
			table.remove(live, index)
		end
		toast:Destroy()
	end

	return {
		gui = gui,
		push = function(text: string, kind: Types.ToastKind)
			local big = kind == "Sundown" or kind == "Objective"
			order += 1

			local root = Instance.new("Frame")
			root.Name = `Toast{order}`
			root.LayoutOrder = order
			root.Size = UDim2.fromScale(if big then 1 else 0.85, if big then BIG_HEIGHT / 0.4 else TOAST_HEIGHT / 0.4)
			root.BackgroundTransparency = 1
			root.Parent = stack
			local minHeight = Instance.new("UISizeConstraint")
			minHeight.MinSize = Vector2.new(0, if big then 50 else 34)
			minHeight.Parent = root

			local body = Instance.new("CanvasGroup")
			body.Name = "Body"
			body.Size = UDim2.fromScale(1, 1)
			body.BackgroundColor3 = if kind == "Sundown" then colors.WoodDark else colors.Paper
			body.BorderSizePixel = 0
			body.GroupTransparency = 1
			Style.corner(body, Theme.Corner.Button)
			body.Parent = root
			local stroke = Style.stroke(body, colors.WoodDark, Theme.Stroke.Button)

			local stripe = Instance.new("Frame")
			stripe.Name = "Stripe"
			stripe.Size = UDim2.new(0, 8, 1, 0)
			stripe.BackgroundColor3 = kindColor(kind)
			stripe.BorderSizePixel = 0
			stripe.Parent = body

			local label = Label.new(body, {
				text = text,
				font = if big then Theme.Fonts.Display else Theme.Fonts.BodyBold,
				color = if kind == "Sundown" then colors.Warning else colors.Ink,
				size = UDim2.new(1, -28, 0.78, 0),
				position = UDim2.new(0.5, 4, 0.5, 0),
				anchor = Vector2.new(0.5, 0.5),
				maxTextSize = if big then 34 else 22,
			})
			label.TextWrapped = true

			table.insert(live, root)
			while #live > Theme.Toast.MaxVisible do
				remove(live[1])
			end

			-- Slide down into place and fade in, then fade out and go.
			body.Position = UDim2.fromScale(0, -Theme.Toast.SlideOffset * 4)
			Style.tween(body, Theme.Tween.Pop, { Position = UDim2.fromScale(0, 0), GroupTransparency = 0 })
			if big then
				stroke.Color = kindColor(kind)
				stroke.Thickness = Theme.Stroke.Panel
			end
			task.delay(if big then Theme.Toast.BigSeconds else Theme.Toast.Seconds, function()
				if root.Parent then
					local fade = Style.tween(body, Theme.Tween.Normal, { GroupTransparency = 1 })
					fade.Completed:Wait()
					remove(root)
				end
			end)
		end,
		setCompact = function(compact: boolean)
			stack.AnchorPoint = if compact then Vector2.new(0.5, 1) else Vector2.new(0.5, 0)
			stack.Position = if compact then UDim2.fromScale(0.5, 0.6) else UDim2.fromScale(0.5, 0.1)
			layout.VerticalAlignment = if compact then Enum.VerticalAlignment.Bottom else Enum.VerticalAlignment.Top
			hintLabel.Position = if compact then UDim2.fromScale(0.5, 0.65) else UDim2.fromScale(0.5, 0.74)
		end,
		hint = function(text: string)
			hintToken += 1
			local token = hintToken
			hintLabel.Text = text
			task.delay(Theme.Toast.HintSeconds, function()
				if hintToken == token then
					hintLabel.Text = ""
				end
			end)
		end,
	}
end

return Toasts
