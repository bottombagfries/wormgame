--!strict
-- Objective 7 (§10): a safe sits in a random ranch house. DigitSigns signs with digits stand around the
-- map, but only `safeDigits` of them make the code, in order. A Puzzle Map shows which signs count,
-- where they and the safe are, and what's been recorded so far. Holding a map, a Pardner records a
-- sign's digit for everyone. The right code at the safe's keypad drops the Train Manual; picking it
-- up completes the objective. Puzzle maps wait at the caboose and come from the vending machine.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Difficulty = require(ReplicatedStorage.Shared.Config.Difficulty)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local Ground = require(ReplicatedStorage.Shared.Util.Ground)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local VendingMachine = require(script.Parent.Parent.Map.VendingMachine)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local MapService = require(script.Parent.Parent.Services.MapService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)
local TrainService = require(script.Parent.Parent.Services.TrainService)

local Params = Objectives.OpenSafe.params :: { [string]: any }
local TrainConfig = GameConfig.Train
local Tags = TagDefs.Tags
local PUZZLE_MAP = "PuzzleMap"
local TRAIN_MANUAL = "TrainManual"
local MAX_CODE_LENGTH = 12

type Sign = { model: Model, digit: number, order: number }

local safe: Model? = nil
local signs: { Sign } = {}
local code: { number } = {}
local recorded: { [string]: number } = {}
local opened = false
local done = false
local nextTry: { [Player]: number } = {}
local connections: { RBXScriptConnection } = {}
local manualConnection: Signal.Connection? = nil
local stateRemote: RemoteEvent? = nil
local notifyRemote: RemoteEvent? = nil

local function buildState(): Types.SafeState
	local positions = {}
	for order = 1, #code do
		for _, sign in signs do
			if sign.order == order then
				table.insert(positions, sign.model:GetPivot().Position)
			end
		end
	end
	return {
		active = safe ~= nil,
		safePosition = if safe then safe:GetPivot().Position else nil,
		signs = positions,
		recorded = recorded,
		opened = opened,
	}
end

local function broadcast()
	if stateRemote then
		stateRemote:FireAllClients(buildState())
	end
end

local function notify(player: Player?, text: string)
	if not notifyRemote then
		return
	end
	if player then
		notifyRemote:FireClient(player, text)
	else
		notifyRemote:FireAllClients(text)
	end
end

local function makePrompt(part: BasePart, objectText: string, actionText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = objectText
	prompt.ActionText = actionText
	prompt.HoldDuration = Params.PromptHoldSeconds
	prompt.MaxActivationDistance = TrainConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	prompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	prompt.Parent = part
	return prompt
end

local function inReach(player: Player, model: Model): boolean
	local root = PardnerService.getLiving()[player]
	local reach = TrainConfig.PromptDistance + TrainConfig.PromptSlack
	return root ~= nil and (root.Position - model:GetPivot().Position).Magnitude <= reach
end

local function anchorAll(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

local function addDigitLabel(part: BasePart, digit: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DigitLabel"
	billboard.Size = Params.SignLabelSize
	billboard.StudsOffsetWorldSpace = Vector3.new(0, Params.SignLabelHeight, 0)
	billboard.MaxDistance = GameConfig.Debug.LabelMaxDistance
	billboard.LightInfluence = 0
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = tostring(digit)
	label.Parent = billboard
end

local function onRecord(player: Player, sign: Sign)
	if not inReach(player, sign.model) then
		return
	end
	if ItemService.getHandItemId(player) ~= PUZZLE_MAP then
		notify(player, "Hold a Puzzle Map to record this digit")
		return
	end
	if sign.order == 0 then
		notify(player, "This sign isn't part of the code - check the Puzzle Map")
		return
	end
	recorded[tostring(sign.order)] = sign.digit
	broadcast()
	notify(nil, `Safe digit #{sign.order} recorded: {sign.digit}`)
end

local function onCode(player: Player, entered: any)
	local model = safe
	if not model or opened or typeof(entered) ~= "string" or #entered > MAX_CODE_LENGTH then
		return
	end
	if not inReach(player, model) or os.clock() < (nextTry[player] or 0) then
		return
	end
	nextTry[player] = os.clock() + Params.WrongCodeCooldown
	if entered ~= table.concat(code) then
		notify(player, "Wrong code")
		return
	end

	opened = true
	local cframe, size = model:GetBoundingBox()
	ItemService.spawn(TRAIN_MANUAL, cframe * CFrame.new(0, 0, -(size.Z / 2 + 2)))
	notify(nil, "The safe is open - grab the Train Manual!")
	broadcast()
end

local function spawnSafe(parent: Instance, rng: Random)
	local houses = MapService.getRanchHouses()
	local point: Vector3
	if #houses > 0 then
		point = MapService.getLootPoints(RandomUtil.pick(houses, rng), 1, rng)[1]
	else
		warn("[OpenSafe] No ranch houses - putting the safe near the Train")
		local trainSpot = MapService.getMarkerCFrames(Tags.TrainSpot, CFrame.identity)[1]
		local position = trainSpot.Position + Params.FallbackSafeOffset
		point = Vector3.new(position.X, Ground.sandBelow(position) or position.Y, position.Z)
	end

	local model = AssetService.get("Safe") -- TODO(asset): Safe
	anchorAll(model)
	Geometry.placeOnGround(model, CFrame.new(point))
	model.Parent = parent
	safe = model

	local prompt = makePrompt(model.PrimaryPart :: BasePart, "Safe", "Use keypad")
	prompt.Triggered:Connect(function(player)
		if inReach(player, model) and not opened then
			Net.event("Ui_SafeKeypad"):FireClient(player)
		end
	end)
end

local function spawnSigns(count: number, parent: Instance, rng: Random)
	for _ = 1, Params.DigitSigns do
		local spot = MapService.findLooseSpot(rng)
		if not spot then
			continue
		end
		local model = AssetService.get("SafeDigitSign") -- TODO(asset): SafeDigitSign
		anchorAll(model)
		Geometry.placeOnGround(model, CFrame.new(spot) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
		model.Parent = parent
		local sign: Sign = { model = model, digit = rng:NextInteger(0, 9), order = 0 }
		addDigitLabel(model.PrimaryPart :: BasePart, sign.digit)
		table.insert(signs, sign)

		local prompt = makePrompt(model.PrimaryPart :: BasePart, "Digit sign", "Record digit")
		prompt.Triggered:Connect(function(player)
			onRecord(player, sign)
		end)
	end

	-- The code is `count` of the signs, in a random order.
	for order, sign in RandomUtil.sample(signs, count, rng) do
		sign.order = order
		table.insert(code, sign.digit)
	end
	for _, sign in signs do
		sign.model:SetAttribute("Digit", sign.digit)
		sign.model:SetAttribute("Order", sign.order)
		sign.model:AddTag(Tags.SafeDigit)
	end
end

local OpenSafe: Types.ObjectiveModule = {
	setup = function(context: Types.ObjectiveContext)
		local parent = MapService.getRuntimeFolder()
		if not parent then
			warn("[OpenSafe] The map has not been populated - no safe")
			return
		end
		stateRemote = Net.event("State_Safe")
		notifyRemote = Net.event("Fx_Notify")
		local rng = Random.new()
		local difficulty = Difficulty[context.difficulty] or Difficulty[GameConfig.DefaultDifficulty]

		spawnSafe(parent, rng)
		spawnSigns(difficulty.safeDigits, parent, rng)

		-- Puzzle maps at the caboose, and more from the vending machine (§7).
		local caboose = TrainService.getCabooseCFrame()
		for index = 1, Params.PuzzleMaps do
			ItemService.spawn(PUZZLE_MAP, caboose * CFrame.new(Params.MapOffset + Vector3.new(0, 1, index * 2)))
		end
		VendingMachine.addProduct(PUZZLE_MAP, parent, caboose)

		table.insert(connections, Net.onRequest("Request_SafeCode", onCode))
		table.insert(
			connections,
			Players.PlayerAdded:Connect(function(player)
				if stateRemote then
					stateRemote:FireClient(player, buildState())
				end
			end)
		)
		manualConnection = ItemService.instantUsed:connect(function(_player: Player, itemId: string)
			if itemId == TRAIN_MANUAL then
				done = true
			end
		end)
		broadcast()
	end,

	getProgress = function(): (number, number)
		return if done then 1 else 0, 1
	end,

	cleanup = function()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		local current = manualConnection
		if current then
			current:disconnect()
		end
		manualConnection = nil
		for _, sign in signs do
			sign.model:Destroy()
		end
		table.clear(signs)
		if safe then
			safe:Destroy()
		end
		safe = nil
		table.clear(code)
		table.clear(recorded)
		table.clear(nextTry)
		opened = false
		done = false
		broadcast() -- active = false hides the puzzle map panel
	end,
}

return OpenSafe
