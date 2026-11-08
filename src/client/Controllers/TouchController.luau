--!strict
-- Phone / tablet controls (only when InputController.isTouch()). Shows the button set for what the player
-- is right now — Pardner, Worm, Ghost or the mouth-escape minigame — and turns presses into the same named
-- actions the keyboard produces, so every other controller works unchanged. Pardners walk and jump with
-- Roblox's own touch stick and jump button; the worm and ghosts (no character, so Roblox's stick can't move
-- them) get this module's dynamic stick, which appears under the thumb on the left half of the screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local InputController = require(script.Parent.InputController)
local MatchController = require(script.Parent.MatchController)
local MinigameController = require(script.Parent.MinigameController)
local WormController = require(script.Parent.WormController)
local TouchControls = require(script.Parent.UI.TouchControls)

type Spec = TouchControls.ButtonSpec
type Mode = "None" | "Pardner" | "Worm" | "Ghost" | "Minigame"

local player = Players.LocalPlayer

-- Cluster layouts (positions are fractions of the bottom-right cluster). Pardner buttons stay clear of
-- the bottom-right corner, where Roblox's jump button sits.
local LAYOUTS: { [Mode]: { Spec } } = {
	None = {},
	Pardner = {
		{ action = "Interact", label = "Grab", x = 0.42, y = 0.66, size = 0.26, kind = "tap", accent = true },
		{ action = "Aim", label = "Aim", x = 0.72, y = 0.40, size = 0.24, kind = "toggle" },
		{ action = "Throw", label = "Throw", x = 0.44, y = 0.36, size = 0.26, kind = "tap", accent = true },
		{ action = "Sprint", label = "Run", x = 0.14, y = 0.84, size = 0.22, kind = "hold" },
		{ action = "UseKit", label = "Kit", x = 0.14, y = 0.56, size = 0.2, kind = "tap" },
		{ action = "UseHeld", label = "Use", x = 0.16, y = 0.28, size = 0.19, kind = "tap" },
		{ action = "StoreInBag", label = "Stow", x = 0.42, y = 0.1, size = 0.18, kind = "tap" },
		{ action = "Drop", label = "Drop", x = 0.66, y = 0.1, size = 0.18, kind = "tap" },
		{ action = "LetGo", label = "Let go", x = 0.9, y = 0.1, size = 0.18, kind = "tap" },
	},
	Worm = {
		{ action = "WormPounce", label = "Pounce", x = 0.8, y = 0.8, size = 0.34, kind = "tap", accent = true },
		{ action = "WormBurrow", label = "Burrow", x = 0.46, y = 0.86, size = 0.24, kind = "tap" },
		{ action = "WormSneak", label = "Sneak", x = 0.16, y = 0.86, size = 0.22, kind = "hold" },
		{ action = "WormSonar", label = "Sonar", x = 0.84, y = 0.44, size = 0.22, kind = "tap" },
		{ action = "WormSinkhole", label = "Sinkhole", x = 0.56, y = 0.56, size = 0.22, kind = "tap" },
		{ action = "WormAbility1", label = "1", x = 0.26, y = 0.56, size = 0.22, kind = "tap" },
		{ action = "WormAbility2", label = "2", x = 0.66, y = 0.22, size = 0.22, kind = "tap" },
	},
	Ghost = {
		{ action = "GhostPush", label = "Push", x = 0.78, y = 0.78, size = 0.3, kind = "hold", accent = true },
		{ action = "GhostUp", label = "Up", x = 0.46, y = 0.6, size = 0.22, kind = "hold" },
		{ action = "GhostDown", label = "Down", x = 0.46, y = 0.86, size = 0.22, kind = "hold" },
	},
	Minigame = {
		{ action = "ArrowUp", label = "↑", x = 0.5, y = 0.2, size = 0.28, kind = "tap" },
		{ action = "ArrowLeft", label = "←", x = 0.2, y = 0.5, size = 0.28, kind = "tap" },
		{ action = "ArrowRight", label = "→", x = 0.8, y = 0.5, size = 0.28, kind = "tap" },
		{ action = "ArrowDown", label = "↓", x = 0.5, y = 0.8, size = 0.28, kind = "tap" },
		{ action = "AutoEscape", label = "Auto", x = 0.5, y = 0.5, size = 0.2, kind = "tap", accent = true },
	},
}

local STICK_MODES: { [Mode]: boolean } = { Worm = true, Ghost = true }

local TouchController = {}

local hud: TouchControls.Hud
local mode: Mode = "None"
local stickInput: InputObject? = nil
local stickCenter = Vector2.zero

local function currentMode(): Mode
	if MinigameController.isActive() then
		return "Minigame"
	end
	local role = MatchController.getRole()
	if role == "Worm" then
		return if WormController.getLocalWorm() then "Worm" else "None"
	end
	if MatchController.isGhost() then
		return "Ghost"
	end
	if MatchController.isPardner() and player.Character then
		return "Pardner"
	end
	return "None"
end

local function onDown(spec: Spec)
	if spec.kind == "toggle" then
		InputController.toggle(spec.action)
	else
		InputController.press(spec.action)
	end
end

local function onUp(spec: Spec)
	if spec.kind ~= "toggle" then
		InputController.release(spec.action)
	end
end

local function setMode(newMode: Mode)
	-- Let go of everything the old buttons were holding.
	for _, spec in LAYOUTS[mode] do
		InputController.release(spec.action)
	end
	mode = newMode
	hud.setButtons(LAYOUTS[newMode], onDown, onUp)
	hud.setStickVisible(STICK_MODES[newMode] == true)
	stickInput = nil
	InputController.setVirtualMove(Vector3.zero)

	if newMode == "Worm" then
		for _, action in { "WormAbility1", "WormAbility2" } do
			local id = WormController.abilityForAction(action)
			local def = id and Abilities[id]
			local button = hud.getButton(action)
			if def and button then
				button.setText(def.displayName)
			end
		end
	end
end

-- Per frame: follow the mode, and show Throw only while aiming.
local function update()
	local wanted = currentMode()
	if wanted ~= mode then
		setMode(wanted)
	end
	if mode == "Pardner" then
		local aiming = InputController.isAimHeld()
		local throw = hud.getButton("Throw")
		local aim = hud.getButton("Aim")
		if throw then
			throw.button.Visible = aiming
		end
		if aim then
			aim.setText(if aiming then "Stop" else "Aim")
		end
	end
end

-- The stick: a touch on the left half plants it under the thumb; dragging pushes the knob.
local function onStickBegan(input: InputObject)
	if input.UserInputType ~= Enum.UserInputType.Touch or stickInput then
		return
	end
	stickInput = input
	stickCenter = Vector2.new(input.Position.X, input.Position.Y)
	hud.showStick(stickCenter, Vector2.zero)
end

local function onTouchMoved(input: InputObject)
	if input ~= stickInput then
		return
	end
	local radius = math.max(hud.showStick(stickCenter, Vector2.zero), 1)
	local delta = Vector2.new(input.Position.X, input.Position.Y) - stickCenter
	if delta.Magnitude > radius then
		delta = delta.Unit * radius
	end
	hud.showStick(stickCenter, delta)
	-- Screen down = backwards (+Z), the same convention as the keyboard move vector.
	InputController.setVirtualMove(Vector3.new(delta.X / radius, 0, delta.Y / radius))
end

local function onTouchEnded(input: InputObject)
	if input == stickInput then
		stickInput = nil
		hud.showStick(nil, nil)
		InputController.setVirtualMove(Vector3.zero)
	end
end

function TouchController.start()
	if not InputController.isTouch() then
		return
	end
	hud = TouchControls.create(player:WaitForChild("PlayerGui"))
	hud.stickZone.InputBegan:Connect(onStickBegan)
	UserInputService.TouchMoved:Connect(onTouchMoved)
	UserInputService.TouchEnded:Connect(onTouchEnded)
	RunService.RenderStepped:Connect(update)
end

return TouchController
