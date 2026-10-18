--!strict
-- The swappable-asset system (§3). Usable on server and client.
-- AssetService.get(id) clones ReplicatedStorage.Assets/<folder>/<id> if the user has dropped a
-- model there, otherwise builds a labeled greybox from Config/Assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(script.Parent.Config.Assets)
local GameConfig = require(script.Parent.Config.Game)

type AssetDef = Assets.AssetDef

local ASSETS_FOLDER = "Assets"
local LABEL_SIZE = UDim2.fromOffset(140, 22)
local LABEL_GAP = 1.5 -- studs above the greybox

local FALLBACK_DEF: AssetDef = {
	folder = "Items",
	size = Vector3.new(2, 2, 2),
	color = Color3.fromRGB(255, 0, 255),
}

local AssetService = {}

local warnedMissing: { [string]: boolean } = {}

local function findUserModel(assetId: string, def: AssetDef): Model?
	local root = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER)
	local folder = root and root:FindFirstChild(def.folder)
	local found = folder and folder:FindFirstChild(assetId)
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

local function largestPart(model: Model): BasePart?
	local best: BasePart? = nil
	local bestVolume = -1
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local size = descendant.Size
			local volume = size.X * size.Y * size.Z
			if volume > bestVolume then
				best, bestVolume = descendant, volume
			end
		end
	end
	return best
end

-- The floating asset-id label every greybox wears, so it's obvious what still needs art.
-- `height` is how far above the part's center the top of the greybox is.
function AssetService.addLabel(part: BasePart, assetId: string, height: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AssetLabel"
	billboard.Size = LABEL_SIZE
	billboard.StudsOffsetWorldSpace = Vector3.new(0, height + LABEL_GAP, 0)
	billboard.MaxDistance = GameConfig.Debug.LabelMaxDistance
	billboard.LightInfluence = 0
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = assetId
	label.Parent = billboard
end

local function buildGreybox(assetId: string, def: AssetDef): Model
	-- TODO(asset): every greybox built here is a model that still needs real art.
	local model = Instance.new("Model")
	model.Name = assetId

	local part = Instance.new("Part")
	part.Name = "Greybox"
	part.Size = def.size
	part.Color = def.color
	part.Shape = def.shape or Enum.PartType.Block
	part.Material = def.material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model

	AssetService.addLabel(part, assetId, def.size.Y / 2)

	model.PrimaryPart = part
	model:SetAttribute("Greybox", true)
	return model
end

function AssetService.getDef(assetId: string): AssetDef
	local def = Assets[assetId]
	if not def then
		if not warnedMissing[assetId] then
			warnedMissing[assetId] = true
			warn(`[AssetService] No entry for "{assetId}" in Config/Assets.luau - using a magenta fallback box`)
		end
		return FALLBACK_DEF
	end
	return def
end

function AssetService.hasUserModel(assetId: string): boolean
	return findUserModel(assetId, AssetService.getDef(assetId)) ~= nil
end

function AssetService.get(assetId: string): Model
	local def = AssetService.getDef(assetId)

	local model: Model? = nil
	local source = findUserModel(assetId, def)
	if source then
		local clone = source:Clone()
		if not clone.PrimaryPart then
			clone.PrimaryPart = largestPart(clone)
		end
		if clone.PrimaryPart then
			model = clone
		else
			warn(`[AssetService] Model "{assetId}" has no parts - using a greybox instead`)
			clone:Destroy()
		end
	end

	local result = model or buildGreybox(assetId, def)
	result:SetAttribute("AssetId", assetId)
	return result
end

return AssetService
