--!strict
-- Canteen (§6.6): passive. Jumping and sprinting cost 35 % less stamina while it's in the kit slot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Types = require(ReplicatedStorage.Shared.Types)

local Canteen: Types.KitModule = {
	passiveStaminaUseMult = Kits.Canteen.params.PassiveStaminaUseMult,
}

return Canteen
