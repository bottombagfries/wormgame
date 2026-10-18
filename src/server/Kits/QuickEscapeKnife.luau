--!strict
-- Quick Escape Knife (§6.6): 1 use. Use it in a worm's mouth to get out at once (counts as an escape).
-- If the mouth would kill the holder first, it's used automatically (KitService + WormService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local WormService = require(script.Parent.Parent.Services.WormService)

local QuickEscapeKnife: Types.KitModule = {
	savesFromMouth = true,
	onUse = function(context: Types.KitContext): boolean
		if WormService.forceEscape(context.player) then
			return true
		end
		context.notify("Save the knife for when a worm has you")
		return false
	end,
}

return QuickEscapeKnife
