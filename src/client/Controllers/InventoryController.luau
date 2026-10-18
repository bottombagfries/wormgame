--!strict
-- Client side of items (§6.2): finds the hovered item, sends pickup/drop/store/throw intents,
-- shows the inventory HUD and draws the throw arc while aiming with something in hand.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local ThrowLogic = require(ReplicatedStorage.Shared.ThrowLogic)
local Types = require(ReplicatedStorage.Shared.Types)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local CameraController = require(script.Parent.CameraController)
local InputController = require(script.Parent.InputController)
local MatchController = require(script.Parent.MatchController)
local ToastController = require(script.Parent.ToastController)
local InventoryHud = require(script.Parent.UI.InventoryHud)

local Tags = TagDefs.Tags
local Arc = PardnerConfig.ThrowArc
local BAG_ACTION_PREFIX = "Bag"
local SHOVEL = "Shovel"

local InventoryController = {}

local player = Players.LocalPlayer

local state: Types.InventoryState = { bag = {}, capacity = PardnerConfig.BagSlots, used = 0 }
local hovered: Model? = nil
local digging = false
local hud: InventoryHud.Hud
local highlight: Highlight
local arcDots: { Part } = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function describe(model: Model): string
	local itemId = model:GetAttribute("ItemId")
	local def = if typeof(itemId) == "string" then Items[itemId] else nil
	if not def then
		return model.Name
	end
	local size = if def.size == 0 then "instant" else tostring(def.size)
	local text = `{def.displayName} / Size {size}`
	if def.fuel then
		text ..= ` / Fuel {def.fuel}`
	end
	if model:GetAttribute("Lit") == true then
		local endsAt = model:GetAttribute("FuseEndsAt")
		local left = if typeof(endsAt) == "number" then math.max(0, endsAt - Workspace:GetServerTimeNow()) else 0
		text ..= ` / LIT! {math.ceil(left)}s`
	end
	local bottles = model:GetAttribute("Bottles")
	if typeof(bottles) == "number" then
		text ..= ` / {bottles} bottles`
	end
	-- Heart jars say whose they are.
	local owner = model:GetAttribute("OwnerName")
	if typeof(owner) == "string" then
		text ..= ` / {owner}{if model:GetAttribute("Ossified") == true then " (ossified)" else ""}`
	end
	return text
end

-- The item under the crosshair (aiming) or the mouse cursor, if it is close enough to pick up.
local function findHovered(camera: Camera, root: BasePart): Model?
	local point = if CameraController.isAiming() then camera.ViewportSize / 2 else UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(point.X, point.Y)
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

	local reach = PardnerConfig.PickupRange + model:GetExtentsSize().Magnitude / 2
	if (model:GetPivot().Position - root.Position).Magnitude > reach then
		return nil
	end
	return model
end

local function hideArc()
	for _, dot in arcDots do
		dot.Transparency = 1
	end
end

-- Dots along the path the held item will take, up to the first thing it hits.
local function updateArc(camera: Camera, root: BasePart, handModel: Model)
	local direction = ThrowLogic.direction(camera.CFrame.LookVector)
	local origin = ThrowLogic.origin(root.Position, direction, handModel:GetExtentsSize())
	local kitDef = if state.kit then Kits[state.kit] else nil
	local velocity = ThrowLogic.velocity(direction, 1, kitDef and kitDef.params.PassiveThrowPowerMult or 1)
	local gravity = Vector3.new(0, -Workspace.Gravity, 0)

	local previous = origin
	local blocked = false
	for index, dot in arcDots do
		if blocked then
			dot.Transparency = 1
			continue
		end
		local t = index * Arc.TimeStep
		local point = origin + velocity * t + gravity * (0.5 * t * t)
		local hit = Workspace:Raycast(previous, point - previous, rayParams)
		if hit then
			point = hit.Position
			blocked = true
		end
		dot.Position = point
		dot.Transparency = 0.2
		previous = point
	end
end

local function update()
	local camera = Workspace.CurrentCamera
	local root = getRoot()
	local isPardner = MatchController.isPardner()
	hud.gui.Enabled = isPardner

	-- Letting go of interact stops a dig.
	if digging and (not isPardner or not InputController.isHeld("Interact")) then
		digging = false
		Net.event("Request_Dig"):FireServer(false)
	end

	-- Metal detector reading (only while a Shovel is in the kit slot and the key is buried).
	local reading = player:GetAttribute("Detector")
	hud.setDetector(if typeof(reading) == "number" then reading else nil)
	if not camera or not root or not isPardner then
		hovered = nil
		highlight.Adornee = nil
		hud.setHover(nil, "")
		hideArc()
		return
	end

	hovered = findHovered(camera, root)
	highlight.Adornee = hovered
	if hovered then
		local character = player.Character
		hud.setHover(character and character:FindFirstChild("Head"), describe(hovered))
	else
		hud.setHover(nil, "")
	end

	local handModel = state.handModel
	if CameraController.isAiming() and handModel and handModel.Parent then
		updateArc(camera, root, handModel)
	else
		hideArc()
	end
end

local function onAction(action: string)
	if not MatchController.isPardner() then
		return
	end
	if action == "Interact" then
		if hovered then
			Net.event("Request_Pickup"):FireServer(hovered)
		elseif state.kit == SHOVEL and not digging then
			-- Nothing to pick up, but a Shovel in the kit slot: hold to dig (§10.2).
			digging = true
			Net.event("Request_Dig"):FireServer(true)
			ToastController.hint("Digging... (keep holding E)")
		end
	elseif action == "Drop" then
		if state.hand then
			Net.event("Request_Drop"):FireServer()
		end
	elseif action == "StoreInBag" then
		if state.hand then
			Net.event("Request_StoreInBag"):FireServer()
		end
	elseif action == "UseHeld" then
		if state.hand then
			Net.event("Request_UseHeld"):FireServer()
		end
	elseif action == "UseKit" then
		local camera = Workspace.CurrentCamera
		if state.kit and camera then
			Net.event("Request_UseKit"):FireServer({ direction = ThrowLogic.direction(camera.CFrame.LookVector) })
		end
	elseif action == "Throw" then
		local camera = Workspace.CurrentCamera
		if camera and state.hand and CameraController.isAiming() then
			Net.event("Request_Throw"):FireServer(ThrowLogic.direction(camera.CFrame.LookVector), 1)
		end
	elseif string.sub(action, 1, #BAG_ACTION_PREFIX) == BAG_ACTION_PREFIX then
		local slot = tonumber(string.sub(action, #BAG_ACTION_PREFIX + 1))
		if slot and state.bag[slot] then
			Net.event("Request_TakeFromBag"):FireServer(slot)
		end
	end
end

local function onCharacter(character: Model)
	rayParams.FilterDescendantsInstances = { character }
end

function InventoryController.getState(): Types.InventoryState
	return state
end

function InventoryController.getHovered(): Model?
	return hovered
end

function InventoryController.init()
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

	-- Local-only visuals live under the camera so they never replicate.
	local folder = Instance.new("Folder")
	folder.Name = "InventoryFx"
	folder.Parent = camera

	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = folder

	for index = 1, Arc.Points do
		local dot = Instance.new("Part")
		dot.Name = `ArcDot{index}`
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.one * Arc.DotSize
		dot.Material = Enum.Material.Neon
		dot.Color = Color3.new(1, 1, 1)
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanQuery = false
		dot.CanTouch = false
		dot.CastShadow = false
		dot.Transparency = 1
		dot.Parent = folder
		table.insert(arcDots, dot)
	end

	hud = InventoryHud.create(player:WaitForChild("PlayerGui"))
	hud.setState(state)
end

function InventoryController.start()
	Net.event("State_Inventory").OnClientEvent:Connect(function(serverState: Types.InventoryState)
		state = serverState
		hud.setState(state)
	end)
	InputController.actionPressed:connect(onAction)

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end

	RunService.RenderStepped:Connect(update)
end

return InventoryController
