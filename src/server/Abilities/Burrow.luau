--!strict
-- Burrow / Unburrow (§12): toggle. Burrowing needs sand (unless forced by damage); surfacing needs
-- full health after being hurt. WormService does the rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local WormService = require(script.Parent.Parent.Services.WormService)

local Burrow: Types.AbilityModule = {
	activate = function(context: Types.AbilityContext): boolean
		local ok, reason = WormService.toggleBurrow(context.player)
		if reason then
			context.notify(reason)
		end
		return ok
	end,
}

return Burrow
