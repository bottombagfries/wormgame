--!strict
-- Who the worms can sense (§8.1, §8.2). A Pardner makes a ground ping only while standing on sand
-- AND moving. Standing still, or standing on any prop / structure / item, is invisible.
--
-- What a worm receives depends on its mode: underground = every ping on the map; above ground =
-- only pings within SurfaceVisionRadius; airborne = nothing.
--   Worm_Pings({ Vector3 })    ping positions, sent each tick
--   Worm_Visible({ userId })   Pardners whose characters this worm's client may show

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Net = require(ReplicatedStorage.Shared.Net)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local PardnerService = require(script.Parent.PardnerService)
local WormService = require(script.Parent.WormService)

type Ping = { player: Player, position: Vector3, revealed: boolean }

local DetectionService = {}

local pingsRemote: RemoteEvent
local visibleRemote: RemoteEvent
local timer = 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function isOnSand(root: BasePart): boolean
	local character = root.Parent
	rayParams.FilterDescendantsInstances = if character then { character } else {}
	local result = Workspace:Raycast(root.Position, Vector3.yAxis * -WormConfig.SandProbeDown, rayParams)
	return result ~= nil and Ground.isSand(result)
end

local function collectPings(): { Ping }
	local pings = {}
	for player, root in PardnerService.getLiving() do
		local stats = PardnerService.getStats(player)
		if stats and stats.grabbed then
			continue
		end
		local velocity = root.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		-- Revealed Pardners (Coffee Tin, Concoction) show up wherever they are and whatever they do.
		local revealed = PardnerService.isRevealed(player)
		if revealed or (speed > PardnerConfig.PingSpeed and isOnSand(root)) then
			table.insert(pings, { player = player, position = root.Position, revealed = revealed })
		end
	end
	-- TODO(Phase 8+): thrown items moving on sand also ping; held-up items touching sand are visible.
	return pings
end

local function update()
	local worms = WormService.getWorms()
	if #worms == 0 then
		return
	end

	local pings = collectPings()
	for _, worm in worms do
		local positions: { Vector3 } = {}
		local visible: { number } = {}
		-- Disoriented (cymbal monkey, train horn): no Pardners, no pings at all.
		if worm.mode ~= "Airborne" and not WormService.isDisoriented(worm.player) then
			for _, ping in pings do
				local inRange = worm.mode == "Underground"
					or ping.revealed
					or (ping.position - worm.position).Magnitude <= WormConfig.SurfaceVisionRadius
				if inRange then
					table.insert(positions, ping.position)
					table.insert(visible, ping.player.UserId)
				end
			end
		end
		if worm.grabbed then
			table.insert(visible, worm.grabbed.UserId)
		end

		-- Sonar Scream (§12): every Pardner within the scream's radius (-1 = the whole map) is shown.
		local model = worm.model
		local revealUntil = model:GetAttribute("RevealUntil")
		local revealCenter = model:GetAttribute("RevealCenter")
		local revealRadius = model:GetAttribute("RevealRadius")
		local revealing = typeof(revealUntil) == "number"
			and Workspace:GetServerTimeNow() < revealUntil
			and typeof(revealCenter) == "Vector3"
			and typeof(revealRadius) == "number"
		if revealing and not WormService.isDisoriented(worm.player) then
			for player, root in PardnerService.getLiving() do
				local inside = revealRadius < 0 or (root.Position - revealCenter).Magnitude <= revealRadius
				if inside and not table.find(visible, player.UserId) then
					table.insert(visible, player.UserId)
				end
			end
		end

		pingsRemote:FireClient(worm.player, positions)
		visibleRemote:FireClient(worm.player, visible)
	end
end

function DetectionService.init()
	pingsRemote = Net.event("Worm_Pings")
	visibleRemote = Net.event("Worm_Visible")
end

function DetectionService.start()
	RunService.Heartbeat:Connect(function(dt)
		timer += dt
		if timer >= WormConfig.DetectionTickSeconds then
			timer = 0
			update()
		end
	end)
end

return DetectionService
