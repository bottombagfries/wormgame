--!strict
-- Uploaded Roblox asset ids for the real models (Blender → Open Cloud). The game never reads these at
-- runtime: AssetService clones the Models in ReplicatedStorage/Assets. This file is the record used to
-- rebuild those Models if the place file loses them. See assets/ASSET_STATUS.md.

export type MeshRecord = {
	mesh: number, -- MeshPart.MeshId
	model: number, -- the uploaded FBX (Model asset) the mesh came from
}

return {
	-- The shared palette texture every mesh uses (MeshPart.TextureID).
	PaletteImage = 81576212373708,
	PaletteDecal = 86148081784505,

	Meshes = {
		SmallCoal = { mesh = 125357970700665, model = 96698677008646 },
		BigCoal = { mesh = 92323673507845, model = 121593929184947 },
		Barrel = { mesh = 118945128255384, model = 140235735792006 },
		Dynamite = { mesh = 71837835385387, model = 115428340223156 },
		Lantern = { mesh = 104761163506498, model = 86815227839969 },
	} :: { [string]: MeshRecord },
}
