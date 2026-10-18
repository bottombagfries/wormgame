--!strict
-- Kit items (§6.6). Each kit also becomes an entry in Config/Items (size "Kit").
-- Behaviour lives in server/Kits/<id>.luau (KitService); Shovel is DigService, Dandylion Bundle NPCService.
-- Params starting with "Passive" apply all the time the kit is in the slot.

local Types = require(script.Parent.Parent.Types)

local Kits: { [string]: Types.KitDef } = {
	BullwormRifle = {
		id = "BullwormRifle",
		displayName = "Bullworm Rifle",
		uses = 1,
		guaranteed = 1,
		params = {
			Range = 400, -- TUNE
			HitSlack = 2, -- TUNE: a shot passing this close to the worm's head hits it
			RecoilSpeed = 45, -- TUNE: the shooter is pushed back this fast
			TracerSeconds = 0.3,
			DynamiteHitRadius = 1.5, -- TUNE: loose dynamite this close to the shot goes off
		},
	},
	CactusSeedPouch = {
		id = "CactusSeedPouch",
		displayName = "Cactus Seed Pouch",
		uses = 7,
		guaranteed = 0,
		params = {
			SmallCactusTrainRadius = 60, -- TUNE: seeds that land this close to the Train grow a small cactus
			ThrowSpeed = 50, -- TUNE
		},
	},
	Canteen = {
		id = "Canteen",
		displayName = "Canteen",
		guaranteed = 0,
		params = { PassiveStaminaUseMult = 0.65 }, -- jumping and sprinting cost 35 % less
	},
	CoffeeTin = {
		id = "CoffeeTin",
		displayName = "Coffee Tin",
		uses = 3,
		guaranteed = 0,
		params = { SpeedMult = 1.45, StaminaUseMult = 0.2, Seconds = 15, RevealSeconds = 20 },
	},
	CymbalMonkey = {
		id = "CymbalMonkey",
		displayName = "Cymbal Monkey",
		uses = 1,
		guaranteed = 0,
		params = { DisorientSeconds = 12, Radius = 80, ThrowSpeed = 50 }, -- Radius, ThrowSpeed TUNE
	},
	DandylionBundle = {
		id = "DandylionBundle",
		displayName = "Dandylion Bundle",
		guaranteed = 0,
		inChests = false, -- comes from behind the caboose / the vending machine (§7)
		params = {
			MaxActiveFlowers = 4, -- per Pardner; a 5th removes their oldest
			AttractRange = 40, -- TUNE: cattlebugs walk to the nearest flower within this
			ThrowSpeed = 50, -- TUNE: studs/s
			EatRadius = 3, -- TUNE: a bug this close to a flower eats it
			FlowerSeconds = 90, -- TUNE: a flower wilts after this long if nothing eats it
		},
	},
	SpiritBoard = {
		id = "SpiritBoard",
		displayName = "Spirit Board",
		refName = "Luigi Board",
		guaranteed = 1,
		params = {
			SpeedBonusPerGhost = 0.1, -- TUNE
			MaxSpeedBonus = 0.3,
			GhostPushCooldown = 12.5, -- for every ghost, while any living Pardner carries one
		},
	},
	MysteriousConcoction = {
		id = "MysteriousConcoction",
		displayName = "Mysterious Concoction",
		uses = 3,
		guaranteed = 0,
		params = {
			TeleportHeight = 4, -- the Teleport effect drops the drinker this far above the sand
			Effects = {
				{ id = "Heal", amount = 10, weight = 10.27 },
				{ id = "Heal", amount = 25, weight = 20.54 },
				{ id = "Heal", amount = 50, weight = 7.99 },
				{ id = "Hurt", amount = 25, weight = 22.83 },
				{ id = "Hurt", amount = 50, weight = 9.13 },
				{ id = "Heal", amount = 100, weight = 1.82 },
				{ id = "Die", weight = 4.56 },
				{ id = "Explode", weight = 2.28 },
				{ id = "Reveal", amount = 20, weight = 11.41 },
				{ id = "Teleport", weight = 9.13 },
			},
		},
	},
	DeadBook = {
		id = "DeadBook",
		displayName = "Book of the Dead",
		refName = "Necronomicon",
		uses = nil, -- not consumed; each use costs the reader health instead
		guaranteed = 1,
		params = { UserDamage = 35, UserDamageSeconds = 1, DamageTicks = 10, ReviveGap = 4 }, -- Gap TUNE
	},
	PogoStick = {
		id = "PogoStick",
		displayName = "Pogo Stick",
		uses = 5,
		guaranteed = 0,
		params = { LaunchSpeed = 110 }, -- TUNE
	},
	QuickEscapeKnife = {
		id = "QuickEscapeKnife",
		displayName = "Quick Escape Knife",
		uses = 1,
		guaranteed = 0,
		params = {},
	},
	Shovel = {
		id = "Shovel",
		displayName = "Shovel",
		guaranteed = 0,
		inChests = false, -- 8 in the caboose (§7)
		params = {
			DigSeconds = 2, -- TUNE: hold interact on sand this long
			DigRadius = 6, -- TUNE: anything buried this close to the dig point comes up
			DigReach = 2, -- TUNE: the dig point is this far in front of the Pardner
			DigMoveTolerance = 3, -- TUNE: moving farther than this cancels the dig
			DetectorMaxDistance = 300, -- TUNE: closeness = 100 - dist / this * 100
			DetectorTickSeconds = 0.25, -- TUNE: how often the metal detector reading updates
		},
	},
	Slingshot = {
		id = "Slingshot",
		displayName = "Slingshot",
		guaranteed = 0,
		params = { PassiveThrowPowerMult = 1.5 },
	},
	SnakeOil = {
		id = "SnakeOil",
		displayName = "Snake Oil",
		uses = 2,
		guaranteed = 0,
		params = { SpeedMult = 1.1, EscapeHealMin = 1, EscapeHealMax = 10 }, -- max 1 buff per Pardner
	},
	ZiplineCrossbow = {
		id = "ZiplineCrossbow",
		displayName = "Zipline Crossbow",
		uses = 1, -- TUNE
		guaranteed = 3,
		params = {
			Range = 300, -- TUNE
			MinLength = 10, -- TUNE: shorter shots don't make a line
			RideSpeed = 50, -- TUNE
			HangDrop = 3, -- TUNE: riders hang this far below the line
			RideHoldSeconds = 0.2, -- TUNE
			LineWidth = 0.3,
			EndSize = Vector3.new(1, 1, 1), -- the invisible part at each end that holds the Ride prompt
		},
	},
}

return Kits
