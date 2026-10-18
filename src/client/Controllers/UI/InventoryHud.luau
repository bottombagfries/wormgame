--!strict
-- The inventory HUD (§6.2, restyled in Phase 13), bottom-center: the kit slot (T) and the bag slots (an
-- item fills as many slots as its size), the hands pill above them, the shovel's metal detector, and the
-- hover label above the Pardner's head. Layout only; InventoryController feeds it state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Types = require(ReplicatedStorage.Shared.Types)
local Label = require(script.Parent.Components.Label)
local Slot = require(script.Parent.Components.Slot)
local Style = require(script.Parent.Components.Style)

export type Hud = {
	gui: ScreenGui,
	setState: (state: Types.InventoryState) -> (),
	setHover: (adornee: Instance?, text: string) -> (),
	setDetector: (percent: number?) -> (), -- nil hides it
}

local ROW_HEIGHT = 0.085 -- share of the screen height
local ROW_Y = 0.975
local ROW_GAP = 6
local ROW_MIN_PX = 40
local ROW_MAX_PX = 96
local HAND_HINT = "Q store · G drop · R use · hold RMB + LMB throw"
local EMPTY_HINT = "E pick up"
local CONTINUED = "·" -- the extra slots a big item takes up

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

local function keyName(action: string, fallback: string): string
	local binds = (Keybinds :: any)[action]
	return if binds and binds[1] then binds[1].Name else fallback
end

local function pill(parent: Instance, name: string, size: UDim2, position: UDim2, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.ZIndex = 2
	Style.corner(frame, Theme.Corner.Pill)
	Style.stroke(frame, Theme.Colors.WoodDark, Theme.Stroke.Button)
	frame.Parent = parent
	return frame
end

function InventoryHud.create(parent: Instance): Hud
	local colors = Theme.Colors
	local gui = Style.screen("InventoryHud", 2)

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.fromScale(0.5, ROW_Y)
	row.Size = UDim2.fromScale(0.7, ROW_HEIGHT)
	row.BackgroundTransparency = 1
	row.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ROW_GAP)
	layout.Parent = row

	local kit = Slot.new(row, { name = "Kit", key = keyName("UseKit", "T"), size = UDim2.fromScale(1, 1), order = 0 })
	kit.frame.BackgroundColor3 = colors.Pardner
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(0, 3, 0.8, 0)
	divider.BackgroundColor3 = colors.WoodDark
	divider.BorderSizePixel = 0
	divider.LayoutOrder = 1
	divider.Parent = row

	local hands =
		pill(gui, "Hands", UDim2.fromScale(0.42, 0.04), UDim2.fromScale(0.5, ROW_Y - ROW_HEIGHT - 0.012), colors.Paper)
	local handsLimits = Instance.new("UISizeConstraint")
	handsLimits.MinSize = Vector2.new(260, 26)
	handsLimits.Parent = hands
	local handText = Label.new(hands, {
		name = "Text",
		font = Theme.Fonts.BodyBold,
		size = UDim2.fromScale(0.94, 0.8),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 18,
	})
	handText.ZIndex = 3

	-- Shovel metal detector (§10.2): a bulb that glows brighter the closer the nearest buried thing is.
	local detector = pill(
		gui,
		"Detector",
		UDim2.fromScale(0.22, 0.04),
		UDim2.fromScale(0.5, ROW_Y - ROW_HEIGHT - 0.065),
		colors.WoodDark
	)
	detector.Visible = false
	local detectorLimits = Instance.new("UISizeConstraint")
	detectorLimits.MinSize = Vector2.new(190, 26)
	detectorLimits.Parent = detector
	local bulb = Instance.new("Frame")
	bulb.Name = "Bulb"
	bulb.AnchorPoint = Vector2.new(0, 0.5)
	bulb.Position = UDim2.fromScale(0.04, 0.5)
	bulb.Size = UDim2.fromScale(0.7, 0.7)
	bulb.ZIndex = 3
	Style.aspect(bulb, 1)
	Style.corner(bulb, Theme.Corner.Pill)
	bulb.Parent = detector
	local reading = Label.new(detector, {
		name = "Reading",
		font = Theme.Fonts.BodyBold,
		color = colors.TextLight,
		size = UDim2.fromScale(0.74, 0.8),
		position = UDim2.fromScale(0.22, 0.1),
		align = Enum.TextXAlignment.Left,
		maxTextSize = 18,
	})
	reading.ZIndex = 3

	-- Small label above the Pardner's head for the hovered item (§6.2).
	local hover = Instance.new("BillboardGui")
	hover.Name = "HoverLabel"
	hover.Size = UDim2.fromOffset(240, 30)
	hover.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	hover.AlwaysOnTop = true
	hover.Enabled = false
	hover.ResetOnSpawn = false
	hover.Parent = parent -- a BillboardGui only renders directly under PlayerGui, not inside a ScreenGui
	local hoverBack = Instance.new("Frame")
	hoverBack.Size = UDim2.fromScale(1, 1)
	hoverBack.BackgroundColor3 = colors.Paper
	hoverBack.Parent = hover
	Style.corner(hoverBack, Theme.Corner.Pill)
	Style.stroke(hoverBack, colors.WoodDark, Theme.Stroke.Button)
	local hoverText = Label.new(hoverBack, {
		font = Theme.Fonts.BodyBold,
		size = UDim2.fromScale(0.92, 0.78),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		maxTextSize = 18,
	})

	gui.Parent = parent

	local bagSlots: { Slot.Slot } = {}
	local lastKit: string? = nil
	-- Kit + bag slots (+ a little for the divider) always fit across the row.
	local function fit()
		Style.fitRow(row, gui, #bagSlots + 1.2, ROW_GAP, ROW_HEIGHT, ROW_MIN_PX, ROW_MAX_PX)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	return {
		gui = gui,
		setState = function(state: Types.InventoryState)
			-- Kit slot
			local uses = if state.kitUses then ` x{state.kitUses}` else ""
			kit.setItem(if state.kit then `{displayName(state.kit)}{uses}` else nil)
			kit.frame.BackgroundColor3 = if state.kit then colors.Pardner else colors.PardnerDark
			if state.kit ~= lastKit and state.kit then
				kit.pop()
			end
			lastKit = state.kit

			-- Bag: one Slot per unit of capacity.
			while #bagSlots < state.capacity do
				table.insert(bagSlots, Slot.new(row, { size = UDim2.fromScale(1, 1), order = #bagSlots + 2 }))
			end
			while #bagSlots > state.capacity do
				(table.remove(bagSlots) :: Slot.Slot).frame:Destroy()
			end
			fit()
			local cursor = 1
			for index, itemId in state.bag do
				for part = 1, slotsOf(itemId) do
					local slot = bagSlots[cursor]
					if slot then
						slot.setItem(if part == 1 then `[{index}] {displayName(itemId)}` else CONTINUED)
					end
					cursor += 1
				end
			end
			for index = cursor, #bagSlots do
				bagSlots[index].setItem(nil)
			end

			handText.Text = if state.hand
				then `Hands: {displayName(state.hand)}   ({HAND_HINT})`
				else `Hands: empty   ({EMPTY_HINT})`
		end,
		setHover = function(adornee: Instance?, text: string)
			hover.Adornee = adornee
			hover.Enabled = adornee ~= nil
			hoverText.Text = text
		end,
		setDetector = function(percent: number?)
			detector.Visible = percent ~= nil
			if percent then
				bulb.BackgroundColor3 = colors.WoodDark:Lerp(colors.Accent, math.clamp(percent / 100, 0, 1))
				reading.Text = `Metal detector  {percent}%`
			end
		end,
	}
end

return InventoryHud
