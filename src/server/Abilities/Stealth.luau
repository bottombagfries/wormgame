--!strict
-- Stealth (§12): for Seconds, or until the next pounce, no tremors: Pardners don't see the dirt mound
-- even while the worm moves (WormController reads the worm model's StealthUntil attribute).
-- TODO(asset): also silences worm sounds and breach particles once those exist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types)

local Stealth: Types.AbilityModule = {
	activate = function(context: Types.AbilityContext): boolean
		context.model:SetAttribute("StealthUntil", Workspace:GetServerTimeNow() + context.params.Seconds)
		context.notify("You move without a sound")
		return true
	end,
}

return Stealth
