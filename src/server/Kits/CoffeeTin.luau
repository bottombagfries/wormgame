--!strict
-- Coffee Tin (§6.6): 3 uses. +45 % speed and −80 % stamina use for 15 s, but the worms can see the
-- drinker anywhere for 20 s.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local CoffeeTin: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local params = context.params
		local now = os.clock()
		PardnerService.addStatus(context.player, {
			id = "CoffeeTin",
			expires = now + params.Seconds,
			speedMult = params.SpeedMult,
			staminaUseMult = params.StaminaUseMult,
		})
		PardnerService.addStatus(context.player, {
			id = "CoffeeTinReveal",
			expires = now + params.RevealSeconds,
			revealed = true,
		})
		context.notify("Coffee! You're fast - and the worms can hear you")
		return true
	end,
}

return CoffeeTin
