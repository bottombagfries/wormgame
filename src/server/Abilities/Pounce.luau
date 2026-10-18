--!strict
-- Pounce (§12): launch toward the aim; grabs a Pardner / swallows items in the path and hits
-- structures (WormService does the flight). Much farther when bursting out of the sand. Ends Stealth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local WormService = require(script.Parent.Parent.Services.WormService)

local Pounce: Types.AbilityModule = {
	activate = function(context: Types.AbilityContext): boolean
		local ok, reason = WormService.pounce(context.player, context.direction)
		if reason then
			context.notify(reason)
		end
		if ok then
			context.model:SetAttribute("StealthUntil", nil)
		end
		return ok
	end,
}

return Pounce
