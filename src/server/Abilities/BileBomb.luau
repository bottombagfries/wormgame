--!strict
-- Bile Bomb (§12): above ground. Spits a sticky glob along the aim. It sticks where it lands — or to a
-- Pardner it lands on — and bursts after FuseSeconds for Damage to every Pardner in Radius.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Types = require(ReplicatedStorage.Shared.Types)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)
local Projectile = require(script.Parent.Parent.Util.Projectile)

local function burst(position: Vector3, params: { [string]: any })
	local visual = Instance.new("Explosion") -- TODO(asset): bile splash + sound (visual only, no damage)
	visual.Position = position
	visual.BlastRadius = params.Radius
	visual.BlastPressure = 0
	visual.DestroyJointRadiusPercent = 0
	visual.ExplosionType = Enum.ExplosionType.NoCraters
	visual.Parent = Workspace
	Debris:AddItem(visual, params.BurstVisualSeconds)
	for player in AbilityKit.pardnersNear(position, params.Radius) do
		PardnerService.damage(player, params.Damage)
	end
end

local BileBomb: Types.AbilityModule = {
	canUse = function(context: Types.AbilityContext): (boolean, string?)
		if context.mode == "Underground" then
			return false, "Surface to spit bile"
		end
		return true, nil
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		Projectile.throw(context.head, "BileBomb", context.direction, params.LaunchSpeed, function(position)
			-- Stick to the nearest Pardner it landed on, if any.
			local stuckTo: BasePart? = nil
			for _, root in AbilityKit.pardnersNear(position, params.StickRadius) do
				stuckTo = root
				break
			end
			local glob = AssetService.get("BileBomb") -- TODO(asset): bile glob
			for _, descendant in glob:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
					descendant.CanCollide = false
					descendant.CanQuery = false
				elseif descendant:IsA("BillboardGui") then
					descendant:Destroy()
				end
			end
			glob:PivotTo(CFrame.new(position))
			glob.Parent = context.folder

			AbilityKit.forSeconds(params.FuseSeconds, function()
				if stuckTo and stuckTo.Parent then
					glob:PivotTo(stuckTo.CFrame)
				end
				return nil
			end, function()
				local at = glob:GetPivot().Position
				glob:Destroy()
				burst(at, params)
			end)
		end)
		return true
	end,
}

return BileBomb
