--!strict
-- The Worm HUD (§14, restyled in Phase 13): a status card bottom-left (health bar, mode, healing-ring hint)
-- and the ability bar bottom-center (one slot per ability with its key, name and cooldown). Layout only;
-- HUDController feeds it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Bar = require(script.Parent.Components.Bar)
local Label = require(script.Parent.Components.Label)
local Slot = require(script.Parent.Components.Slot)
local Style = require(script.Parent.Components.Style)

export type AbilityView = {
	id: string,
	key: string,
	name: string,
	remaining: number, -- seconds of cooldown left (0 = ready)
	total: number,
}

export type Hud = {
	gui: ScreenGui,
	setHealth: (value: number, max: number) -> (),
	setMode: (text: string) -> (),
	setRing: (text: string) -> (),
	setAbilities: (list: { AbilityView }) -> (),
	setCompact: (compact: boolean) -> (),
}

local CONTROLS = "WASD move · right-drag look · abilities aim with the camera"
local WIDE_POSITION = UDim2.fromScale(0.015, 0.975)
local COMPACT_POSITION = UDim2.fromScale(0.015, 0.84)
local ROW_HEIGHT = 0.085 -- ability slots are this share of the screen height (Style.fitRow shrinks them to fit)
local ROW_GAP = 5
local ROW_MIN_PX = 36
local ROW_MAX_PX = 90

local WormHud = {}

function WormHud.create(parent: Instance): Hud
	local colors = Theme.Colors
	local gui = Style.screen("WormHud", 2)
	gui.Enabled = false

	-- Status card --------------------------------------------------------------------------------
	local root = Instance.new("Frame")
	root.Name = "Status"
	root.AnchorPoint = Vector2.new(0, 1)
	root.Position = WIDE_POSITION
	root.Size = UDim2.fromScale(0.26, 0.15)
	root.ZIndex = 2
	root.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(210, 96)
	limits.MaxSize = Vector2.new(400, 160)
	limits.Parent = root
	local body = Style.shadowed(root, Theme.Corner.Panel)
	body.BackgroundColor3 = colors.WormDark
	Style.corner(body, Theme.Corner.Panel)
	Style.stroke(body, colors.WoodDark, Theme.Stroke.Panel)
	Style.padding(body, Theme.Padding.Button)

	local mode = Label.new(body, {
		name = "Mode",
		font = Theme.Fonts.Heading,
		color = colors.TextLight,
		size = UDim2.fromScale(1, 0.28),
		align = Enum.TextXAlignment.Left,
		maxTextSize = 22,
	})
	mode.ZIndex = 4
	local health = Bar.new(body, {
		label = "Worm",
		color = colors.Worm,
		size = UDim2.fromScale(1, 0.28),
		position = UDim2.fromScale(0, 0.32),
	})
	local ring = Label.new(body, {
		name = "Ring",
		font = Theme.Fonts.BodyBold,
		color = colors.Accent,
		size = UDim2.fromScale(1, 0.36),
		position = UDim2.fromScale(0, 0.64),
		align = Enum.TextXAlignment.Left,
		maxTextSize = 16,
	})
	ring.TextWrapped = true
	ring.ZIndex = 4

	-- Ability bar --------------------------------------------------------------------------------
	local row = Instance.new("Frame")
	row.Name = "Abilities"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.fromScale(0.5, 0.975)
	row.Size = UDim2.fromScale(0.96, 0.085)
	row.BackgroundTransparency = 1
	row.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ROW_GAP)
	layout.Parent = row

	local controls = Label.new(gui, {
		name = "Controls",
		font = Theme.Fonts.BodyBold,
		color = colors.PaperLight,
		size = UDim2.fromScale(0.6, 0.026),
		position = UDim2.fromScale(0.5, 0.975 - 0.085 - 0.008),
		anchor = Vector2.new(0.5, 1),
		maxTextSize = 16,
		outline = true,
	})
	controls.Text = CONTROLS

	gui.Parent = parent

	local slots: { [string]: { slot: Slot.Slot, wasCooling: boolean } } = {}
	local signature = ""
	local slotCount = 0
	local function fit()
		Style.fitRow(row, gui, slotCount, ROW_GAP, ROW_HEIGHT, ROW_MIN_PX, ROW_MAX_PX)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

	return {
		gui = gui,
		setHealth = function(value: number, max: number)
			health.set(value, max)
		end,
		setMode = function(text: string)
			mode.Text = text
		end,
		setRing = function(text: string)
			ring.Text = text
		end,
		setAbilities = function(list: { AbilityView })
			-- Rebuild the slots only when the set of abilities changes (the loadout arrives once).
			local ids = {}
			for _, view in list do
				table.insert(ids, `{view.id}={view.key}`)
			end
			local newSignature = table.concat(ids, ",")
			if newSignature ~= signature then
				signature = newSignature
				for _, entry in slots do
					entry.slot.frame:Destroy()
				end
				table.clear(slots)
				for order, view in list do
					local slot =
						Slot.new(row, { name = view.id, key = view.key, size = UDim2.fromScale(1, 1), order = order })
					slot.setItem(view.name)
					slots[view.id] = { slot = slot, wasCooling = false }
				end
				slotCount = #list
				fit()
			end
			for _, view in list do
				local entry = slots[view.id]
				if entry then
					local cooling = view.remaining > 0
					entry.slot.setCooldown(view.remaining, view.total)
					if entry.wasCooling and not cooling then
						entry.slot.pop() -- ready again
					end
					entry.wasCooling = cooling
				end
			end
		end,
		setCompact = function(compact: boolean)
			root.Position = if compact then COMPACT_POSITION else WIDE_POSITION
		end,
	}
end

return WormHud
