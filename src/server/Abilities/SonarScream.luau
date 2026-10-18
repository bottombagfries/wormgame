--!strict
-- Sonar Scream (§12): for RevealSeconds the worm sees every Pardner and prop within Radius — the whole
-- map after sundown, with a shorter cooldown. DetectionService and WormVisionController read the reveal
-- from the worm model's attributes RevealUntil / RevealCenter / RevealRadius (-1 = everywhere).
-- TODO: also cattlebugs, ziplines and the balloon once worms can lose sight of them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local Types = require(ReplicatedStorage.Shared.Types)
local AbilityService = require(script.Parent.Parent.Services.AbilityService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local EVERYWHERE = -1

local SonarScream: Types.AbilityModule = {
	cooldown = function(context: Types.AbilityContext): number
		return if context.night then context.params.NightCooldown else Abilities.SonarScream.cooldown
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		local radius = if context.night then EVERYWHERE else params.Radius
		local model = context.model
		model:SetAttribute("RevealUntil", Workspace:GetServerTimeNow() + params.RevealSeconds)
		model:SetAttribute("RevealCenter", context.position)
		model:SetAttribute("RevealRadius", radius)
		AbilityService.playFx("SonarScream", model, { position = context.position, radius = params.Radius })
		SoundCue.play("SonarScream", context.position)
		return true
	end,
}

return SonarScream
