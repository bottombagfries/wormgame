--!strict
-- Worm skins (cosmetic only, never a gameplay effect). A skin is a recolored copy of the palette texture
-- (built by tools/blender/skins/worm_skins.py, which holds the source colors): `textureA` dresses the head and
-- odd segments, `textureB` (optional) the even segments, for bands. "" = the normal palette.
-- `unlock` is "Free" or the `key` of a game pass in Config/Shop. Swatch colors are for the picker only.

local rgb = Color3.fromRGB

export type Skin = {
	id: string,
	displayName: string,
	description: string,
	unlock: string,
	textureA: string,
	textureB: string?,
	swatch: { Color3 }, -- body, plates, eyes (and the band color when there is one)
}

local Skins: { Skin } = {
	{
		id = "Classic",
		displayName = "Desert Classic",
		description = "The original: raw pink flesh and rusty armor.",
		unlock = "Free",
		textureA = "",
		swatch = { rgb(176, 101, 79), rgb(162, 83, 44), rgb(255, 211, 107) },
	},
	{
		id = "Dune",
		displayName = "Dune",
		description = "Pale as the sand it swims in. Ember eyes.",
		unlock = "Free",
		textureA = "rbxassetid://72328951713999",
		swatch = { rgb(210, 176, 122), rgb(110, 82, 54), rgb(255, 107, 61) },
	},
	{
		id = "Rattlesnake",
		displayName = "Rattlesnake",
		description = "Dark and cream bands down the whole body.",
		unlock = "WormSkins",
		textureA = "rbxassetid://78479604786065",
		textureB = "rbxassetid://122295198316072",
		swatch = { rgb(139, 107, 62), rgb(46, 34, 22), rgb(232, 210, 74), rgb(217, 196, 142) },
	},
	{
		id = "Bone",
		displayName = "Bone",
		description = "Bleached white, with cold blue eyes.",
		unlock = "WormSkins",
		textureA = "rbxassetid://123227177687544",
		swatch = { rgb(230, 221, 200), rgb(140, 132, 115), rgb(127, 212, 255) },
	},
	{
		id = "Copper",
		displayName = "Copper",
		description = "Polished copper bands and green verdigris plates.",
		unlock = "WormSkins",
		textureA = "rbxassetid://113700087497112",
		textureB = "rbxassetid://109108725796998",
		swatch = { rgb(184, 100, 58), rgb(78, 138, 150), rgb(255, 179, 71), rgb(154, 82, 48) },
	},
}

return {
	Default = "Classic",
	Skins = Skins,
}
