--!strict
-- Turns raw input into named actions from Config/Keybinds. Other controllers ask this module
-- instead of reading keys themselves. Mobile comes later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local InputController = {}

local jumpPressed: Signal.Signal<> = Signal.new()
local letGoPressed: Signal.Signal<> = Signal.new()

local actionPressed: Signal.Signal<string> = Signal.new() -- any action from Config/Keybinds, by name

InputController.actionPressed = actionPressed
InputController.jumpPressed = jumpPressed
InputController.letGoPressed = letGoPressed

local held: { [string]: boolean } = {}
local controls: any = nil -- the default PlayerModule's control module (keyboard, gamepad, touch)

local function matches(input: InputObject, action: string): boolean
	local binds = Keybinds[action]
	if not binds then
		return false
	end
	for _, bind in binds do
		if (input.KeyCode :: any) == bind or (input.UserInputType :: any) == bind then
			return true
		end
	end
	return false
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	for action in Keybinds do
		if matches(input, action) then
			held[action] = true
			actionPressed:fire(action)
		end
	end
	if matches(input, "Jump") then
		jumpPressed:fire()
	end
	if matches(input, "LetGo") then
		letGoPressed:fire()
	end
end

local function onInputEnded(input: InputObject)
	for action in Keybinds do
		if matches(input, action) then
			held[action] = nil
		end
	end
end

function InputController.isHeld(action: string): boolean
	return held[action] == true
end

function InputController.isSprintHeld(): boolean
	return held.Sprint == true
end

function InputController.isAimHeld(): boolean
	return held.Aim == true
end

-- X = right, Z = back (so forward is -Z), same as the default control module.
function InputController.getMoveVector(): Vector3
	if controls then
		return controls:GetMoveVector()
	end
	return InputController.getRawMoveVector()
end

-- Same shape as getMoveVector, but straight from the Move* keybinds. Works without a character.
function InputController.getRawMoveVector(): Vector3
	local x = (if held.MoveRight then 1 else 0) - (if held.MoveLeft then 1 else 0)
	local z = (if held.MoveBack then 1 else 0) - (if held.MoveForward then 1 else 0)
	local vector = Vector3.new(x, 0, z)
	return if vector.Magnitude > 0 then vector.Unit else vector
end

function InputController.init()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	UserInputService.WindowFocusReleased:Connect(function()
		table.clear(held)
	end)
end

function InputController.start()
	task.spawn(function()
		-- Roblox used to copy PlayerModule into PlayerScripts; newer builds leave it in StarterPlayer.
		local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
		local playerModule = playerScripts:FindFirstChild("PlayerModule")
			or StarterPlayer:FindFirstChild("PlayerModule")
		while not playerModule do
			task.wait(0.25)
			playerModule = playerScripts:FindFirstChild("PlayerModule") or StarterPlayer:FindFirstChild("PlayerModule")
		end
		-- The newer PlayerModule has no GetControls; getMoveVector then falls back to the raw keybinds.
		local api = (require :: any)(playerModule)
		if type(api.GetControls) == "function" then
			controls = api:GetControls()
		end
	end)
end

return InputController
