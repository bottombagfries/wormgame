--!strict
-- Mysterious Concoction (§6.6): 3 uses. Each swig rolls one weighted effect: heal, hurt, die, explode
-- (a dynamite blast on the drinker), revealed to worms, or a teleport to a random spot on the sand.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local Types = require(ReplicatedStorage.Shared.Types)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local ExplosionService = require(script.Parent.Parent.Services.ExplosionService)
local MapService = require(script.Parent.Parent.Services.MapService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

type Effect = { id: string, amount: number?, weight: number }

-- Effect id -> what it does. Data-driven: the effect list and weights are in Config.Kits.
local effects: { [string]: (context: Types.KitContext, effect: Effect) -> string } = {
	Heal = function(context, effect)
		PardnerService.heal(context.player, effect.amount or 0)
		return `You feel better (+{effect.amount} health)`
	end,
	Hurt = function(context, effect)
		PardnerService.damage(context.player, effect.amount or 0)
		return `That was foul (-{effect.amount} health)`
	end,
	Die = function(context)
		PardnerService.damage(context.player, math.huge)
		return "That was poison."
	end,
	Explode = function(context)
		ExplosionService.explode(context.root.Position, ItemTuning.DynamiteBlastRadius, context.player)
		return "KABOOM"
	end,
	Reveal = function(context, effect)
		PardnerService.addStatus(context.player, {
			id = "ConcoctionReveal",
			expires = os.clock() + (effect.amount or 0),
			revealed = true,
		})
		return `You're glowing - the worms can see you for {effect.amount}s`
	end,
	Teleport = function(context)
		local spot = MapService.findLooseSpot(Random.new())
		local character = context.player.Character
		if spot and character then
			character:PivotTo(CFrame.new(spot + Vector3.yAxis * context.params.TeleportHeight))
		end
		return "Whoa - where are you?"
	end,
}

local MysteriousConcoction: Types.KitModule = {
	onUse = function(context: Types.KitContext): boolean
		local list = context.params.Effects :: { Effect }
		local effect = RandomUtil.weighted(list, function(entry: Effect)
			return entry.weight
		end)
		local run = effects[effect.id]
		if run then
			context.notify(run(context, effect)) -- TODO(asset): drinking sound / effect particles
		end
		return true
	end,
}

return MysteriousConcoction
