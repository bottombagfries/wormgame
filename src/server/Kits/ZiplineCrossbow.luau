--!strict
-- Zipline Crossbow (§6.6): fires a harpoon along the aim; a zipline runs from the shooter to where it
-- hits. Anyone can hold F at either end to ride to the other end. Ziplines last the whole match.
-- While riding, the server holds the rider's root part (like a worm grab) and slides it along the line.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Types = require(ReplicatedStorage.Shared.Types)
local MapService = require(script.Parent.Parent.Services.MapService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local TrainConfig = GameConfig.Train
local IGNORED_FOLDERS = { "Items", "Worms", "Ghosts", "NPCs" }

local riding: { [Player]: boolean } = {}

local function ride(player: Player, from: Vector3, to: Vector3, params: { [string]: any })
	local root = PardnerService.getLiving()[player]
	if not root or riding[player] then
		return
	end
	local stats = PardnerService.getStats(player)
	if not stats or stats.grabbed then
		return
	end
	riding[player] = true
	root.Anchored = true

	local length = (to - from).Magnitude
	local direction = (to - from).Unit
	local hang = Vector3.yAxis * -params.HangDrop
	local travelled = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt)
		local current = PardnerService.getStats(player)
		local stillHere = root.Parent ~= nil and player.Parent ~= nil
		travelled += params.RideSpeed * dt
		if not stillHere or not current or current.health <= 0 or current.grabbed or travelled >= length then
			connection:Disconnect()
			riding[player] = nil
			if root.Parent then
				root.Anchored = false
				root.AssemblyLinearVelocity = direction * params.RideSpeed
				pcall(function()
					root:SetNetworkOwner(player)
				end)
			end
			return
		end
		local point = from + direction * travelled + hang
		root.CFrame = CFrame.lookAt(point, point + Vector3.new(direction.X, 0, direction.Z))
	end)
end

local function makeEnd(parent: Instance, position: Vector3, other: Vector3, params: { [string]: any })
	local anchor = Instance.new("Part")
	anchor.Name = "ZiplineEnd"
	anchor.Size = params.EndSize
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Position = position
	anchor.Parent = parent

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Zipline"
	prompt.ActionText = "Ride"
	prompt.HoldDuration = params.RideHoldSeconds
	prompt.MaxActivationDistance = TrainConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	prompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player)
		local root = PardnerService.getLiving()[player]
		local reach = TrainConfig.PromptDistance + TrainConfig.PromptSlack
		if root and (root.Position - position).Magnitude <= reach then
			ride(player, position, other, params)
		end
	end)
end

local ZiplineCrossbow: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local params = context.params
		local origin = context.root.Position + Vector3.yAxis * PardnerConfig.ThrowOriginHeight

		local ignore: { Instance } = { context.root.Parent :: Instance }
		for _, name in IGNORED_FOLDERS do
			local folder = Workspace:FindFirstChild(name)
			if folder then
				table.insert(ignore, folder)
			end
		end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = ignore
		rayParams.RespectCanCollide = true
		local hit = Workspace:Raycast(origin, context.direction * params.Range, rayParams)
		if not hit or hit.Distance < params.MinLength then
			context.notify("The harpoon found nothing to hook into")
			return false
		end

		local parent = MapService.getRuntimeFolder() or Workspace
		local target = hit.Position
		local length = (target - origin).Magnitude
		local rope = AssetService.get("ZiplineRope") -- TODO(asset): rope + harpoon models, twang sound
		local part = rope.PrimaryPart :: BasePart
		for _, descendant in rope:GetDescendants() do
			if descendant:IsA("BillboardGui") then
				descendant:Destroy()
			end
		end
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Size = Vector3.new(params.LineWidth, params.LineWidth, length)
		part.CFrame = CFrame.lookAt(origin, target) * CFrame.new(0, 0, -length / 2)
		rope.Name = "Zipline"
		rope.Parent = parent

		makeEnd(rope, origin, target, params)
		makeEnd(rope, target, origin, params)
		context.notify("Zipline up! Hold F at either end to ride it")
		return true
	end,
}

Players.PlayerRemoving:Connect(function(player)
	riding[player] = nil
end)

return ZiplineCrossbow
