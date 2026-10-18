--!strict
-- Worm abilities (§12). Every worm has the five defaults plus the two it picked in the loadout
-- (player attribute "Abilities"). Request_Ability(abilityId, payload) → validate → the ability's server
-- half (server/Abilities/<id>) → cooldown. Cooldowns are × Worm.NightCooldownMult after sundown and are
-- replicated as worm-model attributes "Cooldown_<id>" (server time the ability is ready again).
-- Abilities that want a client effect get Fx_Ability(abilityId, wormModel, data) sent to every client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local WormService = require(script.Parent.WormService)

local FX_FOLDER = "AbilityFx"
local COOLDOWN_PREFIX = "Cooldown_"

local AbilityService = {}

local modules: { [string]: Types.AbilityModule } = {}
local readyAt: { [Player]: { [string]: number } } = {}
local fxFolder: Instance
local notifyRemote: RemoteEvent
local fxRemote: RemoteEvent

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- The defaults plus this worm's two picks.
function AbilityService.getAbilities(player: Player): { string }
	local list = {}
	for id, def in Abilities do
		if def.kind == "Default" then
			table.insert(list, id)
		end
	end
	table.sort(list)
	local picks = player:GetAttribute("Abilities")
	if typeof(picks) == "string" then
		for id in string.gmatch(picks, "[^,]+") do
			if Abilities[id] then
				table.insert(list, id)
			end
		end
	end
	return list
end

local function buildContext(player: Player, abilityId: string, direction: Vector3): Types.AbilityContext?
	for _, worm in WormService.getWorms() do
		if worm.player == player then
			return {
				player = player,
				abilityId = abilityId,
				position = worm.position,
				mode = worm.mode,
				head = worm.head,
				model = worm.model,
				direction = direction,
				params = Abilities[abilityId].params,
				night = WormService.isNight(),
				folder = fxFolder,
				notify = function(text: string)
					notifyRemote:FireClient(player, text)
				end,
			}
		end
	end
	return nil
end

local function onAbility(player: Player, abilityId: any, payload: any)
	if typeof(abilityId) ~= "string" or not table.find(AbilityService.getAbilities(player), abilityId) then
		return
	end
	local module = modules[abilityId]
	if not module then
		return
	end
	local data: { [string]: any } = if typeof(payload) == "table" then payload else {}
	local direction = data.direction
	if typeof(direction) ~= "Vector3" or not (direction.Magnitude > 0.5 and direction.Magnitude < 1.5) then
		direction = Vector3.zAxis * -1
	end

	local context = buildContext(player, abilityId, (direction :: Vector3).Unit)
	if not context then
		return
	end
	local cooldowns = readyAt[player]
	if not cooldowns then
		cooldowns = {}
		readyAt[player] = cooldowns
	end
	if now() < (cooldowns[abilityId] or 0) then
		return
	end
	if module.canUse then
		local ok, reason = module.canUse(context)
		if not ok then
			if reason then
				context.notify(reason)
			end
			return
		end
	end
	if not module.activate(context, data) then
		return
	end

	local base = if module.cooldown then module.cooldown(context) else Abilities[abilityId].cooldown
	if base > 0 then
		local cooldown = base * (if context.night then WormConfig.NightCooldownMult else 1)
		cooldowns[abilityId] = now() + cooldown
		context.model:SetAttribute(COOLDOWN_PREFIX .. abilityId, cooldowns[abilityId])
	end
end

-- Plays an ability's client effect on every client (shared/AbilityBehaviors/<id>.clientFx).
function AbilityService.playFx(abilityId: string, wormModel: Model, data: { [string]: any })
	fxRemote:FireAllClients(abilityId, wormModel, data)
end

-- Match over: everything abilities left in the world goes, and cooldowns reset.
function AbilityService.clear()
	for _, module in modules do
		if module.cleanup then
			module.cleanup()
		end
	end
	fxFolder:ClearAllChildren()
	table.clear(readyAt)
end

function AbilityService.init()
	local folder = Instance.new("Folder")
	folder.Name = FX_FOLDER
	folder.Parent = Workspace
	fxFolder = folder
	notifyRemote = Net.event("Fx_Notify")
	fxRemote = Net.event("Fx_Ability")

	local source = script.Parent.Parent:FindFirstChild("Abilities")
	for id in Abilities do
		local module = source and source:FindFirstChild(id)
		if module and module:IsA("ModuleScript") then
			modules[id] = (require :: any)(module) :: Types.AbilityModule
		else
			warn(`[AbilityService] Ability "{id}" has no module in server/Abilities`)
		end
	end
end

function AbilityService.start()
	Net.onRequest("Request_Ability", onAbility)
	Players.PlayerRemoving:Connect(function(player)
		readyAt[player] = nil
	end)
end

return AbilityService
