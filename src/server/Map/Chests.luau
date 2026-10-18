--!strict
-- Chests (§6.6). Every chest holds exactly one kit; randomly spawned (and airdrop) chests may also
-- hold an extra item. Guarantees: MapService plans every match-start chest first, then this assigns
-- the guaranteed kits to random chests and fills the rest at random (§6.6).
-- Opening: hold the prompt; the contents drop in front of the chest and the chest is gone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Loot = require(ReplicatedStorage.Shared.Config.Loot)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local SoundCue = require(script.Parent.Parent.Util.SoundCue)

local CHEST_ASSET = "Chest"

type Plan = { cframe: CFrame, extras: boolean }

local Chests = {}

local planned: { Plan } = {}
local spawned: { Model } = {}

local function guaranteedKits(): { string }
	local ids = {}
	for id in Kits do
		table.insert(ids, id)
	end
	table.sort(ids)
	local list = {}
	for _, id in ids do
		for _ = 1, Kits[id].guaranteed do
			table.insert(list, id)
		end
	end
	return list
end

local function chestPool(): { string }
	local pool = {}
	for id, def in Kits do
		if def.inChests ~= false then
			table.insert(pool, id)
		end
	end
	table.sort(pool)
	return pool
end

local function open(model: Model, contents: { string }, prompt: ProximityPrompt, player: Player)
	local root = PardnerService.getLiving()[player]
	if not root or not model.Parent then
		return
	end
	local reach = prompt.MaxActivationDistance + GameConfig.Train.PromptSlack
	if (root.Position - model:GetPivot().Position).Magnitude > reach then
		return
	end

	local cframe, size = model:GetBoundingBox()
	local front = cframe * CFrame.new(0, 0, -(size.Z / 2 + Structures.Chest.DropGap))
	for index, itemId in contents do
		ItemService.spawn(itemId, front * CFrame.new((index - 1) * 2, 1, 0))
	end
	SoundCue.play("ChestOpen", cframe.Position)
	model:Destroy() -- TODO(asset): opening animation
end

-- Spawns one chest holding `contents` with its base on `cframe`.
local function spawnChest(cframe: CFrame, contents: { string }, parent: Instance): Model
	local model = AssetService.get(CHEST_ASSET) -- TODO(asset): Chest
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	Geometry.placeOnGround(model, cframe)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Chest"
	prompt.ActionText = "Open"
	prompt.HoldDuration = Structures.Chest.HoldSeconds
	prompt.MaxActivationDistance = GameConfig.Train.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	prompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		open(model, contents, prompt, player)
	end)

	model.Parent = parent
	table.insert(spawned, model)
	return model
end

local function rollExtra(rng: Random): string?
	if rng:NextNumber() < Loot.Chest.ExtraChance then
		return RandomUtil.pick(Loot.Chest.ExtraItems, rng)
	end
	return nil
end

-- Queues a match-start chest. `extras` = may hold an extra item (random sand chests, not lookouts).
function Chests.plan(cframe: CFrame, extras: boolean)
	table.insert(planned, { cframe = cframe, extras = extras })
end

-- Spawns every planned chest: guaranteed kits first, the rest random. Returns how many spawned.
function Chests.spawnPlanned(parent: Instance, rng: Random): number
	local plans = RandomUtil.shuffle(table.clone(planned), rng)
	table.clear(planned)

	local guaranteed = guaranteedKits()
	if #guaranteed > #plans then
		warn(`[Chests] {#guaranteed} guaranteed kits but only {#plans} chests - some guarantees are missing`)
	end
	local pool = chestPool()

	for index, plan in plans do
		local contents = { guaranteed[index] or RandomUtil.pick(pool, rng) }
		local extra = if plan.extras then rollExtra(rng) else nil
		if extra then
			table.insert(contents, extra)
		end
		spawnChest(plan.cframe, contents, parent)
	end
	return #plans
end

-- A single chest with a random kit (+ maybe an extra), e.g. an airdrop (Phase 12).
function Chests.spawnOne(cframe: CFrame, parent: Instance, rng: Random): Model
	local contents = { RandomUtil.pick(chestPool(), rng) }
	local extra = rollExtra(rng)
	if extra then
		table.insert(contents, extra)
	end
	return spawnChest(cframe, contents, parent)
end

function Chests.clear()
	table.clear(planned)
	for _, model in spawned do
		model:Destroy()
	end
	table.clear(spawned)
end

return Chests
