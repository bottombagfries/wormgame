--!strict
-- A thrown, server-simulated object for kits (cactus seeds, cymbal monkey). It flies with physics and
-- calls onLand with the ground point once it has slowed down, touched the ground, or flown too long.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)

local Projectile = {}

-- Throws `assetId` from `root` along `direction` (unit) at `speed`.
function Projectile.throw(root: BasePart, assetId: string, direction: Vector3, speed: number, onLand: (Vector3) -> ())
	local model = AssetService.get(assetId) -- TODO(asset): thrown version of the kit
	local part = model.PrimaryPart :: BasePart
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanQuery = false
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	local origin = root.Position
		+ Vector3.yAxis * PardnerConfig.ThrowOriginHeight
		+ direction * (PardnerConfig.ThrowOriginForward + model:GetExtentsSize().Magnitude / 2)
	model:PivotTo(CFrame.new(origin))
	model.Parent = Workspace
	pcall(function()
		part:SetNetworkOwner(nil) -- the server decides where it lands
	end)
	part.AssemblyLinearVelocity = direction * speed

	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local age = os.clock() - started
		if not part.Parent then
			connection:Disconnect()
			return
		end
		if age < ItemTuning.ProjectileMinFlight then
			return
		end
		local position = part.Position
		local groundY = Ground.surfaceBelow(position)
		local nearGround = groundY ~= nil and position.Y - groundY <= part.Size.Y / 2 + ItemTuning.ProjectileGroundGap
		local slow = part.AssemblyLinearVelocity.Magnitude < ItemTuning.ProjectileLandSpeed
		if nearGround or slow or age >= ItemTuning.ProjectileMaxFlight then
			connection:Disconnect()
			model:Destroy()
			onLand(Vector3.new(position.X, groundY or position.Y, position.Z))
		end
	end)
end

return Projectile
