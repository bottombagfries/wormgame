--!strict
-- Phase 13 spectating, for anyone not in the current round (late joiners, AFK): the camera follows a living
-- Pardner's humanoid or a Worm's head; previous / next cycle through them. Purely local: it only moves this
-- client's camera. Stops by itself when the round ends or this player gets a role.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MatchController = require(script.Parent.MatchController)
local SpectateHud = require(script.Parent.UI.SpectateHud)

local WORMS_FOLDER = "Worms"

type Target = { key: string, name: string, role: string, subject: Instance }

local SpectateController = {}

local player = Players.LocalPlayer

local hud: SpectateHud.Hud
local spectating = false
local currentKey: string? = nil

-- Everyone worth watching right now, in a stable order (Pardners by name, then Worms).
local function targets(): { Target }
	local list: { Target } = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local alive = other:GetAttribute("Role") == "Pardner" and other:GetAttribute("Dead") ~= true
		if other ~= player and alive and humanoid and humanoid.Health > 0 then
			table.insert(
				list,
				{ key = `P{other.UserId}`, name = other.DisplayName, role = "Pardner", subject = humanoid }
			)
		end
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	local folder = Workspace:FindFirstChild(WORMS_FOLDER)
	for _, worm in if folder then folder:GetChildren() else {} do
		local owner = worm:GetAttribute("OwnerUserId")
		local head = worm:IsA("Model") and worm.PrimaryPart
		local ownerPlayer = if typeof(owner) == "number" then Players:GetPlayerByUserId(owner) else nil
		if head and ownerPlayer ~= player then
			local name = if ownerPlayer then ownerPlayer.DisplayName else worm.Name
			table.insert(list, { key = `W{owner}`, name = name, role = "Worm", subject = head })
		end
	end
	return list
end

local function canSpectate(): boolean
	return MatchController.getState().phase == "Playing" and MatchController.getRole() == "None"
end

local function restoreCamera()
	local camera = Workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
end

function SpectateController.stop()
	if not spectating then
		return
	end
	spectating = false
	currentKey = nil
	hud.setVisible(false)
	restoreCamera()
end

-- Moves `step` places through the target list (0 = stay on the current one if it's still valid).
local function cycle(step: number)
	local list = targets()
	if #list == 0 then
		currentKey = nil
		hud.setTarget("Nobody left to watch", nil)
		restoreCamera()
		return
	end
	local index = 1
	for candidate, target in list do
		if target.key == currentKey then
			index = candidate
			break
		end
	end
	index = (index - 1 + step) % #list + 1
	local target = list[index]
	currentKey = target.key
	hud.setTarget(target.name, target.role)
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraSubject = target.subject :: any
	end
end

function SpectateController.begin()
	if spectating or not canSpectate() then
		return
	end
	spectating = true
	hud.setVisible(true)
	cycle(0)
end

function SpectateController.isSpectating(): boolean
	return spectating
end

function SpectateController.canSpectate(): boolean
	return canSpectate()
end

function SpectateController.init()
	hud = SpectateHud.create(player:WaitForChild("PlayerGui"), {
		onPrevious = function()
			cycle(-1)
		end,
		onNext = function()
			cycle(1)
		end,
		onStop = SpectateController.stop,
	})

	RunService.RenderStepped:Connect(function()
		if not spectating then
			return
		end
		if not canSpectate() then
			SpectateController.stop()
			return
		end
		-- The watched player died, left or was eaten: move on to someone else.
		local valid = false
		for _, target in targets() do
			if target.key == currentKey then
				valid = true
				break
			end
		end
		if not valid then
			cycle(0)
		end
	end)
end

return SpectateController
