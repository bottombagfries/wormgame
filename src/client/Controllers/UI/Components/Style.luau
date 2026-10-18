--!strict
-- Small builders every UI component uses: corners, strokes, padding, text limits, drop shadows, tweens.
-- All values come from Config/Theme.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local Style = {}

function Style.corner(parent: GuiObject, radius: UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
	return corner
end

function Style.stroke(parent: GuiObject, color: Color3, thickness: number, contextual: boolean?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = if contextual then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

function Style.padding(parent: GuiObject, amount: UDim): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = amount
	padding.PaddingBottom = amount
	padding.PaddingLeft = amount
	padding.PaddingRight = amount
	padding.Parent = parent
	return padding
end

function Style.textLimits(label: TextLabel | TextButton, maxSize: number?)
	label.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = Theme.Text.MinSize
	constraint.MaxTextSize = maxSize or Theme.Text.MaxSize
	constraint.Parent = label
end

function Style.aspect(parent: GuiObject, ratio: number)
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = ratio
	constraint.Parent = parent
end

function Style.minHeight(parent: GuiObject, pixels: number)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(0, pixels)
	constraint.Parent = parent
end

-- A hard drop shadow without fighting layout constraints: `root` (sized and positioned by the caller, may
-- carry aspect / size constraints) gets two full-size children, a dark Shadow offset down-right and the Body
-- on top. Returns the body, which is where the visible styling goes.
function Style.shadowed(root: GuiObject, radius: UDim): Frame
	root.BackgroundTransparency = 1
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = Theme.Shadow.Offset
	shadow.BackgroundColor3 = Theme.Colors.Shadow
	shadow.BackgroundTransparency = Theme.Shadow.Transparency
	shadow.BorderSizePixel = 0
	shadow.ZIndex = root.ZIndex
	Style.corner(shadow, radius)
	shadow.Parent = root

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.fromScale(1, 1)
	body.BorderSizePixel = 0
	body.ZIndex = root.ZIndex + 1
	body.Parent = root
	return body
end

function Style.tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

-- A UIScale on `gui` (created once) so components can pop / squash without touching Size.
function Style.scaler(gui: GuiObject): UIScale
	local existing = gui:FindFirstChildOfClass("UIScale")
	if existing then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	return scale
end

-- Sizes a horizontal row of `count` square slots so they always fit across `widthShare` of the screen:
-- each slot is as tall as `heightShare` of the screen, capped at [minPx, maxPx] and shrunk if too wide.
function Style.fitRow(
	row: GuiObject,
	gui: ScreenGui,
	count: number,
	gap: number,
	heightShare: number,
	minPx: number,
	maxPx: number
)
	local screen = gui.AbsoluteSize
	local widthShare = row.Size.X.Scale
	local wanted = math.clamp(screen.Y * heightShare, minPx, maxPx)
	local fits = if count > 0 then (screen.X * widthShare - gap * (count - 1)) / count else wanted
	row.Size = UDim2.new(widthShare, 0, 0, math.floor(math.min(wanted, fits)))
end

-- A ScreenGui set up the same way everywhere: safe-area insets, no reset on spawn.
function Style.screen(name: string, displayOrder: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = displayOrder or 0
	return gui
end

return Style
