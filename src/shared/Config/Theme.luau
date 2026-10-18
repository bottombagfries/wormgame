--!strict
-- UI theme (Phase 13). Every UI color, font, corner radius, stroke, padding, size and tween time lives here;
-- UI files never hard-code them.
--
-- Visual direction: "sun-bleached frontier notice board". Panels are weathered paper pinned on dark wood
-- (a warm paper fill with a thick dark-wood stroke and a hard drop shadow offset down-right). Headings use a
-- western wood-type face (Antique) for big titles and a heavy serif (Merriweather) for buttons and headings,
-- like a wanted poster; body and numbers use a clean sans (Builder Sans) for
-- readability. One accent: brass/ochre. Warning = burnt orange, danger = brick red, good = sage green. Role
-- colors: the Worm is a deep flesh red, Pardners a faded denim blue. Motion is short and snappy (Quad, Back on
-- pop-ins).

local rgb = Color3.fromRGB

local Theme = {}

Theme.Colors = {
	-- Surfaces
	Paper = rgb(236, 222, 188),
	PaperLight = rgb(246, 238, 216),
	PaperDark = rgb(212, 192, 150),
	Wood = rgb(104, 68, 40),
	WoodDark = rgb(58, 38, 24),
	Shadow = rgb(20, 12, 8),
	Scrim = rgb(12, 8, 6), -- full-screen dimmer behind modals

	-- Text
	Ink = rgb(48, 32, 22),
	InkSoft = rgb(110, 86, 64),
	TextLight = rgb(250, 242, 224),

	-- Accent + states
	Accent = rgb(214, 160, 58), -- brass
	AccentDark = rgb(150, 104, 30),
	Warning = rgb(226, 132, 44),
	Danger = rgb(186, 58, 44),
	Good = rgb(122, 156, 84),
	Disabled = rgb(150, 140, 124),

	-- Bars
	Track = rgb(40, 28, 20),
	Ghost = rgb(250, 236, 200), -- the trailing "damage" fill
	Health = rgb(196, 64, 52),
	Stamina = rgb(126, 168, 82),
	Grip = rgb(222, 168, 62),
	Fuel = rgb(232, 118, 40),

	-- Roles
	Worm = rgb(160, 52, 60),
	WormDark = rgb(92, 26, 34),
	Pardner = rgb(70, 112, 150),
	PardnerDark = rgb(36, 62, 90),
	GhostRole = rgb(190, 220, 240),
}

Theme.Fonts = {
	Display = Font.fromEnum(Enum.Font.Antique), -- big titles: panel banners, role card, results
	Heading = Font.new(Font.fromEnum(Enum.Font.Merriweather).Family, Enum.FontWeight.Heavy), -- buttons, headings
	Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	BodyBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
	Numbers = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy),
}

Theme.Text = {
	MinSize = 12, -- UITextSizeConstraint
	MaxSize = 48,
	HeadingMax = 64,
}

Theme.Corner = {
	Panel = UDim.new(0, 10),
	Button = UDim.new(0, 8),
	Bar = UDim.new(0, 6),
	Slot = UDim.new(0, 8),
	Pill = UDim.new(1, 0),
}

Theme.Stroke = {
	Panel = 3,
	Button = 2,
	Bar = 2,
	Slot = 2,
	Text = 1.5, -- outline on light text over the world
}

Theme.Padding = {
	Panel = UDim.new(0, 14),
	Button = UDim.new(0, 8),
	Gap = UDim.new(0, 8), -- between items in a list
}

Theme.Shadow = {
	Offset = UDim2.fromOffset(4, 5),
	Transparency = 0.45,
}

Theme.Sizes = {
	MinTap = 44, -- px at 1080p; buttons are never shorter
	ScreenMargin = 0.02, -- fraction of the screen kept clear around the HUD
	BarHeight = 0.034, -- fraction of screen height
	SlotSize = 0.07, -- fraction of screen height (square)
}

Theme.Tween = {
	Fast = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Normal = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Pop = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Bar = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Ghost = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	GhostDelay = 0.35, -- seconds the ghost fill waits before catching up
}

Theme.Button = {
	HoverScale = 1.05,
	PressScale = 0.95,
}

-- UI sound hooks (keys into Config/Sounds); played locally by Components/UiSound.
Theme.Sounds = {
	Click = "UiClick",
	Hover = "UiHover",
	Error = "UiError",
	Objective = "UiObjective",
	Reveal = "UiReveal",
}

return Theme
