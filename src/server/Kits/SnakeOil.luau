--!strict
-- Snake Oil (§6.6): 2 uses, max one buff per Pardner. Permanent +10 % speed and 1–10 health back on every
-- mouth escape; kept through death (PardnerService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local SnakeOil: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		if PardnerService.giveSnakeOil(context.player) then
			context.notify("You feel slick. Faster for good, and tougher to keep down")
			return true
		end
		context.notify("You've already had your dose - give the rest to a pardner")
		return false
	end,
}

return SnakeOil
