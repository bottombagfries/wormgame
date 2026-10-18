--!strict
-- Items and Pardner inventory (§6.1, §6.2): spawn, pick up, hold, drop, throw, bag, kit slot.
-- Clients send Request_* intents; everything is validated and applied here.
--
-- An item is always in one of five states:
--   World     - loose physics model in Workspace/Items
--   Hand      - welded in front of its holder (one item per Pardner)
--   Bag       - hidden in ServerStorage, counted against the holder's bag slots
--   Kit       - hidden in ServerStorage, in the holder's single kit slot
--   Swallowed - welded inside a worm's head, about to be destroyed
--
-- Items whose behavior has a fuse (dynamite) can be lit; attributes Lit and FuseEndsAt replicate it.
-- When a fuse runs out the behavior's onFuseEnd runs (e.g. explode) and the item is removed.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local ItemTuning = require(ReplicatedStorage.Shared.Config.ItemTuning)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local ThrowLogic = require(ReplicatedStorage.Shared.ThrowLogic)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local PardnerService = require(script.Parent.PardnerService)

local Debug = GameConfig.Debug
local Tags = TagDefs.Tags

local ITEMS_FOLDER = "Items"
local STASH_FOLDER = "StashedItems"
local LIT_EFFECT_NAME = "LitEffect"

type ItemState = "World" | "Hand" | "Bag" | "Kit" | "Swallowed"

type ItemRecord = {
	id: string,
	def: Types.ItemDef,
	model: Model,
	primary: BasePart,
	state: ItemState,
	holder: Player?,
	weld: WeldConstraint?,
	fuseEndsAt: number?, -- server time; nil = not lit
	litBy: Player?,
}

type Inventory = {
	hand: ItemRecord?,
	bag: { ItemRecord },
	kit: ItemRecord?,
	bonusSlots: number, -- from backpacks; kept through death
}

-- Items whose physics a client is simulating, until they come to rest.
type LooseEntry = { still: number, age: number }

local ItemService = {}

-- An item asked for a blast (ExplosionService handles it): (position, radius, causedBy).
local explosionRequested: Signal.Signal<Vector3, number, Player?> = Signal.new()
ItemService.explosionRequested = explosionRequested

-- A Pardner picked up a size-0 item and it was used at once (Backpack, TrainManual): (player, itemId).
local instantUsed: Signal.Signal<Player, string> = Signal.new()
ItemService.instantUsed = instantUsed

-- A Pardner pressed "use kit" with a kit in the slot: (player, kitId, payload). Whichever system owns that
-- kit's effect listens (e.g. NPCService throws a dandylion). Phase 10 adds kit behaviors and uses.
local kitUsed: Signal.Signal<Player, string, { [string]: any }> = Signal.new()
ItemService.kitUsed = kitUsed

-- An item's fuse ran out and it is gone (a tumbleweed burnt out, dynamite went off): (itemId, position).
local fuseEnded: Signal.Signal<string, Vector3> = Signal.new()
ItemService.fuseEnded = fuseEnded

local records: { [Model]: ItemRecord } = {}
local inventories: { [Player]: Inventory } = {}
local loose: { [ItemRecord]: LooseEntry } = {}
local behaviors: { [string]: Types.ItemBehavior | false } = {}

local itemsFolder: Instance
local stashFolder: Instance
local inventoryRemote: RemoteEvent
local notifyRemote: RemoteEvent

local function getBehavior(def: Types.ItemDef): Types.ItemBehavior?
	local name = def.behavior
	if not name then
		return nil
	end
	local cached = behaviors[name]
	if cached == nil then
		local folder = ReplicatedStorage.Shared:FindFirstChild("ItemBehaviors")
		local module = folder and folder:FindFirstChild(name)
		if module and module:IsA("ModuleScript") then
			cached = (require :: any)(module) :: Types.ItemBehavior
		else
			warn(`[ItemService] Item "{def.id}" wants behavior "{name}" but shared/ItemBehaviors has no such module`)
			cached = false
		end
		behaviors[name] = cached
	end
	return cached or nil
end

local function getInventory(player: Player): Inventory
	local inventory = inventories[player]
	if not inventory then
		inventory = { hand = nil, bag = {}, kit = nil, bonusSlots = 0 }
		inventories[player] = inventory
	end
	return inventory
end

-- The Pardner's root part, if they are alive and able to use items.
local function getRoot(player: Player): BasePart?
	local stats = PardnerService.getStats(player)
	if not stats or stats.health <= 0 then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function capacity(inventory: Inventory): number
	return PardnerConfig.BagSlots + inventory.bonusSlots
end

local function slotsOf(record: ItemRecord): number
	local size = record.def.size
	return if typeof(size) == "number" then size else 0
end

local function usedSlots(inventory: Inventory): number
	local used = 0
	for _, record in inventory.bag do
		used += slotsOf(record)
	end
	return used
end

-- Only size 1-3 items go in the bag, and never one with a burning fuse.
local function fitsInBag(inventory: Inventory, record: ItemRecord): boolean
	local slots = slotsOf(record)
	return slots > 0 and record.fuseEndsAt == nil and usedSlots(inventory) + slots <= capacity(inventory)
end

local function sendInventory(player: Player)
	local inventory = getInventory(player)
	local bag = {}
	for _, record in inventory.bag do
		table.insert(bag, record.id)
	end
	local state: Types.InventoryState = {
		hand = inventory.hand and inventory.hand.id,
		handModel = inventory.hand and inventory.hand.model,
		bag = bag,
		kit = inventory.kit and inventory.kit.id,
		kitUses = inventory.kit and inventory.kit.model:GetAttribute("Uses") :: number?,
		capacity = capacity(inventory),
		used = usedSlots(inventory),
	}
	inventoryRemote:FireClient(player, state)
end

local function notify(player: Player, text: string)
	notifyRemote:FireClient(player, text)
end

-- Collision/physics settings are applied by code, never taken from the model (§3).
local function setHeldPhysics(record: ItemRecord, held: boolean)
	for _, descendant in record.model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = not held
			descendant.CanQuery = not held
			descendant.CanTouch = not held
			-- Massless parts never become the assembly root, so the holder keeps ownership of their character.
			descendant.Massless = held
		end
	end
end

local function clearWeld(record: ItemRecord)
	if record.weld then
		record.weld:Destroy()
		record.weld = nil
	end
end

local function setOwner(record: ItemRecord, owner: Player?)
	if record.primary:IsDescendantOf(itemsFolder) then
		pcall(function()
			record.primary:SetNetworkOwner(owner)
		end)
	end
end

local function holdItem(inventory: Inventory, record: ItemRecord, player: Player, root: BasePart)
	clearWeld(record)
	loose[record] = nil
	setHeldPhysics(record, true)
	record.model.Parent = itemsFolder

	local depth = record.model:GetExtentsSize().Z
	record.model:PivotTo(
		root.CFrame * CFrame.new(0, PardnerConfig.HoldHeight, -(PardnerConfig.HoldDistance + depth / 2))
	)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "HoldWeld"
	weld.Part0 = root
	weld.Part1 = record.primary
	weld.Parent = record.primary

	record.weld = weld
	record.state = "Hand"
	record.holder = player
	inventory.hand = record
end

local function stashItem(record: ItemRecord, player: Player, state: ItemState)
	clearWeld(record)
	loose[record] = nil
	record.model.Parent = stashFolder
	record.state = state
	record.holder = player
end

-- Puts an item back in the world. If `owner` is given, their client simulates it until it rests.
local function releaseItem(record: ItemRecord, cframe: CFrame, velocity: Vector3, owner: Player?)
	clearWeld(record)
	setHeldPhysics(record, false)
	record.model.Parent = itemsFolder
	record.model:PivotTo(cframe)
	record.primary.AssemblyLinearVelocity = velocity
	record.primary.AssemblyAngularVelocity = Vector3.zero
	record.state = "World"
	record.holder = nil

	if owner and PardnerConfig.ThrowClientOwned then
		setOwner(record, owner)
		loose[record] = { still = 0, age = 0 }
	else
		setOwner(record, nil)
		loose[record] = nil
	end
end

local function dropCFrame(root: BasePart, record: ItemRecord): CFrame
	local depth = record.model:GetExtentsSize().Z
	return root.CFrame * CFrame.new(0, 0, -(PardnerConfig.DropDistance + depth / 2))
end

local function removeRecord(record: ItemRecord)
	records[record.model] = nil
	loose[record] = nil
	local holder = record.holder
	local inventory = holder and inventories[holder]
	if inventory and holder then
		if inventory.hand == record then
			inventory.hand = nil
		end
		if inventory.kit == record then
			inventory.kit = nil
		end
		local index = table.find(inventory.bag, record)
		if index then
			table.remove(inventory.bag, index)
		end
		sendInventory(holder)
	end
end

-- Where an item physically is: its holder's position while it is in a bag or kit slot.
local function positionOf(record: ItemRecord): Vector3
	local holder = record.holder
	if (record.state == "Bag" or record.state == "Kit") and holder then
		local character = holder.Character
		if character then
			return character:GetPivot().Position
		end
	end
	return record.model:GetPivot().Position
end

local function lightFuse(record: ItemRecord, seconds: number, litBy: Player?)
	record.fuseEndsAt = Workspace:GetServerTimeNow() + seconds
	record.litBy = litBy
	record.model:SetAttribute("Lit", true)
	record.model:SetAttribute("FuseEndsAt", record.fuseEndsAt)
	if not record.primary:FindFirstChild(LIT_EFFECT_NAME) then
		local behavior = getBehavior(record.def)
		local effect: Instance
		if behavior and behavior.litEffect == "Fire" then
			effect = Instance.new("Fire") -- TODO(asset): burning effect + crackle sound
		else
			local sparkles = Instance.new("Sparkles") -- TODO(asset): fuse effect + hiss sound
			sparkles.SparkleColor = ItemTuning.LitSparkleColor
			effect = sparkles
		end
		effect.Name = LIT_EFFECT_NAME
		effect.Parent = record.primary
	end
end

local function makeContext(record: ItemRecord, player: Player?): Types.ItemUseContext
	local behavior = getBehavior(record.def)
	return {
		player = player,
		itemId = record.id,
		model = record.model,
		position = positionOf(record),
		addBagSlots = function(amount: number)
			if player then
				getInventory(player).bonusSlots += amount
			end
		end,
		light = function()
			local seconds = behavior and behavior.fuseSeconds
			if seconds and record.fuseEndsAt == nil then
				lightFuse(record, seconds, player)
			end
		end,
		explode = function(radius: number)
			explosionRequested:fire(positionOf(record), radius, player)
		end,
	}
end

-- The fuse is out (or the item was swallowed / shot): run its behavior, then remove it.
local function finishFuse(record: ItemRecord)
	if records[record.model] ~= record then
		return
	end
	record.fuseEndsAt = nil
	local position = positionOf(record)
	local behavior = getBehavior(record.def)
	if behavior and behavior.onFuseEnd then
		behavior.onFuseEnd(makeContext(record, record.litBy))
	end
	record.model:Destroy()
	fuseEnded:fire(record.id, position)
end

local function updateFuses()
	local time = Workspace:GetServerTimeNow()
	local due = {}
	for _, record in records do
		local endsAt = record.fuseEndsAt
		if endsAt and time >= endsAt then
			table.insert(due, record)
		end
	end
	for _, record in due do
		finishFuse(record)
	end
end

local function updateLoose(dt: number)
	for record, entry in loose do
		entry.age += dt
		if record.primary.AssemblyLinearVelocity.Magnitude < PardnerConfig.ItemRestSpeed then
			entry.still += dt
		else
			entry.still = 0
		end
		if entry.still >= PardnerConfig.ItemRestSeconds or entry.age >= PardnerConfig.ItemLooseMaxSeconds then
			loose[record] = nil
			setOwner(record, nil)
		end
	end
end

-- Request handlers ------------------------------------------------------------------------------

local function onPickup(player: Player, target: any)
	if typeof(target) ~= "Instance" or not target:IsA("Model") then
		return
	end
	local record = records[target]
	local root = getRoot(player)
	if not record or record.state ~= "World" or not root then
		return
	end

	local stats = PardnerService.getStats(player)
	if stats and stats.climbing then
		return
	end

	local reach = PardnerConfig.PickupRange + record.model:GetExtentsSize().Magnitude / 2 + PardnerConfig.PickupSlack
	if (record.model:GetPivot().Position - root.Position).Magnitude > reach then
		return
	end

	local inventory = getInventory(player)
	local size = record.def.size

	if size == 0 then
		-- Instant use: the item's behavior applies its effect and the item is gone.
		local behavior = getBehavior(record.def)
		if behavior and behavior.onInstantUse then
			behavior.onInstantUse(makeContext(record, player))
		end
		record.model:Destroy()
		instantUsed:fire(player, record.id)
	elseif size == "Kit" then
		-- One kit at a time: the old one drops where the Pardner stands.
		local old = inventory.kit
		stashItem(record, player, "Kit")
		inventory.kit = record
		if old then
			releaseItem(old, dropCFrame(root, old), Vector3.zero, player)
		end
	elseif not inventory.hand then
		holdItem(inventory, record, player, root)
	elseif fitsInBag(inventory, record) then
		stashItem(record, player, "Bag")
		table.insert(inventory.bag, record)
	elseif fitsInBag(inventory, inventory.hand) then
		-- Hands are full but what they hold can go in the bag to make room.
		local held = inventory.hand
		stashItem(held, player, "Bag")
		table.insert(inventory.bag, held)
		holdItem(inventory, record, player, root)
	else
		notify(player, "Your hands and bag are full")
		return
	end
	sendInventory(player)
end

-- The "use kit" key. Only a direction (a unit vector) is accepted from the client.
local function onUseKit(player: Player, payload: any)
	local inventory = getInventory(player)
	local kit = inventory.kit
	if not kit or not getRoot(player) then
		return
	end
	local direction = if typeof(payload) == "table" then payload.direction else nil
	local clean: { [string]: any } = {}
	if typeof(direction) == "Vector3" and direction.Magnitude > 0.5 and direction.Magnitude < 1.5 then
		clean.direction = direction.Unit
	end
	kitUsed:fire(player, kit.id, clean)
end

-- The "use held item" key: whatever the item's behavior does (e.g. light dynamite).
local function onUseHeld(player: Player)
	local inventory = getInventory(player)
	local record = inventory.hand
	if not record or not getRoot(player) then
		return
	end
	local behavior = getBehavior(record.def)
	if behavior and behavior.onUse then
		behavior.onUse(makeContext(record, player))
	end
end

local function onDrop(player: Player)
	local inventory = getInventory(player)
	local record = inventory.hand
	local root = getRoot(player)
	if not record or not root then
		return
	end
	inventory.hand = nil
	releaseItem(record, dropCFrame(root, record), root.AssemblyLinearVelocity, player)
	sendInventory(player)
end

local function onThrow(player: Player, direction: any, power: any)
	if typeof(direction) ~= "Vector3" or typeof(power) ~= "number" then
		return
	end
	-- Rejects NaN and zero vectors.
	if not (direction.Magnitude > 0.5 and direction.Magnitude < 1.5) or power ~= power then
		return
	end
	local inventory = getInventory(player)
	local record = inventory.hand
	local root = getRoot(player)
	if not record or not root then
		return
	end

	local unit = direction.Unit
	local origin = ThrowLogic.origin(root.Position, unit, record.model:GetExtentsSize())
	inventory.hand = nil
	-- A kit may throw harder all the time (Slingshot, §6.6).
	local kitDef = inventory.kit and Kits[inventory.kit.id]
	local mult = kitDef and kitDef.params.PassiveThrowPowerMult or 1
	releaseItem(record, CFrame.new(origin) * root.CFrame.Rotation, ThrowLogic.velocity(unit, power, mult), player)
	sendInventory(player)
end

local function onStoreInBag(player: Player)
	local inventory = getInventory(player)
	local record = inventory.hand
	if not record or not getRoot(player) then
		return
	end
	if slotsOf(record) == 0 then
		notify(player, `{record.def.displayName} is too big for the bag`)
		return
	end
	if record.fuseEndsAt then
		notify(player, "Not with the fuse lit!")
		return
	end
	if not fitsInBag(inventory, record) then
		notify(player, "Not enough room in the bag")
		return
	end
	inventory.hand = nil
	stashItem(record, player, "Bag")
	table.insert(inventory.bag, record)
	sendInventory(player)
end

local function onTakeFromBag(player: Player, slot: any)
	if typeof(slot) ~= "number" then
		return
	end
	local inventory = getInventory(player)
	local record = inventory.bag[slot]
	local root = getRoot(player)
	if not record or not root then
		return
	end

	local stats = PardnerService.getStats(player)
	if stats and stats.climbing then
		return
	end

	table.remove(inventory.bag, slot)

	-- Whatever was in hand swaps into the bag, or drops if it can't fit.
	local held = inventory.hand
	if held then
		inventory.hand = nil
		if fitsInBag(inventory, held) then
			stashItem(held, player, "Bag")
			table.insert(inventory.bag, held)
		else
			releaseItem(held, dropCFrame(root, held), Vector3.zero, player)
		end
	end

	holdItem(inventory, record, player, root)
	sendInventory(player)
end

-- Public API ------------------------------------------------------------------------------------

-- Spawns a loose item in the world. Returns nil for an unknown item id.
function ItemService.spawn(itemId: string, cframe: CFrame): Model?
	local def = Items[itemId]
	if not def then
		warn(`[ItemService] Unknown item "{itemId}"`)
		return nil
	end

	local model = AssetService.get(itemId)
	local primary = model.PrimaryPart
	if not primary then
		warn(`[ItemService] Item "{itemId}" has no PrimaryPart`)
		model:Destroy()
		return nil
	end

	-- User models may be several loose parts: weld them into one body. Physics come from Config (§3).
	local physics = def.physics
	local properties = if physics
		then PhysicalProperties.new(physics.density, physics.friction, physics.elasticity)
		else nil
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CustomPhysicalProperties = properties
			if descendant ~= primary then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end

	local record: ItemRecord = {
		id = itemId,
		def = def,
		model = model,
		primary = primary,
		state = "World",
		holder = nil,
		weld = nil,
	}
	records[model] = record

	model:SetAttribute("ItemId", def.id)
	model:SetAttribute("Size", def.size)
	model:SetAttribute("Fuel", def.fuel)
	local kitDef = Kits[itemId]
	if kitDef and kitDef.uses then
		model:SetAttribute("Uses", kitDef.uses)
	end
	CollectionService:AddTag(model, Tags.Item)
	model.Destroying:Connect(function()
		removeRecord(record)
	end)

	setHeldPhysics(record, false)
	model:PivotTo(cframe)
	model.Parent = itemsFolder
	return model
end

function ItemService.getItemId(model: Model): string?
	local record = records[model]
	return record and record.id
end

-- The loose (not held, not bagged) item that `instance` is part of, and its id.
function ItemService.findLooseItem(instance: Instance): (Model?, string?)
	local model = instance:FindFirstAncestorOfClass("Model")
	while model do
		local record = records[model]
		if record then
			if record.state == "World" then
				return model, record.id
			end
			return nil, nil
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

-- Shoves a loose item (ghost push). The server takes over its physics so the shove is not lost.
-- Returns false if the item is not loose in the world.
function ItemService.push(model: Model, velocityChange: Vector3): boolean
	local record = records[model]
	if not record or record.state ~= "World" then
		return false
	end
	loose[record] = nil
	setOwner(record, nil)
	record.primary.AssemblyLinearVelocity += velocityChange
	return true
end

-- Item ids in a Pardner's hands and kit slot.
function ItemService.getHandItemId(player: Player): string?
	local inventory = inventories[player]
	return inventory and inventory.hand and inventory.hand.id
end

function ItemService.getKitId(player: Player): string?
	local inventory = inventories[player]
	return inventory and inventory.kit and inventory.kit.id
end

-- Destroys whatever the Pardner holds in their hands (e.g. the key going into the keyhole).
-- The model in a Pardner's hands (e.g. the heart jar the Book of the Dead reads).
function ItemService.getHandModel(player: Player): Model?
	local inventory = inventories[player]
	return inventory and inventory.hand and inventory.hand.model
end

-- Uses left on the Pardner's kit (nil = passive / unlimited).
function ItemService.getKitUses(player: Player): number?
	local inventory = inventories[player]
	local uses = inventory and inventory.kit and inventory.kit.model:GetAttribute("Uses")
	return if typeof(uses) == "number" then uses else nil
end

-- Spends one use of the kit; the kit is gone when the last is spent.
function ItemService.spendKitUse(player: Player)
	local inventory = inventories[player]
	local kit = inventory and inventory.kit
	if not kit then
		return
	end
	local uses = kit.model:GetAttribute("Uses")
	if typeof(uses) ~= "number" then
		return
	end
	if uses <= 1 then
		kit.model:Destroy() -- removeRecord empties the slot and updates the client
	else
		kit.model:SetAttribute("Uses", uses - 1)
		sendInventory(player)
	end
end

function ItemService.consumeHand(player: Player): boolean
	local inventory = inventories[player]
	local record = inventory and inventory.hand
	if not record then
		return false
	end
	record.model:Destroy() -- removeRecord clears the hand and updates the client
	return true
end

-- Loose items within `radius` of `position` (by their pivot), with their definitions.
function ItemService.getLooseNear(position: Vector3, radius: number): { Model }
	local list = {}
	for model, record in records do
		if record.state == "World" and (record.primary.Position - position).Magnitude <= radius then
			table.insert(list, model)
		end
	end
	return list
end

function ItemService.isFusible(model: Model): boolean
	local record = records[model]
	local behavior = record and getBehavior(record.def)
	return behavior ~= nil and behavior.fuseSeconds ~= nil
end

-- A blast reached a fused item: a burning fuse is cut by `mult`; an unlit one is lit with
-- fuseSeconds * mult (§6.7: "hit by another blast -> fuse halved"). Returns false if it has no fuse.
function ItemService.chainIgnite(model: Model, mult: number, causedBy: Player?): boolean
	local record = records[model]
	local behavior = record and getBehavior(record.def)
	local seconds = behavior and behavior.blastIgnites and behavior.fuseSeconds
	if not record or not seconds then
		return false
	end
	local endsAt = record.fuseEndsAt
	if endsAt then
		local remaining = math.max(0, endsAt - Workspace:GetServerTimeNow())
		lightFuse(record, remaining * mult, record.litBy)
	else
		lightFuse(record, seconds * mult, causedBy)
	end
	return true
end

-- Lights an item's fuse (e.g. a tumbleweed at the furnace). False if it has no fuse or is already lit.
function ItemService.light(model: Model, litBy: Player?): boolean
	local record = records[model]
	local behavior = record and getBehavior(record.def)
	local seconds = behavior and behavior.fuseSeconds
	if not record or not seconds or record.fuseEndsAt ~= nil then
		return false
	end
	lightFuse(record, seconds, litBy)
	return true
end

function ItemService.isLit(model: Model): boolean
	local record = records[model]
	return record ~= nil and record.fuseEndsAt ~= nil
end

-- Every item with this id that is in the world or in someone's hands (not bagged or swallowed).
function ItemService.getItemsById(itemId: string): { Model }
	local found = {}
	for model, record in records do
		if record.id == itemId and (record.state == "World" or record.state == "Hand") then
			table.insert(found, model)
		end
	end
	return found
end

-- Sets a fused item off right now (swallowed, shot by the rifle, ...).
function ItemService.detonate(model: Model)
	local record = records[model]
	if record then
		finishFuse(record)
	end
end

-- A worm caught a loose item mid-pounce (§8.2). Explosives go off at once; anything swallowable is
-- carried in the head for `seconds` and then gone. Returns true if the item was taken.
function ItemService.swallow(model: Model, head: BasePart, seconds: number): boolean
	local record = records[model]
	if not record or record.state ~= "World" then
		return false
	end
	local behavior = getBehavior(record.def)
	if behavior and behavior.explodesWhenSwallowed then
		finishFuse(record)
		return true
	end
	if not record.def.swallowable then
		return false
	end

	loose[record] = nil
	setHeldPhysics(record, true)
	record.model:PivotTo(head.CFrame)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "MouthWeld"
	weld.Part0 = head
	weld.Part1 = record.primary
	weld.Parent = record.primary
	record.weld = weld
	record.state = "Swallowed"
	task.delay(seconds, function()
		if records[model] == record and record.state == "Swallowed" then
			model:Destroy()
		end
	end)
	return true
end

-- Removes an item from the game, wherever it is.
function ItemService.destroy(model: Model)
	if records[model] then
		model:Destroy()
	end
end

-- Drops whatever the Pardner is holding in their hands (no-op if nothing).
function ItemService.dropHeld(player: Player)
	local inventory = inventories[player]
	local record = inventory and inventory.hand
	if not inventory or not record then
		return
	end
	inventory.hand = nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local cframe = if root and root:IsA("BasePart") then dropCFrame(root, record) else record.model:GetPivot()
	releaseItem(record, cframe, Vector3.zero, nil)
	sendInventory(player)
end

-- Spills hand, bag and kit around `cframe`. Backpack slots are kept (§6.2).
function ItemService.dropAll(player: Player, cframe: CFrame)
	local inventory = inventories[player]
	if not inventory then
		return
	end

	local dropping: { ItemRecord } = table.clone(inventory.bag)
	if inventory.hand then
		table.insert(dropping, inventory.hand)
	end
	if inventory.kit then
		table.insert(dropping, inventory.kit)
	end
	inventory.hand = nil
	inventory.kit = nil
	table.clear(inventory.bag)

	for index, record in dropping do
		local angle = index / #dropping * math.pi * 2
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * PardnerConfig.DeathScatterRadius
		releaseItem(record, cframe + offset, Vector3.zero, nil)
	end
	if #dropping > 0 and player.Parent then
		sendInventory(player)
	end
end

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		ItemService.dropAll(player, character:GetPivot())
	end)
end

local function onPlayerAdded(player: Player)
	getInventory(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
		sendInventory(player)
	end)
	-- A held item is welded to the character, so it has to come off before the character is removed.
	player.CharacterRemoving:Connect(function(character)
		ItemService.dropAll(player, character:GetPivot())
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	sendInventory(player)
end

-- Removes every item in the game and empties every inventory, backpack slots included (new match).
function ItemService.clearAll()
	local models = {}
	for model in records do
		table.insert(models, model)
	end
	for _, model in models do
		model:Destroy()
	end
	for player, inventory in inventories do
		inventory.hand = nil
		inventory.kit = nil
		inventory.bonusSlots = 0
		table.clear(inventory.bag)
		sendInventory(player)
	end
end

-- Debug: a row of items next to the spawn (Config.Game.Debug.TestItems).
function ItemService.spawnTestItems()
	for index, itemId in Debug.TestItems do
		local position = Debug.TestItemOrigin
			+ Vector3.new((index - 1) * Debug.TestItemSpacing, Debug.TestItemDropHeight, 0)
		local model = ItemService.spawn(itemId, CFrame.new(position))
		if model then
			-- Lift it so it rests on the ground instead of spawning half inside it.
			model:PivotTo(CFrame.new(position + Vector3.new(0, model:GetExtentsSize().Y / 2, 0)))
		end
	end
end

function ItemService.init()
	local folder = Workspace:FindFirstChild(ITEMS_FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = ITEMS_FOLDER
		folder.Parent = Workspace
	end
	itemsFolder = folder

	local stash = Instance.new("Folder")
	stash.Name = STASH_FOLDER
	stash.Parent = ServerStorage
	stashFolder = stash

	inventoryRemote = Net.event("State_Inventory")
	notifyRemote = Net.event("Fx_Notify")
end

function ItemService.start()
	Net.onRequest("Request_Pickup", onPickup)
	Net.onRequest("Request_Drop", onDrop)
	Net.onRequest("Request_Throw", onThrow)
	Net.onRequest("Request_StoreInBag", onStoreInBag)
	Net.onRequest("Request_TakeFromBag", onTakeFromBag)
	Net.onRequest("Request_UseHeld", onUseHeld)
	Net.onRequest("Request_UseKit", onUseKit)

	PardnerService.climbStarted:connect(ItemService.dropHeld)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local character = player.Character
		if character then
			ItemService.dropAll(player, character:GetPivot())
		end
		inventories[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	RunService.Heartbeat:Connect(function(dt)
		updateLoose(dt)
		updateFuses()
	end)
end

return ItemService
