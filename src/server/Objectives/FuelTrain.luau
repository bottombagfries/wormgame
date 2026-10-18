--!strict
-- Objective 1 (§10): throw fuel items into the furnace until the meter reads 100. Always active.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local TrainService = require(script.Parent.Parent.Services.TrainService)

local METER_MAX = 100

local FuelTrain: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		TrainService.reset(context.pardnerCount, context.difficulty)
	end,
	getProgress = function(): (number, number)
		return TrainService.getFuelMeter(), METER_MAX
	end,
	cleanup = function() end,
}

return FuelTrain
