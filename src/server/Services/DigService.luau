--!strict
-- Buried things and digging (§10.2).
--
-- Objectives bury items at points on the sand (bury). Anything buried comes up when someone digs
-- next to it with a Shovel (hold interact on sand for DigSeconds), when a blast goes off near it
-- (ExplosionService.exploded), or when a worm bodyslams it (Phase 11 calls digAt).
-- While the metal detector is on, every Pardner with a Shovel in the kit slot gets a player
-- attribute Detector = 0..100 (closeness to the nearest detectable buried thing), else nil.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Net = require(ReplicatedStorage.Shared.Net)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local ExplosionService = require(script.Parent.ExplosionService)
local ItemService = require(script.Parent.ItemService)
local MapService = require(script.Parent.MapService)
local PardnerService = require(script.Parent.PardnerService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local Debug = GameConfig.Debug
local Shovel = Kits.Shovel.params
local SHOVEL = "Shovel"
local DETECTOR_ATTRIBUTE = "Detector"
local MARKER_SIZE = Vector3.new(3, 3, 3) -- debug marker over buried things

export type BuryOptions = {
	detectable: boolean?, -- shows up on the metal detector
	extraAssetId: string?, -- a prop left next to it when dug up (the key's skeleton)
	extraOffset: Vector3?,
	onUnearthed: ((model: Model?) -> ())?,
}

type Buried = {
	itemId: string,
	position: Vector3, -- on the sand surface
	options: BuryOptions,
	marker: BasePart?,
}

type Dig = {
	startedAt: number,
	position: Vector3,
}

local DigService = {}

local buried: { Buried } = {}
local digs: { [Player]: Dig } = {}
local detectorActive = false
local detectorTimer = 0
local notifyRemote: RemoteEvent

local function removeMarker(entry: Buried)
	if entry.marker then
		entry.marker:Destroy()
		entry.marker = nil
	end
end

local function addMarker(entry: Buried)
	local marker = Instance.new("Part")
	marker.Name = `Buried_{entry.itemId}`
	marker.Shape = Enum.PartType.Ball
	marker.Size = MARKER_SIZE
	marker.Color = Debug.BuriedMarkerColor
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.6
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Position = entry.position
	marker.Parent = MapService.getRuntimeFolder() or Workspace
	entry.marker = marker
end

local function leaveHole(position: Vector3)
	local hole = AssetService.get("DigHole") -- TODO(asset): dug-up sand decal
	for _, descendant in hole:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	hole:PivotTo(CFrame.new(position))
	hole.Parent = MapService.getRuntimeFolder() or Workspace
end

local function unearth(entry: Buried)
	removeMarker(entry)
	local model = ItemService.spawn(entry.itemId, CFrame.new(entry.position + Vector3.yAxis * 2))
	local extra = entry.options.extraAssetId
	if extra then
		local prop = AssetService.get(extra) -- TODO(asset): e.g. Skeleton
		for _, descendant in prop:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		prop:PivotTo(CFrame.new(entry.position + (entry.options.extraOffset or Vector3.zero)))
		prop.Parent = MapService.getRuntimeFolder() or Workspace
	end
	local callback = entry.options.onUnearthed
	if callback then
		callback(model)
	end
end

-- Buries `itemId` at the sand surface under `position`. Returns false if there is no sand there.
function DigService.bury(itemId: string, position: Vector3, options: BuryOptions?): boolean
	local sandY = Ground.sandBelow(position)
	if not sandY then
		return false
	end
	local entry: Buried = {
		itemId = itemId,
		position = Vector3.new(position.X, sandY, position.Z),
		options = options or {},
		marker = nil,
	}
	table.insert(buried, entry)
	if Debug.Enabled and Debug.ShowBuried then
		addMarker(entry)
	end
	return true
end

-- Digs up everything buried within `radius` of `position`. Returns how many things came up.
function DigService.digAt(position: Vector3, radius: number): number
	local found = {}
	for index = #buried, 1, -1 do
		local entry = buried[index]
		local offset = entry.position - position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius then
			table.remove(buried, index)
			table.insert(found, entry)
		end
	end
	for _, entry in found do
		unearth(entry)
	end
	return #found
end

-- The metal detector (§10.2) only works while the key objective wants it.
function DigService.setDetectorActive(active: boolean)
	detectorActive = active
	if not active then
		for _, player in Players:GetPlayers() do
			player:SetAttribute(DETECTOR_ATTRIBUTE, nil)
		end
	end
end

-- Forgets everything buried (match over).
function DigService.clear()
	for _, entry in buried do
		removeMarker(entry)
	end
	table.clear(buried)
	table.clear(digs)
	DigService.setDetectorActive(false)
end

-- Shovel digging ------------------------------------------------------------------------------

local function onDig(player: Player, digging: any)
	if typeof(digging) ~= "boolean" then
		return
	end
	if not digging then
		digs[player] = nil
		return
	end

	local root = PardnerService.getLiving()[player]
	if not root or ItemService.getKitId(player) ~= SHOVEL then
		return
	end
	local _, isSand = Ground.surfaceBelow(root.Position)
	if not isSand then
		notifyRemote:FireClient(player, "You can only dig in sand")
		return
	end
	digs[player] = { startedAt = os.clock(), position = root.Position }
end

local function updateDigs()
	local time = os.clock()
	for player, dig in digs do
		local root = PardnerService.getLiving()[player]
		local moved = if root then (root.Position - dig.position).Magnitude else math.huge
		if not root or moved > Shovel.DigMoveTolerance or ItemService.getKitId(player) ~= SHOVEL then
			digs[player] = nil
		elseif time - dig.startedAt >= Shovel.DigSeconds then
			digs[player] = nil
			local point = root.Position + root.CFrame.LookVector * Shovel.DigReach
			local groundY = Ground.sandBelow(point) or point.Y
			local spot = Vector3.new(point.X, groundY, point.Z)
			leaveHole(spot)
			SoundCue.play("Dig", spot)
			local found = DigService.digAt(spot, Shovel.DigRadius)
			notifyRemote:FireClient(player, if found > 0 then "You dug something up!" else "Nothing here")
		end
	end
end

-- Metal detector --------------------------------------------------------------------------------

local function nearestDetectable(position: Vector3): number?
	local best: number? = nil
	for _, entry in buried do
		if entry.options.detectable then
			local offset = entry.position - position
			local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
			if not best or distance < best then
				best = distance
			end
		end
	end
	return best
end

local function updateDetector()
	for _, player in Players:GetPlayers() do
		local reading: number? = nil
		local root = PardnerService.getLiving()[player]
		if detectorActive and root and ItemService.getKitId(player) == SHOVEL then
			local distance = nearestDetectable(root.Position)
			if distance then
				reading = math.floor(math.clamp(100 - distance / Shovel.DetectorMaxDistance * 100, 0, 100))
			end
		end
		if player:GetAttribute(DETECTOR_ATTRIBUTE) ~= reading then
			player:SetAttribute(DETECTOR_ATTRIBUTE, reading)
		end
	end
end

function DigService.init()
	notifyRemote = Net.event("Fx_Notify")
end

function DigService.start()
	Net.onRequest("Request_Dig", onDig)
	ExplosionService.exploded:connect(function(position: Vector3, radius: number)
		DigService.digAt(position, radius)
	end)
	Players.PlayerRemoving:Connect(function(player)
		digs[player] = nil
	end)

	RunService.Heartbeat:Connect(function(dt)
		updateDigs()
		detectorTimer += dt
		if detectorTimer >= Shovel.DetectorTickSeconds then
			detectorTimer = 0
			updateDetector()
		end
	end)
end

return DigService
