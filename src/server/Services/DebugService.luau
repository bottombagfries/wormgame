--!strict
-- Studio-only chat commands for testing (Config.Game.Debug.ChatCommands):
--   !give <ItemId>   spawns that item in front of you (any item, including every kit). "/" works too.
-- (!hurt / !heal live in PardnerService.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Net = require(ReplicatedStorage.Shared.Net)
local ItemService = require(script.Parent.ItemService)

local Debug = GameConfig.Debug

local DebugService = {}

local notifyRemote: RemoteEvent

-- Case-insensitive item id lookup ("coffeetin" -> "CoffeeTin").
local function findItemId(name: string): string?
	local wanted = string.lower(name)
	for id in Items do
		if string.lower(id) == wanted then
			return id
		end
	end
	return nil
end

local function onChat(player: Player, message: string)
	local name = string.match(message, "^[!/]give%s+(%w+)")
	if not name then
		return
	end
	local itemId = findItemId(name)
	local character = player.Character
	if not itemId or not character then
		notifyRemote:FireClient(player, `No item called "{name}"`)
		return
	end
	local front = character:GetPivot() * CFrame.new(0, 0, -Debug.GiveDistance)
	ItemService.spawn(itemId, front)
	notifyRemote:FireClient(player, `Gave {Items[itemId].displayName}`)
end

function DebugService.init()
	notifyRemote = Net.event("Fx_Notify")
end

function DebugService.start()
	if not (Debug.Enabled and Debug.ChatCommands and RunService:IsStudio()) then
		return
	end
	local function hook(player: Player)
		player.Chatted:Connect(function(message)
			onChat(player, message)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
end

return DebugService
