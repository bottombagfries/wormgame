--!strict
-- The balloon pilot (§5.4, §11), driven by NPCService.
--  * Airdrop: at 66 % of the way to sundown it flies over AirdropChests random sand spots and drops a
--    chest at each (random kit + maybe an extra), then leaves.
--  * Escape (only with EnableBalloon, in matches that started with ≥ MinPardners): when exactly one
--    Pardner is alive it flies to a random spot and lowers a ladder; holding F at its foot = escaping.
--    If anyone is revived (alive ≠ 1) the ladder goes up and it leaves until it's needed again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Net = require(ReplicatedStorage.Shared.Net)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local Chests = require(script.Parent.Parent.Map.Chests)
local MapService = require(script.Parent.Parent.Services.MapService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local Balloon = GameConfig.Balloon
local TrainConfig = GameConfig.Train

type Mode = "Away" | "Airdrop" | "ToLadder" | "Ladder" | "Leaving"

local BalloonPilot = {}

-- The last Pardner climbed aboard: (player).
local escaped: Signal.Signal<Player> = Signal.new()
BalloonPilot.escaped = escaped

local model: Model? = nil
local position = Vector3.zero
local mode: Mode = "Away"
local route: { Vector3 } = {} -- airdrop ground points still to visit
local ladderSpot: Vector3? = nil
local ladder: Model? = nil
local escapeEnabled = false
local checkTimer = 0
local rng = Random.new()

local function notifyAll(text: string)
	Net.event("Fx_Notify"):FireAllClients(text)
end

local function hoverOver(point: Vector3): Vector3
	return AbilityKit.groundAt(point) + Vector3.yAxis * Balloon.Height
end

local function centerPoint(): Vector3
	return MapService.getMarkerCFrames(TagDefs.Tags.TrainSpot, CFrame.identity)[1].Position
end

local function removeLadder()
	if ladder then
		ladder:Destroy()
	end
	ladder = nil
end

local function despawn()
	removeLadder()
	if model then
		model:Destroy()
	end
	model = nil
	mode = "Away"
	table.clear(route)
	ladderSpot = nil
end

local function ensureModel()
	if model and model.Parent then
		return
	end
	local balloon = AssetService.get("Balloon") -- TODO(asset): balloon + pilot
	for _, descendant in balloon:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
		end
	end
	position = hoverOver(centerPoint())
	balloon:PivotTo(CFrame.new(position))
	balloon.Parent = MapService.getRuntimeFolder() or Workspace
	model = balloon
end

local function dropLadder(spot: Vector3)
	local balloon = model
	if not balloon then
		return
	end
	local ground = AbilityKit.groundAt(spot)
	local _, size = balloon:GetBoundingBox()
	local top = position - Vector3.yAxis * (size.Y / 2)
	local length = math.max(1, top.Y - ground.Y)

	local newLadder = AssetService.get("BalloonLadder") -- TODO(asset): rope ladder
	local part = newLadder.PrimaryPart :: BasePart
	for _, descendant in newLadder:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	part.Size = Vector3.new(Balloon.LadderWidth, length, part.Size.Z)
	newLadder:PivotTo(CFrame.new(ground.X, ground.Y + length / 2, ground.Z))

	-- The prompt hangs at the foot of the ladder, so it's in reach from the ground.
	local foot = Instance.new("Attachment")
	foot.Name = "LadderFoot"
	foot.Position = Vector3.new(0, -length / 2 + Balloon.LadderPromptHeight, 0)
	foot.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Balloon"
	prompt.ActionText = "Climb aboard"
	prompt.HoldDuration = Balloon.LadderHoldSeconds
	prompt.MaxActivationDistance = TrainConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	prompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	prompt.Parent = foot
	prompt.Triggered:Connect(function(player)
		local root = PardnerService.getLiving()[player]
		local reach = TrainConfig.PromptDistance + TrainConfig.PromptSlack
		if mode == "Ladder" and root and (root.Position - foot.WorldPosition).Magnitude <= reach then
			prompt.Enabled = false
			escaped:fire(player)
		end
	end)

	newLadder.Parent = balloon.Parent
	ladder = newLadder
	SoundCue.play("BalloonArrives")
	notifyAll("The balloon has lowered a ladder - climb aboard to escape!")
end

local function arrive()
	if mode == "Airdrop" then
		local spot = table.remove(route, 1)
		if spot then
			local folder = MapService.getRuntimeFolder()
			if folder then
				Chests.spawnOne(CFrame.new(AbilityKit.groundAt(spot)), folder, rng)
				SoundCue.play("Airdrop", spot)
			end
		end
		if #route == 0 then
			mode = "Leaving"
		end
	elseif mode == "ToLadder" then
		mode = "Ladder"
		dropLadder(ladderSpot or position)
	elseif mode == "Leaving" then
		despawn()
	end
end

local function currentTarget(): Vector3?
	if mode == "Airdrop" and route[1] then
		return hoverOver(route[1])
	elseif mode == "ToLadder" and ladderSpot then
		return hoverOver(ladderSpot)
	elseif mode == "Leaving" then
		return hoverOver(centerPoint())
	end
	return nil
end

-- Comes for the last Pardner, or goes away again once there's more than one.
local function checkEscape()
	if not escapeEnabled then
		return
	end
	local alive = PardnerService.getAliveCount()
	if alive == 1 and mode ~= "ToLadder" and mode ~= "Ladder" then
		ensureModel()
		table.clear(route)
		ladderSpot = MapService.findLooseSpot(rng) or centerPoint()
		mode = "ToLadder"
		notifyAll("A balloon is coming for the last Pardner standing!")
	elseif alive ~= 1 and (mode == "ToLadder" or mode == "Ladder") then
		removeLadder()
		mode = "Leaving"
		notifyAll("The balloon pulls up its ladder")
	end
end

function BalloonPilot.step(dt: number)
	checkTimer += dt
	if checkTimer >= Balloon.CheckSeconds then
		checkTimer = 0
		checkEscape()
	end

	local balloon = model
	local target = currentTarget()
	if not balloon or not target or mode == "Ladder" then
		return
	end
	local offset = target - position
	if offset.Magnitude <= Balloon.ArriveDistance then
		arrive()
		return
	end
	position += offset.Unit * math.min(offset.Magnitude, Balloon.Speed * dt)
	balloon:PivotTo(CFrame.new(position))
end

-- Starts the match: whether the escape ladder can come at all this match.
function BalloonPilot.begin(escapeAllowed: boolean)
	despawn()
	escapeEnabled = escapeAllowed
	checkTimer = 0
end

-- The 66 % airdrop: chests at `count` random sand spots. While the ladder is out, they just appear.
function BalloonPilot.airdrop(count: number)
	local spots = {}
	for _ = 1, count do
		local spot = MapService.findLooseSpot(rng)
		if spot then
			table.insert(spots, spot)
		end
	end
	notifyAll("The balloon pilot is dropping supplies!")
	if mode == "ToLadder" or mode == "Ladder" then
		local folder = MapService.getRuntimeFolder()
		for _, spot in spots do
			if folder then
				Chests.spawnOne(CFrame.new(AbilityKit.groundAt(spot)), folder, rng)
			end
		end
		return
	end
	ensureModel()
	route = spots
	mode = if #route > 0 then "Airdrop" else "Leaving"
end

function BalloonPilot.finish()
	despawn()
	escapeEnabled = false
end

Players.PlayerRemoving:Connect(function()
	checkTimer = Balloon.CheckSeconds -- re-check the alive count right away
end)

return BalloonPilot
