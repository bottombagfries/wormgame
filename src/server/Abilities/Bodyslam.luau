--!strict
-- Bodyslam (§12): mid-air only. The worm dives straight down; where it lands, a 30-stud-wide impact deals
-- 10 damage to Pardners and knocks them back, does 1 damage to structures, unearths anything buried,
-- and leaves a crater.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local Types = require(ReplicatedStorage.Shared.Types)
local AbilityService = require(script.Parent.Parent.Services.AbilityService)
local DigService = require(script.Parent.Parent.Services.DigService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local StructureService = require(script.Parent.Parent.Services.StructureService)
local WormService = require(script.Parent.Parent.Services.WormService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

local function modeOf(player: Player): string?
	for _, worm in WormService.getWorms() do
		if worm.player == player then
			return worm.mode
		end
	end
	return nil
end

local function impact(context: Types.AbilityContext, position: Vector3)
	local params = context.params
	local radius = params.ImpactWidth / 2
	for player, root in AbilityKit.pardnersNear(position, radius) do
		PardnerService.damage(player, params.PardnerDamage)
		local away = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
		local push = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
		PardnerService.impulse(player, (push + Vector3.yAxis).Unit * params.Knockback)
	end
	for _, model in StructureService.getInRadius(position, radius) do
		StructureService.damage(model, params.StructureDamage, "Worm")
	end
	DigService.digAt(position, radius)

	local crater = AssetService.get("Crater") -- TODO(asset): crater decal
	for _, descendant in crater:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.Size = Vector3.new(params.ImpactWidth, descendant.Size.Y, params.ImpactWidth)
		elseif descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	crater:PivotTo(CFrame.new(position))
	crater.Parent = context.folder
	task.delay(ItemTuning.CraterSeconds, function()
		crater:Destroy()
	end)
	AbilityService.playFx("Bodyslam", context.model, { position = position, radius = radius })
end

local Bodyslam: Types.AbilityModule = {
	canUse = function(context: Types.AbilityContext): (boolean, string?)
		if context.mode ~= "Airborne" then
			return false, "Bodyslam only works mid-air - pounce first"
		end
		return true, nil
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		WormService.launch(context.player, Vector3.yAxis * -params.DiveSpeed)
		task.spawn(function()
			local started = os.clock()
			while modeOf(context.player) == "Airborne" and os.clock() - started < params.LandTimeout do
				task.wait(params.LandPollSeconds)
			end
			if context.head.Parent then
				impact(context, AbilityKit.groundAt(context.head.Position))
			end
		end)
		return true
	end,
}

return Bodyslam
