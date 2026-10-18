--!strict
-- Sandstorm (§12): a tornado leaves the worm along its aim and wanders for Seconds. Pardners and loose
-- props caught in it are flung about; caught Pardners are revealed to the worm for a while.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Types = require(ReplicatedStorage.Shared.Types)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local AbilityKit = require(script.Parent.Parent.Util.AbilityKit)

local function randomFling(rng: Random, speed: number): Vector3
	local angle = rng:NextNumber(0, math.pi * 2)
	return (Vector3.new(math.cos(angle), 1, math.sin(angle))).Unit * speed
end

local Sandstorm: Types.AbilityModule = {
	activate = function(context: Types.AbilityContext): boolean
		local params = context.params
		local flat = Vector3.new(context.direction.X, 0, context.direction.Z)
		local heading = if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis
		local center = AbilityKit.groundAt(context.position)

		local tornado = AssetService.get("Tornado") -- TODO(asset): tornado effect + wind sound
		local greybox = tornado:GetAttribute("Greybox") == true
		for _, descendant in tornado:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				if greybox then
					descendant.Size = Vector3.new(params.Height, params.Radius * 2, params.Radius * 2)
					descendant.Transparency = WormConfig.ZoneTransparency
				end
			elseif descendant:IsA("BillboardGui") then
				descendant:Destroy()
			end
		end
		tornado.Parent = context.folder

		local rng = Random.new()
		local lastFling: { [any]: number } = {}
		AbilityKit.forSeconds(params.Seconds, function()
			center = AbilityKit.groundAt(center + heading * params.MoveSpeed * WormConfig.AbilityTickSeconds)
			-- Drift a little so it wanders.
			heading = (heading + Vector3.new(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))).Unit
			local up = CFrame.new(center + Vector3.yAxis * params.Height / 2)
			tornado:PivotTo(if greybox then up * CFrame.Angles(0, 0, math.pi / 2) else up)

			local now = os.clock()
			for player in AbilityKit.pardnersNear(center, params.Radius, true) do
				if now - (lastFling[player] or 0) >= params.FlingInterval then
					lastFling[player] = now
					PardnerService.impulse(player, randomFling(rng, params.FlingSpeed))
					PardnerService.addStatus(player, {
						id = "SandstormReveal",
						expires = now + params.RevealSeconds,
						revealed = true,
					})
				end
			end
			for _, model in ItemService.getLooseNear(center, params.Radius) do
				if now - (lastFling[model] or 0) >= params.FlingInterval then
					lastFling[model] = now
					ItemService.push(model, randomFling(rng, params.FlingSpeed))
				end
			end
			return nil
		end, function()
			tornado:Destroy()
		end)
		return true
	end,
}

return Sandstorm
