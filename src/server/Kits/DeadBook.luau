--!strict
-- Book of the Dead (§6.6, §9): read it while holding a heart jar to bring that Pardner back right in
-- front of you — at night and for ossified hearts too. Reading costs 35 health over 1 s, which can kill.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local ReviveService = require(script.Parent.Parent.Services.ReviveService)

local HEART_JAR = "HeartJar"

local DeadBook: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local params = context.params
		local jar = ItemService.getHandModel(context.player)
		if not jar or ItemService.getItemId(jar) ~= HEART_JAR then
			context.notify("Hold a heart jar in your hands to read from the book")
			return false
		end
		local spot = context.root.CFrame * CFrame.new(0, 0, -params.ReviveGap)
		if not ReviveService.reviveFromJar(jar, spot) then
			context.notify("This heart doesn't answer")
			return false
		end

		-- The price, paid over UserDamageSeconds.
		task.spawn(function()
			local perTick = params.UserDamage / params.DamageTicks
			for _ = 1, params.DamageTicks do
				PardnerService.damage(context.player, perTick)
				task.wait(params.UserDamageSeconds / params.DamageTicks)
			end
		end)
		return true
	end,
}

return DeadBook
