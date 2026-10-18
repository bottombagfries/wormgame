--!strict
-- Kit items (§6.6). Each kit's behaviour is a module in server/Kits named after its id
-- (Types.KitModule): `onUse` for the "use kit" key (T), passive speed / stamina multipliers while the kit
-- is in the slot, and `savesFromMouth` for kits that pop the holder out of a worm's mouth.
-- Uses come from Config.Kits[id].uses (the kit model's "Uses" attribute); the kit is gone when they run
-- out. Shovel (DigService) and Dandylion Bundle (NPCService) are handled by their own services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local ItemService = require(script.Parent.ItemService)
local PardnerService = require(script.Parent.PardnerService)
local WormService = require(script.Parent.WormService)

local KitService = {}

local modules: { [string]: Types.KitModule } = {}
local notifyRemote: RemoteEvent

local function moduleFor(player: Player): Types.KitModule?
	local kitId = ItemService.getKitId(player)
	return if kitId then modules[kitId] else nil
end

local function onKitUsed(player: Player, kitId: string, payload: { [string]: any })
	local module = modules[kitId]
	local def = Kits[kitId]
	if not module or not def then
		return -- not a KitService kit (Shovel, Dandylion Bundle)
	end
	if not module.onUse then
		notifyRemote:FireClient(player, `The {def.displayName} works on its own - keep it in your kit slot`)
		return
	end
	local root = PardnerService.getLiving()[player]
	if not root then
		return
	end
	if def.uses and (ItemService.getKitUses(player) or 0) <= 0 then
		return
	end

	local context: Types.KitContext = {
		player = player,
		kitId = kitId,
		root = root,
		direction = payload.direction or root.CFrame.LookVector,
		params = def.params,
		notify = function(text: string)
			notifyRemote:FireClient(player, text)
		end,
	}
	if module.onUse(context) and def.uses then
		ItemService.spendKitUse(player)
	end
end

function KitService.init()
	notifyRemote = Net.event("Fx_Notify")
	local folder = script.Parent.Parent:FindFirstChild("Kits")
	for id in Kits do
		local module = folder and folder:FindFirstChild(id)
		if module and module:IsA("ModuleScript") then
			modules[id] = (require :: any)(module) :: Types.KitModule
		end
	end
end

function KitService.start()
	ItemService.kitUsed:connect(onKitUsed)

	-- Passive kits (Canteen, Spirit Board) change speed / stamina use while in the slot.
	PardnerService.setPassiveMods(function(player: Player): (number, number)
		local module = moduleFor(player)
		if not module then
			return 1, 1
		end
		local speed = if module.passiveSpeedMult then module.passiveSpeedMult(player) else 1
		return speed, module.passiveStaminaUseMult or 1
	end)

	-- Quick Escape Knife: spent automatically instead of dying in a mouth.
	WormService.setEscapeSaver(function(pardner: Player): boolean
		local module = moduleFor(pardner)
		if module and module.savesFromMouth and (ItemService.getKitUses(pardner) or 0) > 0 then
			ItemService.spendKitUse(pardner)
			notifyRemote:FireClient(pardner, "Your knife cut you free!")
			return true
		end
		return false
	end)
end

return KitService
