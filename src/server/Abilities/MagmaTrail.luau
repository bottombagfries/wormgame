--!strict
-- Magma Trail (§12): underground. For Seconds the worm leaves magma patches on the sand above it (each
-- lasts PatchSeconds). A Pardner on a patch takes DamagePerSecond, and keeps burning for LingerSeconds
-- after stepping off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Types = require(ReplicatedStorage.Shared.Types)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

local Params = Abilities.MagmaTrail.params

type Patch = { zone: Model, center: Vector3, expires: number }

local patches: { Patch } = {}
local lastBurned: { [Player]: number } = {} -- os.clock() a Pardner last stood on magma
local timer = 0

-- One damage tick for everyone on (or just off) the magma.
RunService.Heartbeat:Connect(function(dt)
	timer += dt
	if timer < WormConfig.AbilityTickSeconds then
		return
	end
	local elapsed = timer
	timer = 0
	local now = os.clock()
	for index = #patches, 1, -1 do
		local patch = patches[index]
		if now >= patch.expires then
			patch.zone:Destroy()
			table.remove(patches, index)
		end
	end
	for player, root in PardnerService.getLiving() do
		for _, patch in patches do
			local offset = root.Position - patch.center
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= Params.PatchRadius then
				lastBurned[player] = now
				break
			end
		end
		local burned = lastBurned[player]
		if burned and now - burned <= Params.LingerSeconds then
			PardnerService.damage(player, Params.DamagePerSecond * elapsed)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastBurned[player] = nil
end)

local MagmaTrail: Types.AbilityModule = {
	canUse = function(context: Types.AbilityContext): (boolean, string?)
		if context.mode ~= "Underground" then
			return false, "Burrow to leave a magma trail"
		end
		return true, nil
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		local sinceLast = math.huge
		local lastCenter: Vector3? = nil
		AbilityKit.forSeconds(params.Seconds, function()
			sinceLast += WormConfig.AbilityTickSeconds
			if sinceLast < params.PatchInterval or not context.head.Parent then
				return nil
			end
			local center = AbilityKit.groundAt(context.head.Position)
			-- Standing still doesn't stack patches on top of each other.
			if lastCenter and (center - lastCenter).Magnitude < params.PatchRadius then
				return nil
			end
			sinceLast = 0
			lastCenter = center
			table.insert(patches, {
				zone = AbilityKit.zone("MagmaPatch", center, params.PatchRadius, context.folder), -- TODO(asset)
				center = center,
				expires = os.clock() + params.PatchSeconds,
			})
			return nil
		end)
		return true
	end,
	cleanup = function()
		table.clear(patches)
		table.clear(lastBurned)
	end,
}

return MagmaTrail
