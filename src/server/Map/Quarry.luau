--!strict
-- The quarry (§6.7): minecarts with dynamite on them. A few to start with, then one more every
-- QuarryDynamiteSeconds while fewer than Structures.Quarry.MaxDynamite are lying around the quarry.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local ItemService = require(script.Parent.Parent.Services.ItemService)

local QuarryConfig = Structures.Quarry
local DYNAMITE = "Dynamite"

local Quarry = {}

local carts: { Model } = {}
local center: Vector3? = nil
local timer = 0
local nextCart = 1

local function placeDynamite()
	if #carts == 0 then
		return
	end
	local cart = carts[nextCart]
	nextCart = nextCart % #carts + 1
	local cframe, size = cart:GetBoundingBox()
	ItemService.spawn(DYNAMITE, cframe * CFrame.new(0, size.Y / 2 + 1, 0))
end

local function dynamiteNearby(position: Vector3): number
	local count = 0
	for _, model in ItemService.getLooseNear(position, QuarryConfig.DynamiteRadius) do
		if ItemService.getItemId(model) == DYNAMITE then
			count += 1
		end
	end
	return count
end

function Quarry.spawn(cframe: CFrame, parent: Instance)
	Quarry.clear()
	for index = 1, QuarryConfig.Minecarts do
		local offset = (index - (QuarryConfig.Minecarts + 1) / 2) * QuarryConfig.MinecartSpacing
		local cart = AssetService.get("QuarryMinecart") -- TODO(asset): QuarryMinecart
		for _, descendant in cart:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		Geometry.placeOnGround(cart, cframe * CFrame.new(offset, 0, 0))
		cart.Parent = parent
		table.insert(carts, cart)
	end
	center = cframe.Position
	for _ = 1, ItemTuning.QuarryStartDynamite do
		placeDynamite()
	end
end

function Quarry.step(dt: number)
	local position = center
	if not position then
		return
	end
	timer += dt
	if timer >= ItemTuning.QuarryDynamiteSeconds then
		timer = 0
		if dynamiteNearby(position) < QuarryConfig.MaxDynamite then
			placeDynamite()
		end
	end
end

function Quarry.clear()
	for _, cart in carts do
		cart:Destroy()
	end
	table.clear(carts)
	center = nil
	timer = 0
	nextCart = 1
end

return Quarry
