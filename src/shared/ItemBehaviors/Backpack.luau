--!strict
-- Backpack (§6.5): +BackpackSlots bag slots permanently. Stacks, and is kept through death.

local PardnerConfig = require(script.Parent.Parent.Config.Pardner)
local Types = require(script.Parent.Parent.Types)

local Backpack: Types.ItemBehavior = {
	onInstantUse = function(context: Types.ItemUseContext)
		context.addBagSlots(PardnerConfig.BackpackSlots)
	end,
}

return Backpack
