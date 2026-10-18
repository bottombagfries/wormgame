--!strict
-- NPCs: cattlebugs and the dandylion flowers that lure them (§10.4), and the balloon pilot (§11, in
-- NPC/BalloonPilot: airdrops and the last-Pardner escape ladder).
--
-- Cattlebugs are anchored models the server walks across the ground: they wander until a flower is
-- within AttractRange, then walk to the nearest one and eat it. A bug that walks into the pen counts
-- as delivered and stays there. Flowers are thrown with the Dandylion Bundle kit (use kit, T);
-- each Pardner can have MaxActiveFlowers out at once (a new one removes their oldest).
-- Bug attribute: Penned.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local BalloonPilot = require(script.Parent.Parent.NPC.BalloonPilot)
local ItemService = require(script.Parent.ItemService)
local PardnerService = require(script.Parent.PardnerService)

local Dandylion = Kits.DandylionBundle.params
local BugParams = Objectives.HerdCattlebugs.params :: { [string]: any }
local Tags = TagDefs.Tags
local DANDYLION_KIT = "DandylionBundle"
local NPC_FOLDER = "NPCs"

type Bug = {
	model: Model,
	position: Vector3,
	halfHeight: number,
	target: Vector3?,
	wanderTimer: number,
	penned: boolean,
}

type Flower = {
	part: BasePart,
	owner: Player,
	wiltsAt: number,
}

local NPCService = {}

-- The last Pardner climbed the balloon's ladder: (player). MatchService ends the match with them escaped.
NPCService.balloonEscaped = BalloonPilot.escaped

local bugs: { Bug } = {}
local flowers: { Flower } = {}
local penCenter: Vector3? = nil
local penRadius = 0
local delivered = 0
local npcFolder: Instance
local notifyRemote: RemoteEvent

local function removeFlower(flower: Flower)
	local index = table.find(flowers, flower)
	if index then
		table.remove(flowers, index)
	end
	flower.part:Destroy()
end

-- Throws a flower along the Pardner's aim. Their oldest goes if they're over the limit.
local function throwFlower(player: Player, payload: { [string]: any })
	local root = PardnerService.getLiving()[player]
	if not root then
		return
	end
	local direction: Vector3 = payload.direction or root.CFrame.LookVector

	local model = AssetService.get("Dandylion") -- TODO(asset): Dandylion
	local part = model.PrimaryPart :: BasePart
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	part.Parent = npcFolder
	model:Destroy()
	part.Anchored = false
	part.CanCollide = true
	part.Position = root.Position
		+ Vector3.yAxis * PardnerConfig.ThrowOriginHeight
		+ direction * (PardnerConfig.ThrowOriginForward + part.Size.Magnitude / 2)
	part.AssemblyLinearVelocity = direction * Dandylion.ThrowSpeed
	-- The flower plants itself where it lands; a loose ball would roll out of the bugs' reach.
	local landed: RBXScriptConnection
	landed = part.Touched:Connect(function(hit: BasePart)
		local character = player.Character
		if not hit.CanCollide or (character and hit:IsDescendantOf(character)) then
			return
		end
		landed:Disconnect()
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
		part.Anchored = true
	end)

	table.insert(flowers, { part = part, owner = player, wiltsAt = os.clock() + Dandylion.FlowerSeconds })
	local mine = {}
	for _, flower in flowers do
		if flower.owner == player then
			table.insert(mine, flower)
		end
	end
	if #mine > Dandylion.MaxActiveFlowers then
		removeFlower(mine[1])
	end
end

local function nearestFlower(position: Vector3): Flower?
	local best: Flower? = nil
	local bestDistance = Dandylion.AttractRange
	for _, flower in flowers do
		local distance = (flower.part.Position - position).Magnitude
		if distance <= bestDistance then
			best, bestDistance = flower, distance
		end
	end
	return best
end

local function pen(bug: Bug)
	bug.penned = true
	delivered += 1
	bug.model:SetAttribute("Penned", true)
	for _, descendant in bug.model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = BugParams.PennedColor
		end
	end
	notifyRemote:FireAllClients(`A cattlebug is in the pen ({delivered}/{#bugs})`)
end

local function stepBug(bug: Bug, dt: number, rng: Random)
	local center = penCenter
	if center then
		local offset = bug.position - center
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= penRadius then
			pen(bug)
			return
		end
	end

	local flower = nearestFlower(bug.position)
	local target: Vector3
	if flower then
		target = flower.part.Position
		if (target - bug.position).Magnitude <= Dandylion.EatRadius then
			removeFlower(flower) -- TODO(asset): eating animation / sound
			return
		end
	else
		bug.wanderTimer -= dt
		local current = bug.target
		local arrived = current and (current - bug.position).Magnitude <= BugParams.ArriveDistance
		if not current or arrived or bug.wanderTimer <= 0 then
			local angle = rng:NextNumber(0, math.pi * 2)
			local distance = rng:NextNumber(0, BugParams.WanderRadius)
			current = bug.position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
			bug.target = current
			bug.wanderTimer = BugParams.WanderSeconds
		end
		target = current :: Vector3
	end

	local flat = Vector3.new(target.X - bug.position.X, 0, target.Z - bug.position.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	local step = flat.Unit * math.min(flat.Magnitude, BugParams.BugSpeed * dt)
	local moved = bug.position + step
	local groundY = Ground.surfaceBelow(moved)
	if not groundY then
		bug.target = nil -- the edge of the map: wander somewhere else instead of walking into the void
		return
	end
	bug.position = Vector3.new(moved.X, groundY + bug.halfHeight, moved.Z)
	bug.model:PivotTo(CFrame.lookAt(bug.position, bug.position + flat))
end

-- Starts a herd: one bug at each of `positions`, and the pen they must reach.
function NPCService.spawnCattlebugs(positions: { Vector3 }, center: Vector3, radius: number)
	NPCService.clear()
	penCenter = center
	penRadius = radius
	for _, position in positions do
		local model = AssetService.get("Cattlebug") -- TODO(asset): Cattlebug
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
		local halfHeight = model:GetExtentsSize().Y / 2
		local start = position + Vector3.yAxis * halfHeight
		model:PivotTo(CFrame.new(start))
		model:SetAttribute("Penned", false)
		model:AddTag(Tags.Cattlebug)
		model.Parent = npcFolder
		table.insert(bugs, {
			model = model,
			position = start,
			halfHeight = halfHeight,
			target = nil,
			wanderTimer = 0,
			penned = false,
		})
	end
end

-- Match start: whether the balloon may come for the last Pardner this match.
function NPCService.beginMatch(balloonEscape: boolean)
	BalloonPilot.begin(balloonEscape)
end

-- The 66 %-to-sundown supply drop (§5.4).
function NPCService.airdrop(count: number)
	BalloonPilot.airdrop(count)
end

function NPCService.endMatch()
	BalloonPilot.finish()
	NPCService.clear()
end

function NPCService.getDelivered(): number
	return delivered
end

-- Removes every bug and flower.
function NPCService.clear()
	for _, bug in bugs do
		bug.model:Destroy()
	end
	table.clear(bugs)
	for _, flower in flowers do
		flower.part:Destroy()
	end
	table.clear(flowers)
	penCenter = nil
	delivered = 0
end

function NPCService.init()
	local folder = Instance.new("Folder")
	folder.Name = NPC_FOLDER
	folder.Parent = Workspace
	npcFolder = folder
	notifyRemote = Net.event("Fx_Notify")
end

function NPCService.start()
	ItemService.kitUsed:connect(function(player: Player, kitId: string, payload: { [string]: any })
		if kitId == DANDYLION_KIT then
			throwFlower(player, payload)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for index = #flowers, 1, -1 do
			if flowers[index].owner == player then
				removeFlower(flowers[index])
			end
		end
	end)

	local rng = Random.new()
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for index = #flowers, 1, -1 do
			local flower = flowers[index]
			if now >= flower.wiltsAt or not flower.part.Parent then
				removeFlower(flower)
			end
		end
		for _, bug in bugs do
			if not bug.penned then
				stepBug(bug, dt, rng)
			end
		end
		BalloonPilot.step(dt)
	end)
end

return NPCService
