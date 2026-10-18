--!strict
-- Builds the safe keypad (§10.7): a display, digits 0-9, Clear, Enter and Close.
-- Layout only; SafeController opens it and sends the code. TODO(asset): replace with real UI art.

export type Screen = {
	gui: ScreenGui,
	open: () -> (),
	close: () -> (),
}

local MAX_DIGITS = 12
local BUTTON = 64
local GAP = 8
local PANEL_SIZE = UDim2.fromOffset(BUTTON * 3 + GAP * 4, BUTTON * 5 + GAP * 7 + 40)
local BACK_COLOR = Color3.fromRGB(35, 35, 40)
local BUTTON_COLOR = Color3.fromRGB(80, 80, 90)
local ENTER_COLOR = Color3.fromRGB(70, 150, 80)
-- Keypad rows, top to bottom.
local KEYS = { { "1", "2", "3" }, { "4", "5", "6" }, { "7", "8", "9" }, { "Clear", "0", "Enter" } }

local KeypadScreen = {}

local function makeButton(parent: Instance, text: string, position: UDim2, size: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 24
	button.Text = text
	button.Parent = parent
	return button
end

function KeypadScreen.create(parent: Instance, onSubmit: (code: string) -> ()): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "KeypadScreen"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 7
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = PANEL_SIZE
	panel.BackgroundColor3 = BACK_COLOR
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 32)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 22
	title.Text = "Safe keypad"
	title.Parent = panel

	local display = Instance.new("TextLabel")
	display.Name = "Display"
	display.Position = UDim2.fromOffset(GAP, 40)
	display.Size = UDim2.new(1, -GAP * 2, 0, BUTTON - GAP)
	display.BackgroundColor3 = Color3.new(0, 0, 0)
	display.BorderSizePixel = 0
	display.TextColor3 = Color3.fromRGB(120, 255, 120)
	display.Font = Enum.Font.Code
	display.TextSize = 32
	display.Text = ""
	display.Parent = panel

	local entered = ""
	local function show()
		display.Text = entered
	end

	for row, keys in KEYS do
		for column, key in keys do
			local position = UDim2.fromOffset(GAP + (column - 1) * (BUTTON + GAP), 40 + row * (BUTTON + GAP))
			local color = if key == "Enter" then ENTER_COLOR else BUTTON_COLOR
			local button = makeButton(panel, key, position, UDim2.fromOffset(BUTTON, BUTTON), color)
			button.Activated:Connect(function()
				if key == "Clear" then
					entered = ""
				elseif key == "Enter" then
					if #entered > 0 then
						onSubmit(entered)
					end
					entered = ""
				elseif #entered < MAX_DIGITS then
					entered ..= key
				end
				show()
			end)
		end
	end

	local closeButton = makeButton(
		panel,
		"Close",
		UDim2.new(0, GAP, 1, -(BUTTON / 2 + GAP)),
		UDim2.new(1, -GAP * 2, 0, BUTTON / 2),
		BUTTON_COLOR
	)
	closeButton.Activated:Connect(function()
		gui.Enabled = false
	end)

	gui.Parent = parent

	return {
		gui = gui,
		open = function()
			entered = ""
			show()
			gui.Enabled = true
		end,
		close = function()
			gui.Enabled = false
		end,
	}
end

return KeypadScreen
