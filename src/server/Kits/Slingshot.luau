--!strict
-- Slingshot (§6.6): passive. Throws go 50 % harder while it's in the kit slot.
-- ItemService applies Config.Kits.Slingshot.params.PassiveThrowPowerMult when throwing (and the client's
-- aim arc reads the same number), so there's nothing to do here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local Slingshot: Types.KitModule = {}

return Slingshot
