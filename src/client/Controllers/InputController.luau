--!strict
-- Turns raw input into named actions from Config/Keybinds. Other controllers ask this module
-- instead of reading keys themselves. Touch screens drive the same actions through press()/release()
-- (TouchController's buttons) and setVirtualMove() (its thumbstick, for the worm and ghosts).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local TOUCH_JUMP_DEBOUNCE = 0.25 -- JumpRequest repeats while the touch jump button is held

local InputController = {}

local jumpPressed: Signal.Signal<> = Signal.new()
local letGoPressed: Signal.Signal<> = Signal.new()

local actionPressed: Signal.Signal<string> = Signal.new() -- any action from Config/Keybinds, by name

InputController.actionPressed = actionPressed
InputController.jumpPressed = jumpPressed
InputController.letGoPressed = letGoPressed

local held: { [string]: boolean } = {}
local controls: any = nil -- the default PlayerModule's control module (keyboard, gamepad, touch)
local lastTouchJump = 0
local virtualMove = Vector3.zero -- TouchController's thumbstick (X = right, Z = back)

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

-- Same shape as getMoveVector, but straight from the Move* keybinds (or the touch thumbstick). Works
-- without a character.
function InputController.getRawMoveVector(): Vector3
	local x = (if held.MoveRight then 1 else 0) - (if held.MoveLeft then 1 else 0)
	local z = (if held.MoveBack then 1 else 0) - (if held.MoveForward then 1 else 0)
	local vector = Vector3.new(x, 0, z) + virtualMove
	return if vector.Magnitude > 1 then vector.Unit else vector
end

function InputController.setVirtualMove(vector: Vector3)
	virtualMove = vector
end

-- True on phones/tablets (or when Debug.ForceTouchControls is on for testing with a mouse).
function InputController.isTouch(): boolean
	local debug = GameConfig.Debug
	return UserInputService.TouchEnabled or (debug.Enabled and debug.ForceTouchControls == true)
end

-- On-screen buttons: hold `action` down / let it go, exactly like its key.
function InputController.press(action: string)
	if held[action] then
		return
	end
	held[action] = true
	actionPressed:fire(action)
	if action == "Jump" then
		jumpPressed:fire()
	elseif action == "LetGo" then
		letGoPressed:fire()
	end
end

function InputController.release(action: string)
	held[action] = nil
end

-- Flips a hold-style action (Aim on touch, where holding a button and steering is awkward).
function InputController.toggle(action: string)
	if held[action] then
		InputController.release(action)
	else
		InputController.press(action)
	end
end

function InputController.init()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	-- Roblox's touch jump button is "game processed", so InputBegan never sees it; climbing listens to
	-- jumpPressed, so forward the jump request on touch screens.
	UserInputService.JumpRequest:Connect(function()
		local now = os.clock()
		if InputController.isTouch() and now - lastTouchJump > TOUCH_JUMP_DEBOUNCE then
			lastTouchJump = now
			jumpPressed:fire()
		end
	end)
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
