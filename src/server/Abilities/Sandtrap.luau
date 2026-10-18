--!strict
-- Sandtrap (§12): above ground, on sand. Leaves a trap on the sand for Seconds. The first Pardner to
-- step in is pulled down, revealed, and held there by the worm until they win the mouth minigame
-- (WormService.trapGrab). A dynamite blast destroys traps it reaches.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local ExplosionService = require(script.Parent.Parent.Services.ExplosionService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local WormService = require(script.Parent.Parent.Services.WormService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

type Trap = { zone: Model, center: Vector3, radius: number, active: boolean }

local traps: { Trap } = {}

local function removeTrap(trap: Trap)
	trap.active = false
	trap.zone:Destroy()
	local index = table.find(traps, trap)
	if index then
		table.remove(traps, index)
	end
end

ExplosionService.exploded:connect(function(position: Vector3, radius: number)
	for index = #traps, 1, -1 do
		local trap = traps[index]
		if (trap.center - position).Magnitude <= radius + trap.radius then
			removeTrap(trap)
		end
	end
end)

local Sandtrap: Types.AbilityModule = {
	canUse = function(context: Types.AbilityContext): (boolean, string?)
		if context.mode ~= "Surface" then
			return false, "Surface on the sand to set a sandtrap"
		end
		local _, isSand = Ground.surfaceBelow(context.position)
		if not isSand then
			return false, "Sandtraps only work in sand"
		end
		return true, nil
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		local center = AbilityKit.groundAt(context.position)
		local trap: Trap = {
			zone = AbilityKit.zone("SandtrapZone", center, params.Radius, context.folder), -- TODO(asset): sandtrap
			center = center,
			radius = params.Radius,
			active = true,
		}
		table.insert(traps, trap)

		AbilityKit.forSeconds(params.Seconds, function()
			if not trap.active then
				return false
			end
			for pardner in AbilityKit.pardnersNear(center, params.Radius, true) do
				local hold = CFrame.new(center - Vector3.yAxis * params.HoldDepth)
				if WormService.trapGrab(context.player, pardner, hold) then
					PardnerService.addStatus(pardner, {
						id = "Sandtrap",
						expires = os.clock() + params.RevealSeconds,
						revealed = true,
					})
					removeTrap(trap)
					return false
				end
			end
			return nil
		end, function()
			if trap.active then
				removeTrap(trap)
			end
		end)
		return true
	end,
	cleanup = function()
		table.clear(traps)
	end,
}

return Sandtrap
