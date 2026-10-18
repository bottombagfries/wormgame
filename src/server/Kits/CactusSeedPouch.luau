--!strict
-- Cactus Seed Pouch (§6.6): 7 throws. Each seed grows a tall cactus where it lands (a small one near the
-- Train). Cacti are destructible like the map's own.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local StructureBuilder = require(script.Parent.Parent.Map.StructureBuilder)
local MapService = require(script.Parent.Parent.Services.MapService)
local StructureService = require(script.Parent.Parent.Services.StructureService)
local Projectile = require(script.Parent.Parent.Util.Projectile)

local CactusSeedPouch: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local params = context.params
		Projectile.throw(context.root, "CactusSeed", context.direction, params.ThrowSpeed, function(position)
			local parent = MapService.getRuntimeFolder()
			if not parent then
				return
			end
			local trainSpot = MapService.getMarkerCFrames(TagDefs.Tags.TrainSpot, CFrame.identity)[1].Position
			local nearTrain = (position - trainSpot).Magnitude <= params.SmallCactusTrainRadius
			local cactus =
				StructureBuilder.build(if nearTrain then "CactusSmall" else "CactusTall", CFrame.new(position))
			cactus.Parent = parent
			StructureService.register(cactus, "Cactus")
		end)
		return true
	end,
}

return CactusSeedPouch
