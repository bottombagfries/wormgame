--!strict
-- The lobby's Cosmetics window: worm skins. Left, a slowly turning 3D preview of the selected skin with its
-- name, description and an Equip / Unlock button; right, every skin as a card with color swatches and a lock
-- line. Equipping is a request (CosmeticsService checks ownership); the window follows the player's
-- WormSkin and OwnedPasses attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local WormSkins = require(ReplicatedStorage.Shared.Config.WormSkins)
local WormSkin = require(ReplicatedStorage.Shared.WormSkin)
local Button = require(script.Parent.Components.Button)
local Label = require(script.Parent.Components.Label)
local Modal = require(script.Parent.Components.Modal)
local Style = require(script.Parent.Components.Style)

export type Callbacks = {
	onEquip: (skinId: string) -> (),
	onUnlock: () -> (), -- opens the shop
}

local PREVIEW_SEGMENTS = 3
local PREVIEW_SPIN = 0.5 -- radians per second
local PREVIEW_CAMERA = CFrame.lookAt(Vector3.new(16, 8, -20), Vector3.new(0, 4, 8))

local CosmeticsScreen = {}

local function passName(key: string): string
	for _, pass in Shop.GamePasses do
		if pass.key == key then
			return pass.name
		end
	end
	return key
end

function CosmeticsScreen.create(parent: Instance, callbacks: Callbacks): Modal.Modal
	local colors = Theme.Colors
	local player = Players.LocalPlayer
	local modal = Modal.new(parent, {
		name = "CosmeticsScreen",
		title = "WORM SKINS",
		size = UDim2.fromScale(0.66, 0.74),
		aspect = 1.35,
		minWidth = 360,
	})

	local function owns(key: string): boolean
		local list = player:GetAttribute("OwnedPasses")
		return typeof(list) == "string" and table.find(string.split(list, ","), key) ~= nil
	end
	local function canUse(skin: WormSkins.Skin): boolean
		return skin.unlock == "Free" or owns(skin.unlock)
	end
	local function equipped(): string
		local id = player:GetAttribute("WormSkin")
		return if typeof(id) == "string" then id else WormSkins.Default
	end

	-- Preview (left) ---------------------------------------------------------------------------
	local left = Instance.new("Frame")
	left.Name = "Preview"
	left.BackgroundTransparency = 1
	left.Size = UDim2.fromScale(0.44, 1)
	left.ZIndex = 3
	left.Parent = modal.content

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Worm"
	viewport.Size = UDim2.fromScale(1, 0.5)
	viewport.BackgroundColor3 = colors.WoodDark
	viewport.Ambient = Color3.fromRGB(170, 160, 150)
	viewport.LightColor = Color3.fromRGB(255, 240, 220)
	viewport.LightDirection = Vector3.new(-1, -2, 1)
	viewport.ZIndex = 4
	Style.corner(viewport, Theme.Corner.Button)
	Style.stroke(viewport, colors.WoodDark, Theme.Stroke.Slot)
	viewport.Parent = left
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = PREVIEW_CAMERA
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- The head at the origin facing the camera side (-Z), segments trailing behind along +Z.
	local worm = Instance.new("Model")
	worm.Name = "PreviewWorm"
	local pieces: { Model } = {}
	local head = AssetService.get("WormHead")
	head:PivotTo(CFrame.new(0, 0, 0))
	head.Parent = worm
	table.insert(pieces, head)
	local z = head:GetExtentsSize().Z / 2
	for index = 1, PREVIEW_SEGMENTS do
		local segment = AssetService.get("WormSegment")
		segment:ScaleTo(WormConfig.SegmentShrink ^ (index - 1))
		local depth = segment:GetExtentsSize().Z
		z += depth * WormConfig.SegmentSpacing * 0.5 + depth * 0.25
		segment:PivotTo(CFrame.new(0, 0, z))
		z += depth * 0.25
		segment.Parent = worm
		table.insert(pieces, segment)
	end
	for _, descendant in worm:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	worm.Parent = viewport
	local center = worm:GetPivot()

	local nameLabel = Label.new(left, {
		font = Theme.Fonts.Heading,
		size = UDim2.fromScale(1, 0.09),
		position = UDim2.fromScale(0, 0.51),
		maxTextSize = 26,
	})
	nameLabel.ZIndex = 4
	local description = Label.new(left, {
		color = colors.InkSoft,
		size = UDim2.fromScale(1, 0.18),
		position = UDim2.fromScale(0, 0.6),
		maxTextSize = 16,
	})
	description.TextWrapped = true
	description.ZIndex = 4

	local selected = equipped()
	local action: Button.Button

	-- Skin list (right) ------------------------------------------------------------------------
	local list = Instance.new("Frame")
	list.Name = "Skins"
	list.BackgroundTransparency = 1
	list.AnchorPoint = Vector2.new(1, 0)
	list.Position = UDim2.fromScale(1, 0)
	list.Size = UDim2.fromScale(0.53, 1)
	list.ZIndex = 3
	list.Parent = modal.content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.02, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local cards: { [string]: { button: TextButton, stroke: UIStroke, status: TextLabel } } = {}

	local function refresh()
		local skin = WormSkin.get(selected)
		for index, piece in pieces do
			WormSkin.apply(piece, skin.id, index - 1)
		end
		nameLabel.Text = skin.displayName
		description.Text = skin.description

		local current = equipped()
		if skin.id == current then
			action.setText("EQUIPPED")
			action.setVariant("Good")
			action.setEnabled(false)
		elseif canUse(skin) then
			action.setText("EQUIP")
			action.setVariant("Accent")
			action.setEnabled(true)
		else
			action.setText(`UNLOCK - {passName(skin.unlock)}`)
			action.setVariant("Wood")
			action.setEnabled(true)
		end

		for id, card in cards do
			local each = WormSkin.get(id)
			local isSelected = id == selected
			card.stroke.Color = if isSelected then colors.Accent else colors.WoodDark
			card.stroke.Thickness = if isSelected then Theme.Stroke.Slot + 1 else Theme.Stroke.Slot
			card.button.BackgroundColor3 = if isSelected then colors.PaperLight else colors.Paper
			card.status.Text = if id == current
				then "Equipped"
				elseif canUse(each) then (if each.unlock == "Free" then "Free" else "Owned")
				else `Locked - {passName(each.unlock)}`
			card.status.TextColor3 = if canUse(each) then colors.Good else colors.Danger
		end
	end

	action = Button.new(left, {
		text = "",
		size = UDim2.fromScale(1, 0.14),
		position = UDim2.fromScale(0, 1),
		anchor = Vector2.new(0, 1),
		onClick = function()
			local skin = WormSkin.get(selected)
			if canUse(skin) then
				callbacks.onEquip(skin.id)
			else
				callbacks.onUnlock()
			end
		end,
	})
	action.button.ZIndex = 5

	for order, skin in WormSkins.Skins do
		local button = Instance.new("TextButton")
		button.Name = skin.id
		button.Text = ""
		button.AutoButtonColor = false
		button.Size = UDim2.fromScale(1, 0.18)
		button.LayoutOrder = order
		button.ZIndex = 4
		Style.corner(button, Theme.Corner.Button)
		local stroke = Style.stroke(button, colors.WoodDark, Theme.Stroke.Slot)
		button.Parent = list

		-- Color swatches
		local swatches = Instance.new("Frame")
		swatches.BackgroundTransparency = 1
		swatches.AnchorPoint = Vector2.new(0, 0.5)
		swatches.Position = UDim2.fromScale(0.03, 0.5)
		swatches.Size = UDim2.fromScale(0.32, 0.36)
		swatches.ZIndex = 5
		swatches.Parent = button
		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.Padding = UDim.new(0, 3)
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.Parent = swatches
		for _, color in skin.swatch do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromScale(0.22, 1) -- up to 4 dots always fit across
			dot.BackgroundColor3 = color
			dot.ZIndex = 6
			Style.aspect(dot, 1)
			Style.corner(dot, Theme.Corner.Pill)
			Style.stroke(dot, colors.WoodDark, 1.5)
			dot.Parent = swatches
		end

		Label.new(button, {
			text = skin.displayName,
			font = Theme.Fonts.Heading,
			size = UDim2.fromScale(0.6, 0.5),
			position = UDim2.fromScale(0.38, 0.06),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 22,
		}).ZIndex =
			5
		local status = Label.new(button, {
			font = Theme.Fonts.BodyBold,
			size = UDim2.fromScale(0.6, 0.36),
			position = UDim2.fromScale(0.38, 0.58),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 16,
		})
		status.ZIndex = 5
		cards[skin.id] = { button = button, stroke = stroke, status = status }

		local scale = Style.scaler(button)
		button.MouseEnter:Connect(function()
			Style.tween(scale, Theme.Tween.Fast, { Scale = 1.03 })
		end)
		button.MouseLeave:Connect(function()
			Style.tween(scale, Theme.Tween.Fast, { Scale = 1 })
		end)
		button.Activated:Connect(function()
			selected = skin.id
			refresh()
		end)
	end

	player:GetAttributeChangedSignal("WormSkin"):Connect(function()
		selected = equipped()
		refresh()
	end)
	player:GetAttributeChangedSignal("OwnedPasses"):Connect(refresh)
	refresh()

	-- Spin the preview only while the window is open.
	local angle = 0
	RunService.RenderStepped:Connect(function(dt)
		if modal.isOpen() then
			angle += dt * PREVIEW_SPIN
			worm:PivotTo(center * CFrame.Angles(0, angle, 0))
		end
	end)

	return modal
end

return CosmeticsScreen
