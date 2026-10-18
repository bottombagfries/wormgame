--!strict
-- The vending machine at the Train (§7): while an objective needs it, it makes one of each of its
-- products (puzzle map, dandylion bundle) every VendingSeconds. Hold the prompt to take what's ready.
-- Objectives add their product in setup; the machine appears with the first product. MapService
-- steps it and clears it with the rest of the match's map.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local TrainConfig = GameConfig.Train

type Product = { itemId: string, ready: boolean, timer: number }

local VendingMachine = {}

local model: Model? = nil
local prompt: ProximityPrompt? = nil
local products: { Product } = {}

local function refresh()
	if not prompt then
		return
	end
	local ready = {}
	for _, product in products do
		if product.ready then
			table.insert(ready, Items[product.itemId].displayName)
		end
	end
	prompt.ObjectText = if #ready > 0 then `Vending machine: {table.concat(ready, ", ")}` else "Vending machine (empty)"
	prompt.Enabled = #ready > 0
end

local function onVend(player: Player)
	local machine = model
	local root = PardnerService.getLiving()[player]
	if not machine or not prompt or not root then
		return
	end
	if
		(root.Position - machine:GetPivot().Position).Magnitude
		> prompt.MaxActivationDistance + TrainConfig.PromptSlack
	then
		return
	end
	local cframe, size = machine:GetBoundingBox()
	local front = cframe * CFrame.new(0, -size.Y / 2 + 2, -(size.Z / 2 + 2))
	for _, product in products do
		if product.ready then
			product.ready = false
			product.timer = 0
			ItemService.spawn(product.itemId, front)
			break
		end
	end
	refresh()
end

local function build(parent: Instance, cabooseCFrame: CFrame)
	local machine = AssetService.get("VendingMachine") -- TODO(asset): VendingMachine
	for _, descendant in machine:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	Geometry.placeOnGround(machine, cabooseCFrame * CFrame.new(TrainConfig.VendingOffset))

	local newPrompt = Instance.new("ProximityPrompt")
	newPrompt.ActionText = "Take"
	newPrompt.HoldDuration = TrainConfig.VendingHoldSeconds
	newPrompt.MaxActivationDistance = TrainConfig.PromptDistance
	newPrompt.RequiresLineOfSight = false
	newPrompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	newPrompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	newPrompt.Parent = machine.PrimaryPart
	newPrompt.Triggered:Connect(onVend)

	machine.Parent = parent
	model = machine
	prompt = newPrompt
end

-- Adds a product (once). The first one builds the machine in `parent`, beside the caboose.
function VendingMachine.addProduct(itemId: string, parent: Instance, cabooseCFrame: CFrame)
	for _, product in products do
		if product.itemId == itemId then
			return
		end
	end
	if not model then
		build(parent, cabooseCFrame)
	end
	table.insert(products, { itemId = itemId, ready = false, timer = 0 })
	refresh()
end

function VendingMachine.step(dt: number)
	local changed = false
	for _, product in products do
		if not product.ready then
			product.timer += dt
			if product.timer >= TrainConfig.VendingSeconds then
				product.ready = true
				changed = true
			end
		end
	end
	if changed then
		refresh()
	end
end

function VendingMachine.clear()
	if model then
		model:Destroy()
	end
	model = nil
	prompt = nil
	table.clear(products)
end

return VendingMachine
