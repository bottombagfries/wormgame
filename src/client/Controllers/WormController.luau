--!strict
-- Client side of the Worm (§8.2).
--  * Every client: draws each worm's body (segments chain-following the head) and the dirt mound
--    above a burrowed worm. These are local visuals only; just the head replicates.
--  * The worm's own client: steers the head (which it has network ownership of), keeps it at the
--    right height for its mode, moves the camera, and sends ability intents (Request_Ability).
--  * Every client: plays ability effects (Fx_Ability → shared/AbilityBehaviors/<id>.clientFx).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local SettingsConfig = require(ReplicatedStorage.Shared.Config.Settings)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local InputController = require(script.Parent.InputController)
local MatchController = require(script.Parent.MatchController)
local SettingsController = require(script.Parent.SettingsController)

local Tags = TagDefs.Tags
local UNLOCKED_MAX_ZOOM = 1e5 -- lets min and max zoom be set in either order
local LAUNCH_GRACE = 0.5 -- seconds the client treats itself as airborne after a launch, until Mode catches up
local MOUND_MOVING_SPEED = 2 -- studs/s; a still worm shows no mound to Pardners
local PICK_ACTIONS: { [string]: number } = { WormAbility1 = 1, WormAbility2 = 2 } -- keys for the chosen two

type Visual = {
	segments: { Model },
	radii: { number },
	positions: { Vector3 },
	mound: Part,
}

local WormController = {}

local player = Players.LocalPlayer

local visuals: { [Instance]: Visual } = {}
local fxFolder: Folder
local cameraAnchor: Part
local usingMouthView = false -- the Settings mouth view is applied to the camera
local abilityRemote: RemoteEvent
local launchUntil = 0
local sentSneak = false
local wasWorm = false

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.RespectCanCollide = true

local function flatUnit(vector: Vector3): Vector3?
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else nil
end

local function makeLocalPart(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy() -- greybox label: one on the head is enough
		end
	end
end

-- Body visuals -----------------------------------------------------------------------------------

local function createVisual(worm: Model, head: BasePart): Visual
	local visual: Visual = { segments = {}, radii = {}, positions = {}, mound = Instance.new("Part") }

	-- The head is segment 1; the rest shrink toward the tail.
	for index = 1, WormConfig.Segments - 1 do
		local segment = AssetService.get("WormSegment") -- TODO(asset): WormSegment
		segment:ScaleTo(WormConfig.SegmentShrink ^ (index - 1))
		makeLocalPart(segment)
		segment:PivotTo(head.CFrame)
		segment.Parent = fxFolder
		table.insert(visual.segments, segment)
		table.insert(visual.radii, segment:GetExtentsSize().X / 2)
		table.insert(visual.positions, head.Position)
	end

	-- TODO(asset): rumble particles / sound instead of a flat disc
	local mound = visual.mound
	mound.Name = "WormMound"
	mound.Shape = Enum.PartType.Cylinder
	mound.Size = WormConfig.MoundSize
	mound.Color = WormConfig.MoundColor
	mound.Material = Enum.Material.Sand
	mound.Anchored = true
	mound.CanCollide = false
	mound.CanQuery = false
	mound.CanTouch = false
	mound.Transparency = 1
	mound.Parent = fxFolder

	visuals[worm] = visual
	return visual
end

local function destroyVisual(worm: Instance)
	local visual = visuals[worm]
	if visual then
		visuals[worm] = nil
		for _, segment in visual.segments do
			segment:Destroy()
		end
		visual.mound:Destroy()
	end
end

local function updateVisual(worm: Model, head: BasePart, visual: Visual)
	-- Chain-follow: each segment is dragged to a fixed distance behind the one in front of it.
	local previous = head.Position
	local previousRadius = head.Size.X / 2
	for index, segment in visual.segments do
		local radius = visual.radii[index]
		local spacing = (previousRadius + radius) * WormConfig.SegmentSpacing
		local offset = visual.positions[index] - previous
		local position = if offset.Magnitude > 0.01
			then previous + offset.Unit * spacing
			else previous - Vector3.yAxis * spacing
		visual.positions[index] = position
		segment:PivotTo(CFrame.new(position))
		previous, previousRadius = position, radius
	end

	-- Mound: worms always see it; Pardners only while the worm is moving and not sneaking.
	local showMound = false
	local sandY: number? = nil
	if worm:GetAttribute("Mode") == "Underground" then
		sandY = Ground.sandBelow(head.Position)
		local moving = head.AssemblyLinearVelocity.Magnitude > MOUND_MOVING_SPEED
		-- Stealth (§12) hides the tremors as well as sneaking does.
		local stealthUntil = worm:GetAttribute("StealthUntil")
		local stealthy = typeof(stealthUntil) == "number" and Workspace:GetServerTimeNow() < stealthUntil
		local quiet = worm:GetAttribute("Sneaking") == true or stealthy
		showMound = MatchController.getRole() == "Worm" or (moving and not quiet)
	end
	if showMound and sandY then
		visual.mound.CFrame = CFrame.new(head.Position.X, sandY, head.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
		visual.mound.Transparency = 0
	else
		visual.mound.Transparency = 1
	end
end

-- Steering the local worm ------------------------------------------------------------------------

-- Something solid right in front of the head (above ground only).
local function isBlocked(position: Vector3, direction: Vector3, radius: number): boolean
	local ignore: { Instance } = { fxFolder }
	for _, name in { "Items", "Worms" } do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	wallParams.FilterDescendantsInstances = ignore
	local result = Workspace:Raycast(position, direction * (radius + WormConfig.WallProbe), wallParams)
	if not result then
		return false
	end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	return not (model and model:FindFirstChildOfClass("Humanoid"))
end

local function control(worm: Model, head: BasePart, camera: Camera)
	local drive = head:FindFirstChild("Drive")
	local align = head:FindFirstChild("Align")
	if not drive or not drive:IsA("LinearVelocity") or not align or not align:IsA("AlignOrientation") then
		return
	end

	local mode = worm:GetAttribute("Mode")
	local position = head.Position
	local radius = head.Size.Y / 2

	local sneaking = InputController.isHeld("WormSneak")
	if sneaking ~= sentSneak then
		sentSneak = sneaking
		abilityRemote:FireServer("Sneak", { state = sneaking })
	end

	if mode == "Airborne" or os.clock() < launchUntil then
		-- Ballistic: gravity does the work.
		drive.Enabled = false
		local velocity = head.AssemblyLinearVelocity
		if velocity.Magnitude > 1 then
			align.CFrame = CFrame.lookAt(Vector3.zero, velocity)
		end
		-- The head passes through the ground; don't sink forever while the server confirms the landing.
		local sandY = Ground.sandBelow(position)
		if sandY and velocity.Y < 0 and position.Y < sandY - WormConfig.UndergroundDepth then
			drive.VectorVelocity = Vector3.zero
			drive.Enabled = true
		end
		return
	end

	-- Camera-relative steering.
	local move = InputController.getRawMoveVector()
	local forward = flatUnit(camera.CFrame.LookVector) or -Vector3.zAxis
	local right = forward:Cross(Vector3.yAxis)
	local direction = forward * -move.Z + right * move.X

	local speed = if mode == "Surface" then WormConfig.SurfaceSpeed else WormConfig.UndergroundSpeed
	if sneaking then
		speed *= WormConfig.SneakSpeedMult
	end
	local horizontal = direction * speed
	local targetY: number

	if mode == "Surface" then
		local surfaceY = Ground.surfaceBelow(position)
		targetY = (surfaceY or position.Y - radius) + radius
		if horizontal.Magnitude > 0 and isBlocked(position, direction.Unit, radius) then
			horizontal = Vector3.zero
		end
	else
		local sandY = Ground.sandBelow(position)
		if sandY then
			targetY = sandY - WormConfig.UndergroundDepth
			-- The worm can't swim out from under the sand.
			if horizontal.Magnitude > 0 and not Ground.sandBelow(position + horizontal * WormConfig.EdgeLookahead) then
				horizontal = Vector3.zero
			end
		else
			-- Forced underground somewhere with no sand: sink below whatever is here.
			local surfaceY = Ground.surfaceBelow(position, WormConfig.SandProbeUp)
			targetY = (surfaceY or position.Y + WormConfig.UndergroundDepth) - WormConfig.UndergroundDepth
		end
	end

	local vertical = math.clamp(
		(targetY - position.Y) * WormConfig.DepthGain,
		-WormConfig.MaxVerticalSpeed,
		WormConfig.MaxVerticalSpeed
	)
	drive.VectorVelocity = horizontal + Vector3.yAxis * vertical
	drive.Enabled = true
	if horizontal.Magnitude > 0.1 then
		align.CFrame = CFrame.lookAt(Vector3.zero, horizontal)
	end
end

local function setZoomRange(min: number, max: number)
	player.CameraMaxZoomDistance = UNLOCKED_MAX_ZOOM
	player.CameraMinZoomDistance = min
	player.CameraMaxZoomDistance = max
end

-- The default camera follows a point over the worm (above ground even when the head is below it). With the
-- mouth view setting on, it sits just in front of the head in first person instead.
local function updateCamera(head: BasePart, camera: Camera)
	local mouthView = SettingsController.get().WormMouthView
	if mouthView ~= usingMouthView then
		usingMouthView = mouthView
		local Mouth = SettingsConfig.MouthView
		if mouthView then
			setZoomRange(Mouth.Zoom, Mouth.Zoom)
		else
			setZoomRange(WormConfig.Camera.MinZoom, WormConfig.Camera.MaxZoom)
		end
	end

	local position = head.Position
	if mouthView then
		local Mouth = SettingsConfig.MouthView
		local forward = flatUnit(head.CFrame.LookVector) or -Vector3.zAxis
		cameraAnchor.Position = position + forward * Mouth.ForwardOffset + Vector3.yAxis * Mouth.UpOffset
	else
		local sandY = Ground.sandBelow(position)
		local y = math.max(position.Y, (sandY or position.Y) + WormConfig.Camera.AnchorHeight)
		cameraAnchor.Position = Vector3.new(position.X, y, position.Z)
	end
	if camera.CameraSubject ~= cameraAnchor then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = cameraAnchor
	end
end

local function update()
	for _, worm in CollectionService:GetTagged(Tags.Worm) do
		if worm:IsA("Model") and worm.PrimaryPart then
			updateVisual(worm, worm.PrimaryPart, visuals[worm] or createVisual(worm, worm.PrimaryPart))
		end
	end

	local isWorm = MatchController.getRole() == "Worm"
	if isWorm ~= wasWorm then
		wasWorm = isWorm
		sentSneak = false
		usingMouthView = false
		if isWorm then
			setZoomRange(WormConfig.Camera.MinZoom, WormConfig.Camera.MaxZoom)
		else
			setZoomRange(PardnerConfig.Camera.MinZoom, PardnerConfig.Camera.MaxZoom)
		end
	end

	local worm = WormController.getLocalWorm()
	local head = worm and worm.PrimaryPart
	local camera = Workspace.CurrentCamera
	if isWorm and worm and head and camera then
		control(worm, head, camera)
		updateCamera(head, camera)
	end
end

-- Which ability a key fires: the defaults by their Config action, the two picks by WormAbility1/2.
function WormController.abilityForAction(action: string): string?
	for id, def in Abilities do
		if def.action == action then
			return id
		end
	end
	local slot = PICK_ACTIONS[action]
	local picks = player:GetAttribute("Abilities")
	if slot and typeof(picks) == "string" then
		local index = 0
		for id in string.gmatch(picks, "[^,]+") do
			index += 1
			if index == slot then
				return id
			end
		end
	end
	return nil
end

local function onAction(action: string)
	if MatchController.getRole() ~= "Worm" or not WormController.getLocalWorm() then
		return
	end
	local abilityId = WormController.abilityForAction(action)
	local camera = Workspace.CurrentCamera
	if not abilityId or abilityId == "Sneak" or not camera then
		return -- Sneak is a hold, sent from control()
	end
	abilityRemote:FireServer(abilityId, { direction = camera.CFrame.LookVector })
end

-- Every client plays an ability's effect (shared/AbilityBehaviors/<id>), if it has one.
local function onAbilityFx(abilityId: string, wormModel: Model, data: { [string]: any })
	local folder = ReplicatedStorage.Shared:FindFirstChild("AbilityBehaviors")
	local module = folder and folder:FindFirstChild(abilityId)
	if module and module:IsA("ModuleScript") and wormModel then
		local fx = (require :: any)(module) :: Types.AbilityFx
		fx.clientFx(wormModel, data)
	end
end

-- The server approved a pounce: this client owns the head, so it applies the launch.
local function onLaunch(velocity: Vector3)
	local worm = WormController.getLocalWorm()
	local head = worm and worm.PrimaryPart
	if not head then
		return
	end
	local drive = head:FindFirstChild("Drive")
	if drive and drive:IsA("LinearVelocity") then
		drive.Enabled = false
	end
	launchUntil = os.clock() + LAUNCH_GRACE
	head.AssemblyLinearVelocity = velocity
end

-- The worm model this player controls, if they are a worm right now.
function WormController.getLocalWorm(): Model?
	for _, worm in CollectionService:GetTagged(Tags.Worm) do
		if worm:IsA("Model") and worm:GetAttribute("OwnerUserId") == player.UserId then
			return worm
		end
	end
	return nil
end

function WormController.init()
	abilityRemote = Net.event("Request_Ability")

	-- Local-only visuals live under the camera so they never replicate.
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "WormFx"
	fxFolder.Parent = camera

	cameraAnchor = Instance.new("Part")
	cameraAnchor.Name = "WormCameraAnchor"
	cameraAnchor.Size = Vector3.one
	cameraAnchor.Transparency = 1
	cameraAnchor.Anchored = true
	cameraAnchor.CanCollide = false
	cameraAnchor.CanQuery = false
	cameraAnchor.CanTouch = false
	cameraAnchor.Parent = fxFolder
end

function WormController.start()
	Net.event("Worm_Launch").OnClientEvent:Connect(onLaunch)
	Net.event("Fx_Ability").OnClientEvent:Connect(onAbilityFx)
	InputController.actionPressed:connect(onAction)
	CollectionService:GetInstanceRemovedSignal(Tags.Worm):Connect(destroyVisual)
	RunService.RenderStepped:Connect(update)
end

return WormController
