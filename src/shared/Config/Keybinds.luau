--!strict
-- Action -> inputs. Each entry is an Enum.KeyCode or Enum.UserInputType. Mobile comes later.

local Keybinds: { [string]: { EnumItem } } = {
	Sprint = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3 },
	Jump = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA },
	Aim = { Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2 },
	LetGo = { Enum.KeyCode.C, Enum.KeyCode.ButtonB }, -- stop climbing

	Interact = { Enum.KeyCode.E, Enum.KeyCode.ButtonX }, -- pick up the hovered item
	Prompt = { Enum.KeyCode.F, Enum.KeyCode.ButtonY }, -- ProximityPrompts (lever, horn): keyboard key, gamepad button
	Drop = { Enum.KeyCode.G, Enum.KeyCode.DPadDown },
	StoreInBag = { Enum.KeyCode.Q, Enum.KeyCode.DPadUp },
	UseHeld = { Enum.KeyCode.R, Enum.KeyCode.DPadRight }, -- e.g. light the dynamite in your hands
	UseKit = { Enum.KeyCode.T, Enum.KeyCode.ButtonL1 }, -- use the kit slot (e.g. throw a dandylion toward the camera)
	Throw = { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2 }, -- only while aiming

	-- Worm (same keys as some Pardner actions; each controller only listens in its own role)
	WormBurrow = { Enum.KeyCode.E, Enum.KeyCode.ButtonX }, -- burrow / unburrow
	WormPounce = { Enum.UserInputType.MouseButton1, Enum.KeyCode.Space, Enum.KeyCode.ButtonR2 },
	WormSneak = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3 }, -- hold
	WormSonar = { Enum.KeyCode.Q, Enum.KeyCode.ButtonY },
	WormSinkhole = { Enum.KeyCode.F, Enum.KeyCode.ButtonB },
	WormAbility1 = { Enum.KeyCode.One, Enum.KeyCode.DPadLeft }, -- first chosen ability
	WormAbility2 = { Enum.KeyCode.Two, Enum.KeyCode.DPadRight }, -- second chosen ability

	-- Ghost (dead Pardner)
	GhostUp = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA },
	GhostDown = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonB },
	GhostPush = { Enum.KeyCode.E, Enum.KeyCode.ButtonX }, -- hold to charge, release to push

	-- Mouth-escape minigame
	ArrowUp = { Enum.KeyCode.W, Enum.KeyCode.Up, Enum.KeyCode.DPadUp },
	ArrowDown = { Enum.KeyCode.S, Enum.KeyCode.Down, Enum.KeyCode.DPadDown },
	ArrowLeft = { Enum.KeyCode.A, Enum.KeyCode.Left, Enum.KeyCode.DPadLeft },
	ArrowRight = { Enum.KeyCode.D, Enum.KeyCode.Right, Enum.KeyCode.DPadRight },
	AutoEscape = { Enum.KeyCode.G, Enum.KeyCode.ButtonB }, -- the drop key toggles auto-escape

	-- Raw movement, for when there is no character for Roblox's control module to drive (worm)
	MoveForward = { Enum.KeyCode.W, Enum.KeyCode.Up },
	MoveBack = { Enum.KeyCode.S, Enum.KeyCode.Down },
	MoveLeft = { Enum.KeyCode.A, Enum.KeyCode.Left },
	MoveRight = { Enum.KeyCode.D, Enum.KeyCode.Right },

	-- Take the Nth item out of the bag
	Bag1 = { Enum.KeyCode.One },
	Bag2 = { Enum.KeyCode.Two },
	Bag3 = { Enum.KeyCode.Three },
	Bag4 = { Enum.KeyCode.Four },
	Bag5 = { Enum.KeyCode.Five },
	Bag6 = { Enum.KeyCode.Six },
	Bag7 = { Enum.KeyCode.Seven },
	Bag8 = { Enum.KeyCode.Eight },
	Bag9 = { Enum.KeyCode.Nine },
}

return Keybinds
