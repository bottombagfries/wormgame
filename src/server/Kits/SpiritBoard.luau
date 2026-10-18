--!strict
-- Spirit Board (§6.6): passive. The holder sees ghosts (GhostController, client side), runs faster for
-- every ghost (up to +30 %), and while any living Pardner carries one, ghost pushes recharge twice as
-- fast (ReviveService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Types = require(ReplicatedStorage.Shared.Types)
local ReviveService = require(script.Parent.Parent.Services.ReviveService)

local Params = Kits.SpiritBoard.params

local SpiritBoard: Types.KitModule = {
	passiveSpeedMult = function(_player: Player): number
		local bonus = math.min(Params.MaxSpeedBonus, Params.SpeedBonusPerGhost * ReviveService.getGhostCount())
		return 1 + bonus
	end,
}

return SpiritBoard
