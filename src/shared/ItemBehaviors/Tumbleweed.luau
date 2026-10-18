--!strict
-- Tumbleweed (§6.4): lit at the Train's furnace (the LightSignalFires objective does that), it burns
-- for TumbleweedBurnSeconds and is then gone. Blasts don't light it, and it can't be lit by hand.

local ItemTuning = require(script.Parent.Parent.Config.ItemTuning)
local Types = require(script.Parent.Parent.Types)

local Tumbleweed: Types.ItemBehavior = {
	fuseSeconds = ItemTuning.TumbleweedBurnSeconds,
	litEffect = "Fire",
}

return Tumbleweed
