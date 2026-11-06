--!strict
-- Builds the phone controls: a cluster of action buttons bottom-right (one set per mode) and a thumbstick
-- zone on the left half for the worm and ghosts (who have no character, so Roblox's own touch stick
-- doesn't show). Layout only; TouchController decides the mode and what each button does.

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
	stickZone: Frame,
	setButtons: (specs: { ButtonSpec }, onDown: (ButtonSpec) -> (), onUp: (ButtonSpec) -> ()) -> (),
	getButton: (action: string) -> Button.Button?,
	setStickVisible: (visible: boolean) -> (),
	showStick: (center: Vector2?, knobOffset: Vector2?) -> (),
	stickRadius: () -> number,
}

local CLUSTER_SIZE = UDim2.fromScale(0.36, 0.62)
local CLUSTER_ASPECT = 0.95 -- width / height
local STICK_SIZE = UDim2.fromScale(0.2, 0.2)
local STICK_HOME = UDim2.fromScale(0.16, 0.78)
local KNOB_FRACTION = 0.45
local IDLE_TRANSPARENCY = 0.25 -- buttons rest a little see-through so they don't hide the game

local TouchControls = {}

local function circle(parent: Instance, name: string, size: UDim2, color: Color3, transparency: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Parent = parent
	Style.corner(frame, Theme.Corner.Pill)
	Style.stroke(frame, Theme.Colors.Accent, Theme.Stroke.Button)
	Style.aspect(frame, 1)
	return frame
end

function TouchControls.create(parent: Instance): Hud
	local gui = Style.screen("TouchControls", 3)
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Parent = parent

	-- Left half: drag anywhere to steer. Active so the drag doesn't also turn the camera.
	local stickZone = Instance.new("Frame")
	stickZone.Name = "StickZone"
	stickZone.Size = UDim2.fromScale(0.45, 0.7)
	stickZone.Position = UDim2.fromScale(0, 0.3)
	stickZone.BackgroundTransparency = 1
	stickZone.Active = true
	stickZone.Visible = false
	stickZone.Parent = gui

	local base = circle(gui, "StickBase", STICK_SIZE, Theme.Colors.WoodDark, 0.5)
	base.Position = STICK_HOME
	base.Visible = false
	local knob = circle(base, "Knob", UDim2.fromScale(KNOB_FRACTION, KNOB_FRACTION), Theme.Colors.Accent, 0.2)
	knob.Position = UDim2.fromScale(0.5, 0.5)

	local cluster = Instance.new("Frame")
	cluster.Name = "Cluster"
	cluster.AnchorPoint = Vector2.new(1, 1)
	cluster.Position = UDim2.fromScale(0.99, 0.97)
	cluster.Size = CLUSTER_SIZE
	cluster.BackgroundTransparency = 1
	cluster.Parent = gui
	Style.aspect(cluster, CLUSTER_ASPECT)

	local buttons: { [string]: Button.Button } = {}
	local connections: { RBXScriptConnection } = {}

	return {
		gui = gui,
		stickZone = stickZone,
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
		setStickVisible = function(visible: boolean)
			stickZone.Visible = visible
			base.Visible = visible
		end,
		showStick = function(center: Vector2?, knobOffset: Vector2?)
			base.Position = if center then UDim2.fromOffset(center.X, center.Y) else STICK_HOME
			local offset = knobOffset or Vector2.zero
			knob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
		end,
		stickRadius = function(): number
			return base.AbsoluteSize.X / 2
		end,
	}
end

return TouchControls
