--!strict
-- Builds the phone controls: a cluster of action buttons bottom-right, one set per mode. Movement uses
-- Roblox's own touch stick. Layout only; TouchController decides the mode and what each button does.

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
}

local CLUSTER_SIZE = UDim2.fromScale(0.36, 0.62)
local CLUSTER_ASPECT = 0.95 -- width / height
local IDLE_TRANSPARENCY = 0.25 -- buttons rest a little see-through so they don't hide the game

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
	}
end

return TouchControls
