--!strict
-- Builds the phone controls: a cluster of action buttons bottom-right, one set per mode, and a dynamic
-- thumbstick for the worm and ghosts (Roblox's own touch stick only drives players who have a character).
-- The stick appears under the thumb anywhere on the left half. Layout only; TouchController decides the
-- mode and what each button does.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local Button = require(script.Parent.Components.Button)
local Style = require(script.Parent.Components.Style)

-- kind: "tap" fires once, "hold" stays down while the finger is down, "toggle" flips on each tap.
export type ButtonSpec = {
	action: string,
	label: string,
	x: number, -- center, as a fraction of the cluster
	y: number,
	size: number, -- width as a fraction of the cluster
	kind: "tap" | "hold" | "toggle",
	accent: boolean?,
}

export type Hud = {
	gui: ScreenGui,
	setButtons: (specs: { ButtonSpec }, onDown: (ButtonSpec) -> (), onUp: (ButtonSpec) -> ()) -> (),
	getButton: (action: string) -> Button.Button?,
	stickZone: Frame,
	setStickVisible: (visible: boolean) -> (),
	-- Shows the stick at a screen position (InputObject.Position) with the knob pushed by `offset` px; nil
	-- hides it. Returns the stick's radius in px.
	showStick: (screenPosition: Vector2?, offset: Vector2?) -> number,
}

local CLUSTER_SIZE = UDim2.fromScale(0.34, 0.58)
local CLUSTER_ASPECT = 0.95 -- width / height
local IDLE_TRANSPARENCY = 0.25 -- buttons rest a little see-through so they don't hide the game
local STICK_SIZE = UDim2.fromScale(0.3, 0.3) -- of the screen's short side (square), like Roblox's stick
local KNOB_FRACTION = 0.42

local function circle(parent: Instance, name: string, size: UDim2, color: Color3, transparency: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Parent = parent
	Style.corner(frame, Theme.Corner.Pill)
	Style.aspect(frame, 1)
	return frame
end

local TouchControls = {}

function TouchControls.create(parent: Instance): Hud
	local gui = Style.screen("TouchControls", 3)
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Parent = parent

	local cluster = Instance.new("Frame")
	cluster.Name = "Cluster"
	cluster.AnchorPoint = Vector2.new(1, 1)
	cluster.Position = UDim2.fromScale(0.99, 0.97)
	cluster.Size = CLUSTER_SIZE
	cluster.BackgroundTransparency = 1
	cluster.Parent = gui
	Style.aspect(cluster, CLUSTER_ASPECT)

	-- Left half: touch anywhere to steer. Active so the drag doesn't also turn the camera.
	local stickZone = Instance.new("Frame")
	stickZone.Name = "StickZone"
	stickZone.Size = UDim2.fromScale(0.5, 0.75)
	stickZone.Position = UDim2.fromScale(0, 0.25)
	stickZone.BackgroundTransparency = 1
	stickZone.Active = true
	stickZone.Visible = false
	stickZone.Parent = gui

	-- The stick lives in a full-screen layer; its position is worked out against that layer's own
	-- AbsolutePosition, so it sits exactly under the finger whatever the insets are.
	local layer = Instance.new("Frame")
	layer.Name = "StickLayer"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.Parent = gui
	local base = circle(layer, "StickBase", STICK_SIZE, Theme.Colors.Shadow, 0.6)
	base.Visible = false
	Style.stroke(base, Theme.Colors.PaperLight, Theme.Stroke.Button)
	local knob = circle(base, "Knob", UDim2.fromScale(KNOB_FRACTION, KNOB_FRACTION), Theme.Colors.PaperLight, 0.25)
	knob.Position = UDim2.fromScale(0.5, 0.5)

	local buttons: { [string]: Button.Button } = {}
	local connections: { RBXScriptConnection } = {}

	return {
		gui = gui,
		setButtons = function(specs: { ButtonSpec }, onDown: (ButtonSpec) -> (), onUp: (ButtonSpec) -> ())
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			for _, button in buttons do
				button.destroy()
			end
			table.clear(buttons)
			for _, spec in specs do
				local button = Button.new(cluster, {
					name = spec.action,
					text = spec.label,
					size = UDim2.fromScale(spec.size, spec.size),
					position = UDim2.fromScale(spec.x, spec.y),
					anchor = Vector2.new(0.5, 0.5),
					variant = if spec.accent then "Accent" else "Wood",
				})
				local frame = button.button
				frame.BackgroundTransparency = IDLE_TRANSPARENCY
				Style.aspect(frame, 1)
				-- Press and release (the component only reports clicks), so hold actions work.
				table.insert(
					connections,
					frame.InputBegan:Connect(function(input)
						local kind = input.UserInputType
						if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
							onDown(spec)
						end
					end)
				)
				table.insert(
					connections,
					frame.InputEnded:Connect(function(input)
						local kind = input.UserInputType
						if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
							onUp(spec)
						end
					end)
				)
				buttons[spec.action] = button
			end
		end,
		getButton = function(action: string): Button.Button?
			return buttons[action]
		end,
		stickZone = stickZone,
		setStickVisible = function(visible: boolean)
			stickZone.Visible = visible
			if not visible then
				base.Visible = false
			end
		end,
		showStick = function(screenPosition: Vector2?, offset: Vector2?): number
			if not screenPosition then
				base.Visible = false
				return base.AbsoluteSize.X / 2
			end
			local localPos = screenPosition - layer.AbsolutePosition
			base.Position = UDim2.fromOffset(localPos.X, localPos.Y)
			base.Visible = true
			local push = offset or Vector2.zero
			knob.Position = UDim2.new(0.5, push.X, 0.5, push.Y)
			return base.AbsoluteSize.X / 2
		end,
	}
end

return TouchControls
