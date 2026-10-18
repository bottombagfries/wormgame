--!strict
-- Phase 13 shop: Roblox game passes. RULE: cosmetic only. Nothing sold here may change the Worm roll, a
-- match's outcome, or any gameplay number - no paid Worm chance or boosts for it (in an asymmetric game
-- that reads as pay-to-win), no stat boosts, no items. Worm skins, hats, trails and sounds are fine.
-- `id` is the game pass id from the Creator Dashboard; 0 = not created yet (shows "Coming soon").
-- Perks are granted server-side later (cosmetics are deferred in CLAUDE.md §15).

export type GamePass = {
	id: number,
	name: string,
	description: string,
	price: number, -- Robux, for display only (Roblox shows the real price at purchase)
}

local GamePasses: { GamePass } = {
	{
		id = 0, -- TODO: create the pass and paste its id
		name = "Worm Skins Pack",
		description = "Rattlesnake, bone and copper patterns for your Worm.",
		price = 199,
	},
	{
		id = 0, -- TODO
		name = "Hat Rack",
		description = "Stetsons, bowlers and a sombrero for your Pardner.",
		price = 99,
	},
	{
		id = 0, -- TODO
		name = "Train Horn Sounds",
		description = "Pick what the Train's horn sounds like when you pull it.",
		price = 79,
	},
	{
		id = 0, -- TODO
		name = "Spur Trail",
		description = "A trail of dust and sparks behind your boots.",
		price = 99,
	},
}

return {
	GamePasses = GamePasses,
	ComingSoonText = "Coming soon",
}
