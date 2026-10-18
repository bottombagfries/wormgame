--!strict
-- What the worm's client is allowed to show (§8.2, §13). Pardner characters replicate normally, so
-- on a worm client this hides every Pardner not in the server's visible set and every item that is
-- not right next to the worm, and draws the red ground pings the server sends.
-- This is client-side hiding (exploitable); accepted for v1.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Net = require(ReplicatedStorage.Shared.Net)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local MatchController = require(script.Parent.MatchController)
local WormController = require(script.Parent.WormController)

type Dot = {
	part: Part,
	gui: BillboardGui,
	frame: Frame,
	expires: number,
}

local PING_COLOR = Color3.fromRGB(255, 40, 40)

local WormVisionController = {}

local player = Players.LocalPlayer

local visible: { [number]: boolean } = {} -- userIds
local dots: { Dot } = {}
local nextDot = 1
local refreshTimer = 0
local wasWorm = false

local function setHidden(model: Instance, hidden: boolean)
	local modifier = if hidden then 1 else 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.LocalTransparencyModifier = modifier
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = not hidden
		elseif descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = if hidden
				then Enum.HumanoidDisplayDistanceType.None
				else Enum.HumanoidDisplayDistanceType.Viewer
		end
	end
end

-- Applies (or with showAll, removes) the worm's blindness.
local function refresh(showAll: boolean)
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if other ~= player and character then
			setHidden(character, not showAll and not visible[other.UserId])
		end
	end

	local worm = WormController.getLocalWorm()
	local head = worm and worm.PrimaryPart
	-- Disoriented: not even the props right next to the worm (§6.6 cymbal monkey).
	local disorientedUntil = worm and worm:GetAttribute("DisorientedUntil")
	local now = Workspace:GetServerTimeNow()
	local disoriented = typeof(disorientedUntil) == "number" and now < disorientedUntil
	-- Sonar Scream: props within its radius show too (-1 = everywhere).
	local revealUntil = worm and worm:GetAttribute("RevealUntil")
	local revealCenter = worm and worm:GetAttribute("RevealCenter")
	local revealRadius = worm and worm:GetAttribute("RevealRadius")
	local revealing = not disoriented
		and typeof(revealUntil) == "number"
		and now < revealUntil
		and typeof(revealCenter) == "Vector3"
		and typeof(revealRadius) == "number"
	for _, item in CollectionService:GetTagged(TagDefs.Tags.Item) do
		if item:IsA("Model") then
			local position = item:GetPivot().Position
			local near = head ~= nil
				and not disoriented
				and (position - head.Position).Magnitude <= WormConfig.CloseItemRadius
			local revealed = revealing
				and (
					(revealRadius :: number) < 0
					or (position - (revealCenter :: Vector3)).Magnitude <= (revealRadius :: number)
				)
			setHidden(item, not showAll and not near and not revealed)
		end
	end
end

local function makeDot(parent: Instance): Dot
	local part = Instance.new("Part")
	part.Name = "PingDot"
	part.Size = Vector3.one
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = parent

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(WormConfig.PingDotSize, WormConfig.PingDotSize)
	gui.AlwaysOnTop = true
	gui.Enabled = false
	gui.Parent = part

	-- TODO(asset): ping sprite
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = PING_COLOR
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	return { part = part, gui = gui, frame = frame, expires = 0 }
end

local function onPings(positions: { Vector3 })
	local expires = os.clock() + WormConfig.PingLifetime
	for _, position in positions do
		local dot = dots[nextDot]
		nextDot = nextDot % #dots + 1
		dot.part.Position = position
		dot.expires = expires
	end
end

local function onVisible(userIds: { number })
	table.clear(visible)
	for _, userId in userIds do
		visible[userId] = true
	end
end

local function update(dt: number)
	local isWorm = MatchController.getRole() == "Worm"

	-- Pings fade out over their lifetime.
	local now = os.clock()
	for _, dot in dots do
		local remaining = if isWorm then (dot.expires - now) / WormConfig.PingLifetime else 0
		dot.gui.Enabled = remaining > 0
		dot.frame.BackgroundTransparency = 1 - math.clamp(remaining, 0, 1)
	end

	if isWorm then
		refreshTimer += dt
		if refreshTimer >= WormConfig.VisionRefreshSeconds then
			refreshTimer = 0
			refresh(false)
		end
	elseif wasWorm then
		table.clear(visible)
		refresh(true)
	end
	wasWorm = isWorm
end

function WormVisionController.init()
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
	local folder = Instance.new("Folder")
	folder.Name = "WormPings"
	folder.Parent = camera
	for _ = 1, WormConfig.MaxPingDots do
		table.insert(dots, makeDot(folder))
	end
end

function WormVisionController.start()
	Net.event("Worm_Pings").OnClientEvent:Connect(onPings)
	Net.event("Worm_Visible").OnClientEvent:Connect(onVisible)
	RunService.RenderStepped:Connect(update)
end

return WormVisionController
