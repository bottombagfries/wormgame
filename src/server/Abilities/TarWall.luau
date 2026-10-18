--!strict
-- Tar Wall (§12): not mid-air. A ring of tar spires around the worm for Seconds. Pardners can't pass
-- them (they collide) or climb them (attribute NoClimb, checked by the climbing code); being right next
-- to one slows you. Worms pass through freely (the worm never collides with anything).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Types = require(ReplicatedStorage.Shared.Types)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

local TarWall: Types.AbilityModule = {
	canUse = function(context: Types.AbilityContext): (boolean, string?)
		if context.mode == "Airborne" then
			return false, "Not while airborne"
		end
		return true, nil
	end,
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		local center = AbilityKit.groundAt(context.position)
		local spires: { Model } = {}
		local positions: { Vector3 } = {}
		for index = 1, params.Spires do
			local angle = index / params.Spires * math.pi * 2
			local ground =
				AbilityKit.groundAt(center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * params.Radius)
			local spire = AssetService.get("TarSpire") -- TODO(asset): tar spire + bubbling sound
			for _, descendant in spire:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
					descendant.CanCollide = true
					descendant:SetAttribute("NoClimb", true)
				elseif descendant:IsA("BillboardGui") then
					descendant:Destroy()
				end
			end
			local height = spire:GetExtentsSize().Y
			spire:PivotTo(CFrame.new(ground + Vector3.yAxis * height / 2))
			spire.Parent = context.folder
			table.insert(spires, spire)
			table.insert(positions, ground)
		end

		AbilityKit.forSeconds(params.Seconds, function()
			for player, root in AbilityKit.pardnersNear(center, params.Radius + params.SlowDistance, true) do
				for _, position in positions do
					local offset = root.Position - position
					if Vector3.new(offset.X, 0, offset.Z).Magnitude <= params.SlowDistance then
						AbilityKit.slow(player, "TarWall", params.SlowFraction)
						break
					end
				end
			end
			return nil
		end, function()
			for _, spire in spires do
				spire:Destroy()
			end
		end)
		return true
	end,
}

return TarWall
