--!strict
-- Phase 13 Shop window: one card per game pass in Config/Shop (cosmetic / convenience only). Buying opens
-- Roblox's purchase prompt; passes without an id yet say "Coming soon"; owned passes say "Owned".

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Button = require(script.Parent.Components.Button)
local Label = require(script.Parent.Components.Label)
local Modal = require(script.Parent.Components.Modal)
local Style = require(script.Parent.Components.Style)

local ShopScreen = {}

function ShopScreen.create(parent: Instance): Modal.Modal
	local colors = Theme.Colors
	local player = Players.LocalPlayer
	local modal = Modal.new(parent, {
		name = "ShopScreen",
		title = "GENERAL STORE",
		size = UDim2.fromScale(0.56, 0.74),
		aspect = 0.8,
		minWidth = 340,
	})

	Label.new(modal.content, {
		text = "Looks and comforts only - nothing here helps you win.",
		font = Theme.Fonts.BodyBold,
		color = colors.InkSoft,
		size = UDim2.fromScale(1, 0.07),
		maxTextSize = 18,
	}).ZIndex =
		4

	local grid = Instance.new("Frame")
	grid.Name = "Passes"
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromScale(0, 0.09)
	grid.Size = UDim2.fromScale(1, 0.91)
	grid.ZIndex = 3
	grid.Parent = modal.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(0.485, 0.47)
	layout.CellPadding = UDim2.fromScale(0.03, 0.03)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local buttons: { { pass: Shop.GamePass, button: Button.Button } } = {}

	for order, pass in Shop.GamePasses do
		local card = Instance.new("Frame")
		card.Name = pass.name
		card.BackgroundColor3 = colors.PaperLight
		card.LayoutOrder = order
		card.ZIndex = 4
		Style.corner(card, Theme.Corner.Button)
		Style.stroke(card, colors.WoodDark, Theme.Stroke.Slot)
		Style.padding(card, Theme.Padding.Button)
		card.Parent = grid

		Label.new(card, {
			text = pass.name,
			font = Theme.Fonts.Heading,
			size = UDim2.fromScale(1, 0.2),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 22,
		}).ZIndex =
			5
		local description = Label.new(card, {
			text = pass.description,
			size = UDim2.fromScale(1, 0.44),
			position = UDim2.fromScale(0, 0.22),
			align = Enum.TextXAlignment.Left,
			maxTextSize = 16,
		})
		description.TextWrapped = true
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.ZIndex = 5

		local available = pass.id > 0
		local button = Button.new(card, {
			text = if available then `R$ {pass.price}` else Shop.ComingSoonText,
			variant = "Accent",
			size = UDim2.fromScale(1, 0.28),
			position = UDim2.fromScale(0, 1),
			anchor = Vector2.new(0, 1),
			onClick = function()
				if pass.id > 0 then
					MarketplaceService:PromptGamePassPurchase(player, pass.id)
				end
			end,
		})
		button.button.ZIndex = 6
		button.setEnabled(available)
		table.insert(buttons, { pass = pass, button = button })
	end

	-- Mark passes this player already owns (and newly bought ones).
	local function markOwned(passId: number)
		for _, entry in buttons do
			if entry.pass.id == passId then
				entry.button.setText("Owned")
				entry.button.setVariant("Good")
				entry.button.setEnabled(false)
			end
		end
	end
	task.spawn(function()
		for _, entry in buttons do
			local id = entry.pass.id
			if id > 0 then
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
				if ok and owns then
					markOwned(id)
				end
			end
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId, purchased)
		if who == player and purchased then
			markOwned(passId)
		end
	end)

	return modal
end

return ShopScreen
