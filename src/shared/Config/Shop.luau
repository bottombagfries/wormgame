--!strict
-- Phase 13 shop: Roblox game passes. RULE: cosmetic or convenience only. Nothing sold here may change the
-- Worm roll, a match's outcome, or any gameplay number - no paid Worm chance, no stat boosts, no items.
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
		name = "Spur Trail",
		description = "A trail of dust and sparks behind your boots. Looks only.",
		price = 99,
	},
	{
		id = 0, -- TODO
		name = "Ghost Lantern",
		description = "Your ghost glows with a lantern light while you wait for a revive.",
		price = 79,
	},
	{
		id = 0, -- TODO
		name = "Worm Skins Pack",
		description = "Rattlesnake, bone and copper patterns for your Worm.",
		price = 199,
	},
	{
		id = 0, -- TODO
		name = "Station Radio",
		description = "Pick the lobby's music and turn the radio on for everyone.",
		price = 49,
	},
}

return {
	GamePasses = GamePasses,
	ComingSoonText = "Coming soon",
}
