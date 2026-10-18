--!strict
-- Cosmetics (Phase 13+): which game passes each player owns (Config/Shop), and their chosen worm skin.
-- Cosmetic only - nothing here touches the role roll or gameplay.
--
-- Replication: player attributes OwnedPasses (comma-separated pass keys) and WormSkin (skin id).
-- Requests: Request_SetWormSkin(skinId) - checked against ownership here.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local WormSkins = require(ReplicatedStorage.Shared.Config.WormSkins)
local Net = require(ReplicatedStorage.Shared.Net)
local WormSkin = require(ReplicatedStorage.Shared.WormSkin)

local Debug = GameConfig.Debug

local CosmeticsService = {}

local owned: { [Player]: { [string]: boolean } } = {}

-- In Studio with Debug.UnlockAllCosmetics every pass counts as owned, so cosmetics can be tested before the
-- passes exist.
local function unlockAll(): boolean
	return Debug.Enabled and Debug.UnlockAllCosmetics and RunService:IsStudio()
end

local function publish(player: Player)
	local keys = {}
	for key, has in owned[player] or {} do
		if has then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	player:SetAttribute("OwnedPasses", table.concat(keys, ","))
end

local function refresh(player: Player)
	local passes: { [string]: boolean } = {}
	for _, pass in Shop.GamePasses do
		if unlockAll() then
			passes[pass.key] = true
		elseif pass.id > 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			passes[pass.key] = ok and has == true
		end
	end
	if player.Parent then
		owned[player] = passes
		publish(player)
	end
end

function CosmeticsService.ownsPass(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

function CosmeticsService.canUseSkin(player: Player, skinId: string): boolean
	local skin = WormSkin.find(skinId)
	if not skin then
		return false
	end
	return skin.unlock == "Free" or CosmeticsService.ownsPass(player, skin.unlock)
end

-- The skin this player's worm should wear (their choice if they may use it, else the default).
function CosmeticsService.getWormSkin(player: Player): string
	local chosen = player:GetAttribute("WormSkin")
	if typeof(chosen) == "string" and CosmeticsService.canUseSkin(player, chosen) then
		return chosen
	end
	return WormSkins.Default
end

local function onSetWormSkin(player: Player, skinId: any)
	if typeof(skinId) == "string" and CosmeticsService.canUseSkin(player, skinId) then
		player:SetAttribute("WormSkin", skinId)
	end
end

function CosmeticsService.start()
	Net.onRequest("Request_SetWormSkin", onSetWormSkin)

	local function onPlayerAdded(player: Player)
		player:SetAttribute("WormSkin", WormSkins.Default)
		task.spawn(refresh, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)

	-- Right after a purchase the ownership check can still say no for a while, so trust the receipt.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in Shop.GamePasses do
			if pass.id > 0 and pass.id == passId then
				local passes = owned[player] or {}
				passes[pass.key] = true
				owned[player] = passes
				publish(player)
			end
		end
	end)
end

return CosmeticsService
