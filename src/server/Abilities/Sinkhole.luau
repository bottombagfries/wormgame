--!strict
-- Sinkhole (§12): a vortex on the sand above the worm; Pardners inside are slowed 80 % for Seconds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

local Sinkhole: Types.AbilityModule = {
	canUse = function(context: Types.AbilityContext): (boolean, string?)
		if context.mode == "Airborne" then
			return false, "Not while airborne"
		end
		return true, nil
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		local center = AbilityKit.groundAt(context.position)
		local zone = AbilityKit.zone("SinkholeZone", center, params.Radius, context.folder) -- TODO(asset): swirl
		AbilityKit.forSeconds(params.Seconds, function()
			for player in AbilityKit.pardnersNear(center, params.Radius, true) do
				AbilityKit.slow(player, "Sinkhole", params.SlowFraction)
			end
			return nil
		end, function()
			zone:Destroy()
		end)
		return true
	end,
}

return Sinkhole
