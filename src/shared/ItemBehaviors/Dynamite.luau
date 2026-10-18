--!strict
-- Dynamite (§6.7): light it while held, and it blows up when the fuse runs out. Swallowing it,
-- lit or not, sets it off at once. A nearby blast lights it with half the fuse (ExplosionService).

local ItemTuning = require(script.Parent.Parent.Config.ItemTuning)
local Types = require(script.Parent.Parent.Types)

local Dynamite: Types.ItemBehavior = {
	fuseSeconds = ItemTuning.DynamiteFuse,
	explodesWhenSwallowed = true,
	blastIgnites = true,
	onUse = function(context: Types.ItemUseContext)
		context.light()
	end,
	onFuseEnd = function(context: Types.ItemUseContext)
		context.explode(ItemTuning.DynamiteBlastRadius)
	end,
}

return Dynamite
