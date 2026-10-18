--!strict
-- Cymbal Monkey (§6.6): 1 use. Throw it; where it lands, worms within Radius are disoriented for 12 s
-- (they see no Pardners, props or pings). TODO: wormlings too, once they exist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local WormService = require(script.Parent.Parent.Services.WormService)
local Projectile = require(script.Parent.Parent.Util.Projectile)

local CymbalMonkey: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local params = context.params
		Projectile.throw(context.root, "CymbalMonkey", context.direction, params.ThrowSpeed, function(position)
			-- TODO(asset): cymbal clash sound + effect
			WormService.disorient(position, params.Radius, params.DisorientSeconds)
		end)
		return true
	end,
}

return CymbalMonkey
