--!strict
-- A modal window: a dimming scrim, a titled Panel that pops in, and a close button on the banner.
-- Clicking the scrim also closes it. Put content in `modal.content`.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Button = require(script.Parent.Button)
local Panel = require(script.Parent.Panel)
local Style = require(script.Parent.Style)

export type Options = {
	name: string,
	title: string,
	size: UDim2?,
	aspect: number?, -- width / height
	minWidth: number?,
	displayOrder: number?,
}

export type Modal = {
	gui: ScreenGui,
	content: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	onClosed: (callback: () -> ()) -> (),
}

local SCRIM_TRANSPARENCY = 0.45
local CLOSE_SIZE = UDim2.fromScale(0.11, 0.62)
local SCREEN_GUTTER = 8 -- px kept clear on each side on very narrow screens

local Modal = {}

function Modal.new(parent: Instance, options: Options): Modal
	local gui = Style.screen(options.name, options.displayOrder or 30)
	gui.Enabled = false

	local scrim = Instance.new("TextButton")
	scrim.Name = "Scrim"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = Theme.Colors.Scrim
	scrim.BackgroundTransparency = SCRIM_TRANSPARENCY
	scrim.BorderSizePixel = 0
	scrim.Parent = gui

	local panel = Panel.new(gui, {
		name = "Window",
		title = options.title,
		size = options.size or UDim2.fromScale(0.5, 0.7),
	})
	Style.aspect(panel.frame, options.aspect or 1)
	-- A minimum width for readability, but never wider than the screen.
	local limits = Instance.new("UISizeConstraint")
	limits.Parent = panel.frame
	local function fitWidth()
		local screen = gui.AbsoluteSize.X
		if screen <= 0 then
			return
		end
		limits.MinSize = Vector2.new(math.min(options.minWidth or 320, math.max(screen - SCREEN_GUTTER * 2, 0)), 0)
		limits.MaxSize = Vector2.new(math.max(screen - SCREEN_GUTTER * 2, 1), math.huge)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitWidth)

	local closedCallbacks: { () -> () } = {}
	local modal: Modal

	local banner = panel.body:FindFirstChild("TitleBanner")
	if banner then
		local close = Button.new(banner, {
			name = "Close",
			text = "X",
			variant = "Danger",
			size = CLOSE_SIZE,
			position = UDim2.fromScale(0.97, 0.5),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				modal.close()
			end,
		})
		Style.aspect(close.button, 1)
		close.button.ZIndex = 6
	end
	scrim.Activated:Connect(function()
		modal.close()
	end)

	gui.Parent = parent
	fitWidth()

	modal = {
		gui = gui,
		content = panel.content,
		open = function()
			gui.Enabled = true
			fitWidth()
			panel.popIn()
		end,
		close = function()
			if not gui.Enabled then
				return
			end
			gui.Enabled = false
			for _, callback in closedCallbacks do
				callback()
			end
		end,
		isOpen = function()
			return gui.Enabled
		end,
		onClosed = function(callback: () -> ())
			table.insert(closedCallbacks, callback)
		end,
	}
	return modal
end

return Modal
