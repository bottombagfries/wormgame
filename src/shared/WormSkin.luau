--!strict
-- Looks up worm skins (Config/WormSkins) and dresses a worm model in one. Usable on server and client:
-- the server dresses the replicated head, each client dresses its own local body segments.

local AssetIds = require(script.Parent.Config.AssetIds)
local WormSkins = require(script.Parent.Config.WormSkins)

local PALETTE = `rbxassetid://{AssetIds.PaletteImage}`

local WormSkin = {}

local byId: { [string]: WormSkins.Skin } = {}
for _, skin in WormSkins.Skins do
	byId[skin.id] = skin
end

-- The skin with this id, or nil.
function WormSkin.find(id: any): WormSkins.Skin?
	return if typeof(id) == "string" then byId[id] else nil
end

-- The skin with this id, falling back to the default.
function WormSkin.get(id: any): WormSkins.Skin
	return WormSkin.find(id) or byId[WormSkins.Default]
end

-- The texture for one piece of the worm: index 0 is the head, 1.. the body segments (even ones use the
-- skin's B texture when it has one, for bands).
function WormSkin.textureFor(id: any, index: number): string
	local skin = WormSkin.get(id)
	local texture = if index > 0 and index % 2 == 0 and skin.textureB then skin.textureB else skin.textureA
	return if texture ~= "" then texture else PALETTE
end

-- Sets the texture on every textured MeshPart in `model` (greyboxes are left alone).
function WormSkin.apply(model: Instance, id: any, index: number)
	local texture = WormSkin.textureFor(id, index)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("MeshPart") and descendant.TextureID ~= "" then
			descendant.TextureID = texture
		end
	end
	if model:IsA("MeshPart") and model.TextureID ~= "" then
		model.TextureID = texture
	end
end

return WormSkin
