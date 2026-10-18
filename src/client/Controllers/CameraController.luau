--!strict
-- Pardner camera: Roblox's default third-person camera, plus an over-the-shoulder aim mode while
-- the Aim input is held (the default camera already pans while the right mouse button is down).
-- The worm's underground camera arrives in Phase 6.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local InputController = require(script.Parent.InputController)
local MatchController = require(script.Parent.MatchController)
local PardnerMovementController = require(script.Parent.PardnerMovementController)

local Cam = PardnerConfig.Camera
local UNLOCKED_MAX_ZOOM = 1e5 -- lets min and max be set in either order

local CameraController = {}

local player = Players.LocalPlayer

local aiming = false
local aimAlpha = 0
local savedZoom: number? = nil
local zoomToken = 0

local function setZoomRange(min: number, max: number)
	player.CameraMaxZoomDistance = UNLOCKED_MAX_ZOOM
	player.CameraMinZoomDistance = min
	player.CameraMaxZoomDistance = max
end

local function setAiming(camera: Camera, state: boolean)
	aiming = state
	zoomToken += 1
	if state then
		if not savedZoom then
			savedZoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude
		end
		setZoomRange(Cam.AimZoom, Cam.AimZoom)
		return
	end

	-- Pin the zoom to where it was before aiming, then give the player the full range back.
	local restore = math.clamp(savedZoom or Cam.MaxZoom, Cam.MinZoom, Cam.MaxZoom)
	local token = zoomToken
	setZoomRange(restore, restore)
	task.delay(Cam.ZoomRestoreDelay, function()
		if zoomToken == token then
			savedZoom = nil
			setZoomRange(Cam.MinZoom, Cam.MaxZoom)
		end
	end)
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not camera or not humanoid or not root or not root:IsA("BasePart") then
		return
	end

	local wantsAim = InputController.isAimHeld() and humanoid.Health > 0 and MatchController.isPardner()
	if wantsAim ~= aiming then
		setAiming(camera, wantsAim)
	end

	local target = if aiming then 1 else 0
	aimAlpha += (target - aimAlpha) * (1 - math.exp(-Cam.AimLerpSpeed * dt))
	humanoid.CameraOffset = Cam.AimOffset * aimAlpha
	camera.FieldOfView = Cam.DefaultFov + (Cam.AimFov - Cam.DefaultFov) * aimAlpha

	-- While aiming the Pardner faces where the camera looks; while climbing they face the wall.
	local climbing = PardnerMovementController.isClimbing()
	humanoid.AutoRotate = not (aiming or climbing)
	if aiming and not climbing then
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.01 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
		end
	end
end

function CameraController.isAiming(): boolean
	return aiming
end

function CameraController.start()
	setZoomRange(Cam.MinZoom, Cam.MaxZoom)
	RunService.RenderStepped:Connect(update)
end

return CameraController
