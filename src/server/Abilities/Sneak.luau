--!strict
-- Sneak (§12): hold. Slower, and no dirt mound for Pardners to spot. Payload: { state = boolean }.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local WormService = require(script.Parent.Parent.Services.WormService)

local Sneak: Types.AbilityModule = {
	activate = function(context: Types.AbilityContext, payload: { [string]: any }): boolean
		WormService.setSneaking(context.player, payload.state == true)
		return false -- no cooldown
	end,
}

return Sneak
