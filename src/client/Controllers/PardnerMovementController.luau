--!strict
-- Pardner sprint, jump cost, and wall climbing on the owning client (§8.1).
-- Sends intents to PardnerService and predicts stamina/grip with PardnerLogic between server updates.
--
-- Climbing: jump at any wall while pushing toward it to grab on. W/S/A/D move along the wall,
-- Jump leaps upward (costs grip), LetGo drops off. Climbing over the top mantles onto the ledge.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local PardnerLogic = require(ReplicatedStorage.Shared.PardnerLogic)
local InputController = require(script.Parent.InputController)
local MatchController = require(script.Parent.MatchController)

type ClimbState = {
	normal: Vector3, -- horizontal unit vector pointing out of the wall
	attachment: Attachment,
	velocity: LinearVelocity,
	align: AlignOrientation,
	startedAt: number,
	jumpUntil: number,
	lastJump: number,
}

local PardnerMovementController = {}

local player = Players.LocalPlayer

local stats = PardnerLogic.new()
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local climb: ClimbState? = nil
local regrabAt = 0
local sentSprint = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local climbRemote: RemoteEvent
local sprintRemote: RemoteEvent
local jumpRemote: RemoteEvent

local function flatNormal(normal: Vector3): Vector3
	return Vector3.new(normal.X, 0, normal.Z).Unit
end

-- A climbable wall along `ray` from `origin`, or nil. Loose items and other characters don't count.
local function findWall(origin: Vector3, ray: Vector3): RaycastResult?
	local result = Workspace:Raycast(origin, ray, rayParams)
	-- Tar spires (§12 Tar Wall) are marked NoClimb.
	local climbable = result ~= nil
		and result.Instance.Anchored
		and result.Instance:GetAttribute("NoClimb") ~= true
		and math.abs(result.Normal.Y) <= PardnerConfig.ClimbMaxNormalY
	if result and climbable then
		return result
	end
	return nil
end

local function stopClimb()
	local state = climb
	if not state then
		return
	end
	climb = nil
	regrabAt = os.clock() + PardnerConfig.ClimbRegrabCooldown
	state.velocity:Destroy()
	state.align:Destroy()
	state.attachment:Destroy()
	climbRemote:FireServer(false)
end

local function startClimb(rootPart: BasePart, normal: Vector3)
	-- TODO(asset): climb animation (the default falling animation plays for now)
	local attachment = Instance.new("Attachment")
	attachment.Name = "ClimbAttachment"
	attachment.Parent = rootPart

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "ClimbVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = PardnerConfig.ClimbMaxForce
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = rootPart

	local align = Instance.new("AlignOrientation")
	align.Name = "ClimbAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.CFrame = CFrame.lookAt(Vector3.zero, -normal)
	align.Parent = rootPart

	climb = {
		normal = normal,
		attachment = attachment,
		velocity = velocity,
		align = align,
		startedAt = os.clock(),
		jumpUntil = 0,
		lastJump = 0,
	}
	climbRemote:FireServer(true)
end

local function updateClimb(state: ClimbState, hum: Humanoid, rootPart: BasePart, move: Vector3, now: number)
	local up = -move.Z
	local reach = PardnerConfig.ClimbReach + PardnerConfig.ClimbWallOffset
	local hit = findWall(rootPart.Position, -state.normal * reach)

	if not hit then
		-- Ran out of wall. Going up means we reached the top: hop onto the ledge.
		local normal = state.normal
		stopClimb()
		if up > 0 then
			rootPart.AssemblyLinearVelocity = Vector3.yAxis * PardnerConfig.MantleUpSpeed
				- normal * PardnerConfig.MantleForwardSpeed
		end
		return
	end

	-- Climbed down onto the ground.
	if up < 0 and hum.FloorMaterial ~= Enum.Material.Air then
		stopClimb()
		return
	end

	state.normal = flatNormal(hit.Normal)
	local right = (-state.normal):Cross(Vector3.yAxis)
	local vertical = if now < state.jumpUntil then PardnerConfig.ClimbJumpSpeed else up * PardnerConfig.ClimbSpeed
	local stick = -state.normal * ((hit.Distance - PardnerConfig.ClimbWallOffset) * PardnerConfig.ClimbStickGain)

	state.velocity.VectorVelocity = Vector3.yAxis * vertical + right * (move.X * PardnerConfig.ClimbSpeed) + stick
	state.align.CFrame = CFrame.lookAt(Vector3.zero, -state.normal)
end

local function update(dt: number)
	local hum, rootPart = humanoid, root
	if not hum or not rootPart or hum.Health <= 0 then
		return
	end
	-- Worms, spectators and players in the lobby move like a plain Roblox character.
	if not MatchController.isPardner() then
		if climb then
			stopClimb()
		end
		return
	end

	local now = os.clock()
	local move = InputController.getMoveVector()
	local airborne = hum.FloorMaterial == Enum.Material.Air
	local moveDirection = hum.MoveDirection

	if climb then
		updateClimb(climb, hum, rootPart, move, now)
	elseif airborne and now >= regrabAt and moveDirection.Magnitude > 0.1 and PardnerLogic.canClimb(stats) then
		local hit = findWall(rootPart.Position, moveDirection.Unit * PardnerConfig.ClimbReach)
		if hit then
			startClimb(rootPart, flatNormal(hit.Normal))
		end
	end

	local wantsSprint = InputController.isSprintHeld()
	if wantsSprint ~= sentSprint then
		sentSprint = wantsSprint
		sprintRemote:FireServer(wantsSprint)
	end

	PardnerLogic.step(stats, {
		wantsSprint = wantsSprint,
		wantsClimb = climb ~= nil,
		moving = moveDirection.Magnitude > 0,
		grounded = not airborne,
	}, dt)

	-- Out of grip and stamina: fall.
	if climb and not stats.climbing then
		stopClimb()
	end

	hum.WalkSpeed = PardnerLogic.walkSpeed(stats)
end

local function onJumpPressed()
	local state = climb
	if not state then
		return -- ground jumps are picked up from the Humanoid state change
	end
	local now = os.clock()
	if now - state.lastJump >= PardnerConfig.ClimbJumpCooldown and stats.grip > 0 then
		state.lastJump = now
		state.jumpUntil = now + PardnerConfig.ClimbJumpSeconds
		PardnerLogic.applyClimbJump(stats)
		jumpRemote:FireServer()
	end
end

local function onServerState(serverStats: PardnerLogic.Stats)
	stats = serverStats
	-- The server refused or ended the climb (give it a moment to hear about a new one first).
	local state = climb
	if state and not serverStats.climbing and os.clock() - state.startedAt > PardnerConfig.ClimbConfirmGrace then
		stopClimb()
	end
end

local function onCharacter(character: Model)
	climb = nil -- the old character took its constraints with it
	humanoid = nil
	root = nil
	sentSprint = false

	local hum = character:WaitForChild("Humanoid") :: Humanoid
	local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	if player.Character ~= character then
		return
	end

	stats = PardnerLogic.new()
	rayParams.FilterDescendantsInstances = { character }
	humanoid = hum
	root = rootPart

	hum.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Jumping and not climb then
			PardnerLogic.applyJump(stats)
			jumpRemote:FireServer()
		end
	end)
	hum.Died:Connect(stopClimb)
end

function PardnerMovementController.getStats(): PardnerLogic.Stats
	return stats
end

function PardnerMovementController.isClimbing(): boolean
	return climb ~= nil
end

function PardnerMovementController.init()
	climbRemote = Net.event("Request_Climb")
	sprintRemote = Net.event("Request_Sprint")
	jumpRemote = Net.event("Request_Jump")
end

function PardnerMovementController.start()
	Net.event("State_Pardner").OnClientEvent:Connect(onServerState)
	-- Recoil, pogo jumps: the server asks; this client owns the character, so it applies them.
	Net.event("Pardner_Impulse").OnClientEvent:Connect(function(velocity: Vector3)
		local rootPart = root
		if rootPart then
			stopClimb()
			rootPart.AssemblyLinearVelocity += velocity
		end
	end)
	InputController.jumpPressed:connect(onJumpPressed)
	InputController.letGoPressed:connect(stopClimb)

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	RunService.Heartbeat:Connect(update)
end

return PardnerMovementController
