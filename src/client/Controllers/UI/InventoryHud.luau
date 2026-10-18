--!strict
-- Builds the inventory screen: bag slots, hands, kit slot, hover label, notices.
-- Layout only; InventoryController feeds it state. TODO(asset): replace with real UI art.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local Types = require(ReplicatedStorage.Shared.Types)

export type Hud = {
	gui: ScreenGui,
	setState: (state: Types.InventoryState) -> (),
	setHover: (adornee: Instance?, text: string) -> (),
	notify: (text: string) -> (),
	setDetector: (percent: number?) -> (), -- nil hides it
}

local SLOT = 64
local GAP = 6
local MARGIN = 20
local NOTICE_SECONDS = 2.5
local BACK_COLOR = Color3.fromRGB(25, 25, 25)
local FILLED_COLOR = Color3.fromRGB(70, 60, 45)
local KIT_COLOR = Color3.fromRGB(45, 65, 95)
local HAND_HINT = "Q store · G drop · R use · hold RMB + LMB throw"
local EMPTY_HINT = "E pick up"
local DETECTOR_WIDTH = 240
local BULB_SIZE = 24
local BULB_OFF = Color3.fromRGB(60, 50, 20)
local BULB_ON = Color3.fromRGB(255, 240, 120)

local InventoryHud = {}

local function displayName(itemId: string): string
	local def = Items[itemId]
	return if def then def.displayName else itemId
end

local function slotsOf(itemId: string): number
	local def = Items[itemId]
	local size = def and def.size
	return if typeof(size) == "number" then math.max(size, 1) else 1
end

local function makeBox(parent: Instance, width: number, color: Color3, text: string, order: number): TextLabel
	local box = Instance.new("TextLabel")
	box.Size = UDim2.fromOffset(width, SLOT)
	box.BackgroundColor3 = color
	box.BackgroundTransparency = 0.3
	box.BorderSizePixel = 0
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Font = Enum.Font.SourceSansBold
	box.TextSize = 15
	box.TextWrapped = true
	box.Text = text
	box.LayoutOrder = order
	box.Parent = parent
	return box
end

local function makeText(parent: Instance, name: string, size: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent
	return label
end

function InventoryHud.create(parent: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "InventoryHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Bottom center: [kit] [bag slots...], with the hands line above.
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -MARGIN)
	row.Size = UDim2.fromOffset(0, SLOT)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.BackgroundTransparency = 1
	row.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, GAP)
	layout.Parent = row

	local hand = makeText(gui, "Hand", UDim2.fromOffset(600, 24), 18)
	hand.AnchorPoint = Vector2.new(0.5, 1)
	hand.Position = UDim2.new(0.5, 0, 1, -(MARGIN + SLOT + GAP))

	local notice = makeText(gui, "Notice", UDim2.fromOffset(600, 28), 22)
	notice.AnchorPoint = Vector2.new(0.5, 1)
	notice.Position = UDim2.new(0.5, 0, 1, -(MARGIN + SLOT + GAP + 30))
	notice.TextColor3 = Color3.fromRGB(255, 220, 120)
	local noticeToken = 0

	-- Shovel metal detector (§10.2): a bulb that glows brighter the closer the nearest buried thing is.
	local detector = Instance.new("Frame")
	detector.Name = "Detector"
	detector.AnchorPoint = Vector2.new(0.5, 1)
	detector.Position = UDim2.new(0.5, 0, 1, -(MARGIN + SLOT + GAP + 64))
	detector.Size = UDim2.fromOffset(DETECTOR_WIDTH, BULB_SIZE)
	detector.BackgroundTransparency = 1
	detector.Visible = false
	detector.Parent = gui

	local bulb = Instance.new("Frame")
	bulb.Name = "Bulb"
	bulb.Size = UDim2.fromOffset(BULB_SIZE, BULB_SIZE)
	bulb.BorderSizePixel = 0
	bulb.Parent = detector
	local bulbCorner = Instance.new("UICorner")
	bulbCorner.CornerRadius = UDim.new(1, 0)
	bulbCorner.Parent = bulb

	local reading = makeText(detector, "Reading", UDim2.new(1, -(BULB_SIZE + GAP), 1, 0), 20)
	reading.Position = UDim2.fromOffset(BULB_SIZE + GAP, 0)
	reading.TextXAlignment = Enum.TextXAlignment.Left

	-- Small label above the Pardner's head for the hovered item (§6.2).
	local hover = Instance.new("BillboardGui")
	hover.Name = "HoverLabel"
	hover.Size = UDim2.fromOffset(260, 26)
	hover.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	hover.AlwaysOnTop = true
	hover.Enabled = false
	hover.ResetOnSpawn = false
	hover.Parent = parent -- a BillboardGui only renders directly under PlayerGui, not inside a ScreenGui
	local hoverText = makeText(hover, "Text", UDim2.fromScale(1, 1), 18)

	gui.Parent = parent

	local boxes: { Instance } = {}

	return {
		gui = gui,
		setState = function(state: Types.InventoryState)
			for _, box in boxes do
				box:Destroy()
			end
			table.clear(boxes)

			local uses = if state.kitUses then ` x{state.kitUses}` else ""
			local kitText = if state.kit then `Kit (T)\n{displayName(state.kit)}{uses}` else "Kit\n-"
			table.insert(boxes, makeBox(row, SLOT + GAP * 2, KIT_COLOR, kitText, 0))

			-- An item takes as many slot-widths as its size.
			for index, itemId in state.bag do
				local slots = slotsOf(itemId)
				local width = SLOT * slots + GAP * (slots - 1)
				table.insert(boxes, makeBox(row, width, FILLED_COLOR, `[{index}] {displayName(itemId)}`, index))
			end
			for index = 1, math.max(0, state.capacity - state.used) do
				table.insert(boxes, makeBox(row, SLOT, BACK_COLOR, "", #state.bag + index))
			end

			hand.Text = if state.hand
				then `Hands: {displayName(state.hand)}   ({HAND_HINT})`
				else `Hands: empty   ({EMPTY_HINT})`
		end,
		setHover = function(adornee: Instance?, text: string)
			hover.Adornee = adornee
			hover.Enabled = adornee ~= nil
			hoverText.Text = text
		end,
		notify = function(text: string)
			noticeToken += 1
			local token = noticeToken
			notice.Text = text
			task.delay(NOTICE_SECONDS, function()
				if noticeToken == token then
					notice.Text = ""
				end
			end)
		end,
		setDetector = function(percent: number?)
			detector.Visible = percent ~= nil
			if percent then
				bulb.BackgroundColor3 = BULB_OFF:Lerp(BULB_ON, math.clamp(percent / 100, 0, 1))
				reading.Text = `Metal detector: {percent}%`
			end
		end,
	}
end

return InventoryHud
