--!strict
-- Client side of Open the Safe (§10.7): the keypad screen (opened by the server when a Pardner uses the
-- safe), and the Puzzle Map panel + highlighted code signs while holding a Puzzle Map.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local InventoryController = require(script.Parent.InventoryController)
local MatchController = require(script.Parent.MatchController)
local KeypadScreen = require(script.Parent.UI.KeypadScreen)
local PuzzleMapHud = require(script.Parent.UI.PuzzleMapHud)

local HEADINGS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" } -- north is -Z
local PUZZLE_MAP = "PuzzleMap"
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 220, 90)

local SafeController = {}

local player = Players.LocalPlayer

local state: Types.SafeState = { active = false, signs = {}, recorded = {}, opened = false }
local keypad: KeypadScreen.Screen
local mapHud: PuzzleMapHud.Hud
local highlights: { [Instance]: Highlight } = {}
local fxFolder: Folder

-- "120 studs NE" from `from` to `to`.
local function describeWay(from: Vector3, to: Vector3): string
	local offset = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local index = math.round(math.atan2(offset.X, -offset.Z) / (math.pi / 4)) % #HEADINGS
	return `{math.floor(offset.Magnitude)} studs {HEADINGS[index + 1]}`
end

local function mapText(from: Vector3): string
	local lines = { "PUZZLE MAP" }
	local safePosition = state.safePosition
	if state.opened then
		table.insert(lines, "Safe: OPEN")
	elseif safePosition then
		table.insert(lines, `Safe: {describeWay(from, safePosition)}`)
	end

	local codeParts = {}
	for order, position in state.signs do
		local digit = state.recorded[tostring(order)]
		table.insert(codeParts, if digit then tostring(digit) else "_")
		local shown = if digit then `recorded {digit}` else describeWay(from, position)
		table.insert(lines, `Digit {order}: {shown}`)
	end
	table.insert(lines, `Code: {table.concat(codeParts, " ")}`)
	table.insert(lines, "Hold F at a highlighted sign to record it")
	return table.concat(lines, "\n")
end

local function updateHighlights(show: boolean)
	for _, sign in CollectionService:GetTagged(TagDefs.Tags.SafeDigit) do
		local order = sign:GetAttribute("Order")
		local inCode = typeof(order) == "number" and order > 0
		local highlight = highlights[sign]
		if show and inCode and not highlight then
			local new = Instance.new("Highlight")
			new.Adornee = sign
			new.FillColor = HIGHLIGHT_COLOR
			new.OutlineColor = HIGHLIGHT_COLOR
			new.FillTransparency = 0.6
			new.Parent = fxFolder
			highlights[sign] = new
		elseif highlight and not (show and inCode) then
			highlight:Destroy()
			highlights[sign] = nil
		end
	end
	for sign, highlight in highlights do
		if not sign.Parent then
			highlight:Destroy()
			highlights[sign] = nil
		end
	end
end

local function update()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local holding = state.active
		and MatchController.isPardner()
		and InventoryController.getState().hand == PUZZLE_MAP
		and root ~= nil
		and root:IsA("BasePart")

	mapHud.setVisible(holding)
	updateHighlights(holding)
	if holding and root and root:IsA("BasePart") then
		mapHud.setText(mapText(root.Position))
	end
	if not MatchController.isPardner() then
		keypad.close()
	end
end

function SafeController.init()
	local playerGui = player:WaitForChild("PlayerGui")
	keypad = KeypadScreen.create(playerGui, function(code: string)
		Net.event("Request_SafeCode"):FireServer(code)
	end)
	mapHud = PuzzleMapHud.create(playerGui)

	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "SafeFx"
	fxFolder.Parent = camera
end

function SafeController.start()
	Net.event("State_Safe").OnClientEvent:Connect(function(newState: Types.SafeState)
		state = newState
		if state.opened or not state.active then
			keypad.close()
		end
	end)
	Net.event("Ui_SafeKeypad").OnClientEvent:Connect(function()
		keypad.open()
	end)
	RunService.RenderStepped:Connect(update)
end

return SafeController
