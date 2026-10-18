--!strict
-- Ghosts (§8.4): dead Pardners fly around and can shove loose items.
--  * Every client: hides ghost models unless the local player is a ghost too.
--    TODO(Phase 10): Spirit Board holders also see (and hear) ghosts.
--  * The ghost's own client: flies its model (which it has network ownership of), points the camera
--    at it, and charges / releases pushes on the item under the cursor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local InputController = require(script.Parent.InputController)
local InventoryController = require(script.Parent.InventoryController)
local MatchController = require(script.Parent.MatchController)
local GhostHud = require(script.Parent.UI.GhostHud)

local SPIRIT_BOARD = "SpiritBoard"

local Tags = TagDefs.Tags
local GhostConfig = PardnerConfig.Ghost
local ARROW_THICKNESS = 0.4
local ARROW_MIN_LENGTH = 1

local GhostController = {}

local player = Players.LocalPlayer

local hud: GhostHud.Hud
local highlight: Highlight
local arrow: Part
local pushRemote: RemoteEvent

local chargeTarget: Model? = nil
local chargeStarted = 0
local wasHolding = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getLocalGhost(): Model?
	for _, ghost in CollectionService:GetTagged(Tags.Ghost) do
		if ghost:IsA("Model") and ghost:GetAttribute("OwnerUserId") == player.UserId then
			return ghost
		end
	end
	return nil
end

-- The loose item under the cursor, if it is close enough to this ghost to push.
local function findTarget(camera: Camera, ghostPosition: Vector3): Model?
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * PardnerConfig.HoverRayLength, rayParams)
	if not result then
		return nil
	end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	while model and not CollectionService:HasTag(model, Tags.Item) do
		model = model:FindFirstAncestorOfClass("Model")
	end
	if not model then
		return nil
	end
	local reach = GhostConfig.PushRange + model:GetExtentsSize().Magnitude / 2
	if (model:GetPivot().Position - ghostPosition).Magnitude > reach then
		return nil
	end
	return model
end

local function hideGhosts(showAll: boolean)
	local modifier = if showAll then 0 else 1
	for _, ghost in CollectionService:GetTagged(Tags.Ghost) do
		for _, descendant in ghost:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = modifier
			end
		end
	end
end

local function fly(part: BasePart, camera: Camera)
	local drive = part:FindFirstChild("Drive")
	if not drive or not drive:IsA("LinearVelocity") then
		return
	end
	-- Fly where the camera looks; Space / Shift go straight up and down.
	local move = InputController.getRawMoveVector()
	local cframe = camera.CFrame
	local vertical = (if InputController.isHeld("GhostUp") then 1 else 0)
		- (if InputController.isHeld("GhostDown") then 1 else 0)
	local direction = cframe.LookVector * -move.Z + cframe.RightVector * move.X + Vector3.yAxis * vertical
	drive.VectorVelocity = direction * GhostConfig.FlySpeed

	if camera.CameraSubject ~= part then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = part
	end
end

-- Hold the push key on an item to charge; an arrow shows where it will go; let go to push.
local function updatePush(ghost: Model, part: BasePart, camera: Camera)
	local now = Workspace:GetServerTimeNow()
	local readyAt = ghost:GetAttribute("PushReadyAt")
	local cooldown = (if typeof(readyAt) == "number" then readyAt else 0) - now

	local hovered = if cooldown <= 0 then findTarget(camera, part.Position) else nil
	local holding = InputController.isHeld("GhostPush")

	if holding and not wasHolding and hovered then
		chargeTarget = hovered
		chargeStarted = os.clock()
	end

	local target = chargeTarget
	local charge = 0
	if target and target.Parent then
		charge = math.clamp((os.clock() - chargeStarted) / GhostConfig.PushChargeSeconds, 0, 1)
		local direction = camera.CFrame.LookVector
		if not holding then
			pushRemote:FireServer(target, direction, charge)
			chargeTarget = nil
			charge = 0
		else
			local length = ARROW_MIN_LENGTH + GhostConfig.ArrowLength * charge
			local origin = target:GetPivot().Position
			arrow.Size = Vector3.new(ARROW_THICKNESS, ARROW_THICKNESS, length)
			arrow.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -length / 2)
		end
	else
		chargeTarget = nil
	end
	wasHolding = holding

	arrow.Transparency = if chargeTarget then 0.2 else 1
	highlight.Adornee = chargeTarget or hovered
	hud.setCharge(charge)
	if cooldown > 0 then
		hud.setStatus(string.format("Push ready in %.0fs", cooldown))
	elseif chargeTarget then
		hud.setStatus("Release E to push")
	elseif hovered then
		hud.setStatus("Hold E to charge a push")
	else
		hud.setStatus("Push ready - point at a nearby item")
	end
end

local function update()
	local isGhost = MatchController.isGhost()
	-- Ghosts see each other; so does a living Pardner carrying a Spirit Board (§6.6).
	local hasBoard = MatchController.isPardner() and InventoryController.getState().kit == SPIRIT_BOARD
	hideGhosts(isGhost or hasBoard)
	hud.gui.Enabled = isGhost

	local ghost = if isGhost then getLocalGhost() else nil
	local part = ghost and ghost.PrimaryPart
	local camera = Workspace.CurrentCamera
	if not ghost or not part or not camera then
		chargeTarget = nil
		wasHolding = false
		arrow.Transparency = 1
		highlight.Adornee = nil
		return
	end

	fly(part, camera)
	updatePush(ghost, part, camera)
end

function GhostController.init()
	pushRemote = Net.event("Request_GhostPush")

	-- Local-only visuals live under the camera so they never replicate.
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
	local folder = Instance.new("Folder")
	folder.Name = "GhostFx"
	folder.Parent = camera

	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.fromRGB(200, 230, 255)
	highlight.Parent = folder

	arrow = Instance.new("Part")
	arrow.Name = "PushArrow"
	arrow.Material = Enum.Material.Neon
	arrow.Color = Color3.fromRGB(200, 230, 255)
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CanQuery = false
	arrow.CanTouch = false
	arrow.Transparency = 1
	arrow.Parent = folder

	hud = GhostHud.create(player:WaitForChild("PlayerGui"))
end

function GhostController.start()
	RunService.RenderStepped:Connect(update)
end

return GhostController
