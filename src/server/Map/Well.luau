--!strict
-- The town well (§7): always gives something, so fuel can never run out. It gains a token every
-- TokenSeconds (up to MaxTokens). Using it with a token gives a random household item, without one a
-- rusty tin can; very rarely a cursed trinket. The prompt shows the token count.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Structures = require(ReplicatedStorage.Shared.Config.Structures)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local ItemService = require(script.Parent.Parent.Services.ItemService)
local PardnerService = require(script.Parent.Parent.Services.PardnerService)

local WellConfig = Structures.Well
local CURSED_TRINKET = "CursedTrinket"

local Well = {}

local model: Model? = nil
local prompt: ProximityPrompt? = nil
local tokens = 0
local tokenTimer = 0
local nextUse = 0
local rng = Random.new()

local function refreshPrompt()
	local well = model
	if prompt and well then
		prompt.ObjectText = `Well ({tokens}/{WellConfig.MaxTokens} tokens)`
		well:SetAttribute("Tokens", tokens)
	end
end

local function onUse(player: Player)
	local well = model
	local root = PardnerService.getLiving()[player]
	if not well or not prompt or not root or os.clock() < nextUse then
		return
	end
	if
		(root.Position - well:GetPivot().Position).Magnitude
		> prompt.MaxActivationDistance + GameConfig.Train.PromptSlack
	then
		return
	end
	nextUse = os.clock() + WellConfig.UseCooldown

	local itemId
	if rng:NextNumber() < WellConfig.CursedTrinketChance then
		itemId = CURSED_TRINKET
	elseif tokens > 0 then
		tokens -= 1
		itemId = RandomUtil.pick(WellConfig.TokenItems, rng)
	else
		itemId = WellConfig.NoTokenItem
	end
	refreshPrompt()

	-- Out in front of the well, toward whoever used it.
	local center = well:GetPivot().Position
	local _, size = well:GetBoundingBox()
	local toward = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
	local direction = if toward.Magnitude > 0.1 then toward.Unit else Vector3.zAxis
	local position = center + direction * (size.X / 2 + WellConfig.DropGap) + Vector3.yAxis * 2
	ItemService.spawn(itemId, CFrame.new(position))
end

function Well.spawn(cframe: CFrame, parent: Instance)
	Well.clear()
	local well = AssetService.get("TownWell") -- TODO(asset): TownWell
	for _, descendant in well:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	Geometry.placeOnGround(well, cframe)

	local newPrompt = Instance.new("ProximityPrompt")
	newPrompt.ActionText = "Draw from the well"
	newPrompt.HoldDuration = WellConfig.HoldSeconds
	newPrompt.MaxActivationDistance = GameConfig.Train.PromptDistance
	newPrompt.RequiresLineOfSight = false
	newPrompt.KeyboardKeyCode = Keybinds.Prompt[1] :: Enum.KeyCode
	newPrompt.GamepadKeyCode = Keybinds.Prompt[2] :: Enum.KeyCode
	newPrompt.Parent = well.PrimaryPart
	newPrompt.Triggered:Connect(onUse)

	well.Parent = parent
	model = well
	prompt = newPrompt
	tokens = 0
	tokenTimer = 0
	nextUse = 0
	refreshPrompt()
end

function Well.step(dt: number)
	if not model or tokens >= WellConfig.MaxTokens then
		return
	end
	tokenTimer += dt
	if tokenTimer >= WellConfig.TokenSeconds then
		tokenTimer = 0
		tokens += 1
		refreshPrompt()
	end
end

function Well.clear()
	if model then
		model:Destroy()
	end
	model = nil
	prompt = nil
end

return Well
