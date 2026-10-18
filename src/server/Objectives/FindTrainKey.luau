--!strict
-- Objective 2 (§10): the Train Key is buried with a skeleton somewhere in a DigArea, among
-- `horseshoes` decoy horseshoes. The Shovel's metal detector points at the nearest of them while
-- the key is still buried. Dig it up (shovel, dynamite, or a worm bodyslam), carry it to the Train
-- and put it in the keyhole.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Types = require(ReplicatedStorage.Shared.Types)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local DigService = require(script.Parent.Parent.Services.DigService)
local MapService = require(script.Parent.Parent.Services.MapService)
local TrainService = require(script.Parent.Parent.Services.TrainService)

local Params = Objectives.FindTrainKey.params :: { [string]: any }
local Tags = TagDefs.Tags

-- Buries one item at a random sand point inside a random DigArea.
local function buryInArea(areas: { BasePart }, itemId: string, options: DigService.BuryOptions, rng: Random): boolean
	for _ = 1, Params.BuryAttempts do
		local area = RandomUtil.pick(areas, rng)
		if DigService.bury(itemId, Geometry.randomPointInPart(area, rng), options) then
			return true
		end
	end
	warn(`[FindTrainKey] Could not find sand in any DigArea to bury {itemId}`)
	return false
end

local FindTrainKey: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		local rng = Random.new()
		local keyOptions: DigService.BuryOptions = {
			detectable = true,
			extraAssetId = "Skeleton", -- TODO(asset): Skeleton
			extraOffset = Params.SkeletonOffset,
			-- Once the key is out, the detector has nothing left to find (§10.2).
			onUnearthed = function()
				DigService.setDetectorActive(false)
			end,
		}
		local areas = MapService.getMarkers(Tags.DigArea)
		if #areas == 0 then
			warn("[FindTrainKey] No DigArea markers - burying the key next to the Train")
			local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]
			DigService.bury("TrainKey", trainSpot.Position + Params.FallbackOffset, keyOptions)
		else
			buryInArea(areas, "TrainKey", keyOptions, rng)
			local difficulty = Difficulty[context.difficulty] or Difficulty[GameConfig.DefaultDifficulty]
			for _ = 1, difficulty.horseshoes do
				buryInArea(areas, "Horseshoe", { detectable = true }, rng)
			end
		end
		DigService.setDetectorActive(true)
		TrainService.setKeyholeActive(true)
	end,

	getProgress = function(): (number, number)
		return if TrainService.isKeyInserted() then 1 else 0, 1
	end,

	cleanup = function()
		DigService.clear()
		TrainService.setKeyholeActive(false)
	end,
}

return FindTrainKey
