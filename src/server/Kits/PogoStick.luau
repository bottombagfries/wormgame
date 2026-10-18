--!strict
-- Pogo Stick (§6.6): 5 uses. A big jump straight up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local PogoStick: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local stats = PardnerService.getStats(context.player)
		if not stats or stats.grabbed or stats.climbing then
			return false
		end
		PardnerService.impulse(context.player, Vector3.yAxis * context.params.LaunchSpeed) -- TODO(asset): boing
		return true
	end,
}

return PogoStick
