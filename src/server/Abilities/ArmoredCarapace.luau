--!strict
-- Armored Carapace (§12): a shell for Seconds. It shrugs off the first hit (and ends), and the first
-- structure the worm pounces into is flattened (and ends) — WormService handles both. Coming up out of
-- the sand with the shell on blasts sand at nearby Pardners: −30 stamina, +30 % stamina use and +30 %
-- damage taken for 15 s.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local Types = require(ReplicatedStorage.Shared.Types)
local AbilityService = require(script.Parent.Parent.Services.AbilityService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local WormService = require(script.Parent.Parent.Services.WormService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

local Params = Abilities.ArmoredCarapace.params

WormService.surfaced:connect(function(player: Player, position: Vector3)
	if not WormService.hasCarapace(player) then
		return
	end
	local now = os.clock()
	for pardner in AbilityKit.pardnersNear(position, Params.BlastRadius) do
		PardnerService.drainStamina(pardner, Params.BlastStaminaLoss)
		PardnerService.addStatus(pardner, {
			id = "CarapaceBlast",
			expires = now + Params.BlastDebuffSeconds,
			staminaUseMult = Params.BlastStaminaUseMult,
			damageTakenMult = Params.BlastDamageTakenMult,
		})
	end
	for _, worm in WormService.getWorms() do
		if worm.player == player then
			AbilityService.playFx("ArmoredCarapace", worm.model, { position = position, radius = Params.BlastRadius })
		end
	end
end)

local ArmoredCarapace: Types.AbilityModule = {
	activate = function(context: Types.AbilityContext): boolean
		WormService.setCarapace(context.player, Workspace:GetServerTimeNow() + context.params.Seconds)
		context.notify("Carapace up")
		return true
	end,
}

return ArmoredCarapace
