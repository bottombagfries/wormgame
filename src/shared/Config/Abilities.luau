--!strict
-- Worm abilities (§12). Server halves: server/Abilities/<id>.luau; client effects:
-- shared/AbilityBehaviors/<id>.luau (optional). AbilityService runs cooldowns (× Worm.NightCooldownMult
-- after sundown). `action` is the Config/Keybinds action for the default abilities; the two chosen ones
-- use WormAbility1 / WormAbility2 in pick order. All non-wiki numbers are TUNE.

local Types = require(script.Parent.Parent.Types)

local Abilities: { [string]: Types.AbilityDef } = {
	-- Default (all worms)
	Pounce = {
		id = "Pounce",
		displayName = "Pounce",
		description = "Launch forward and grab whatever you hit.",
		kind = "Default",
		action = "WormPounce",
		cooldown = 3, -- TUNE
		params = { LaunchSpeed = 70, UnburrowLaunchSpeed = 120 },
	},
	Sneak = {
		id = "Sneak",
		displayName = "Sneak",
		description = "Hold to move without rumbling.",
		kind = "Default",
		action = "WormSneak",
		cooldown = 0, -- hold
		params = { SpeedMult = 0.5 },
	},
	Burrow = {
		id = "Burrow",
		displayName = "Burrow",
		description = "Dive under the sand or come up for air.",
		kind = "Default",
		action = "WormBurrow",
		cooldown = 0, -- toggle
		params = {},
	},
	SonarScream = {
		id = "SonarScream",
		displayName = "Sonar Scream",
		description = "Reveal everything nearby for a few seconds.",
		kind = "Default",
		action = "WormSonar",
		cooldown = 60,
		params = { Radius = 120, RevealSeconds = 6, NightCooldown = 40, RingSeconds = 1.2 },
	},
	Sinkhole = {
		id = "Sinkhole",
		displayName = "Sinkhole",
		description = "A sand vortex that slows Pardners to a crawl.",
		kind = "Default",
		action = "WormSinkhole",
		cooldown = 70,
		params = { Radius = 25, Seconds = 10, SlowFraction = 0.8 },
	},

	-- Choose 2 before the match
	Sandstorm = {
		id = "Sandstorm",
		displayName = "Sandstorm",
		description = "A roaming tornado that flings Pardners about.",
		kind = "Choosable",
		cooldown = 90,
		params = {
			Seconds = 16,
			Radius = 20,
			Height = 60,
			MoveSpeed = 18,
			FlingSpeed = 60, -- studs/s given to Pardners and props caught in it
			FlingInterval = 1, -- seconds between flings of the same thing
			RevealSeconds = 3, -- caught Pardners stay revealed this long
		},
	},
	ArmoredCarapace = {
		id = "ArmoredCarapace",
		displayName = "Armored Carapace",
		description = "A shell that blocks one hit and flattens a building.",
		kind = "Choosable",
		cooldown = 60,
		params = {
			Seconds = 16,
			BlastRadius = 25,
			BlastStaminaLoss = 30,
			BlastStaminaUseMult = 1.3,
			BlastDamageTakenMult = 1.3,
			BlastDebuffSeconds = 15,
		},
	},
	Stealth = {
		id = "Stealth",
		displayName = "Stealth",
		description = "No sound, tremors or sand spray until you pounce.",
		kind = "Choosable",
		cooldown = 90,
		params = { Seconds = 20 },
	},
	Bodyslam = {
		id = "Bodyslam",
		displayName = "Bodyslam",
		description = "Mid-air: slam down and knock Pardners back.",
		kind = "Choosable",
		cooldown = 60,
		params = {
			ImpactWidth = 30,
			PardnerDamage = 10,
			StructureDamage = 1,
			Knockback = 60,
			DiveSpeed = 150, -- straight down
			LandTimeout = 3, -- gives up waiting for the landing after this long
			LandPollSeconds = 0.05,
		},
	},
	TarWall = {
		id = "TarWall",
		displayName = "Tar Wall",
		description = "Raise a ring of tar spires Pardners can't cross.",
		kind = "Choosable",
		cooldown = 65,
		params = {
			Seconds = 18,
			Radius = 30,
			Spires = 20,
			SlowFraction = 0.5, -- Pardners right by the spires
			SlowDistance = 5, -- "right by" = this close to a spire
		},
	},
	Sandtrap = {
		id = "Sandtrap",
		displayName = "Sandtrap",
		description = "A hidden trap that drags a Pardner into your mouth.",
		kind = "Choosable",
		cooldown = 45,
		params = { Radius = 8, Seconds = 60, HoldDepth = 3, RevealSeconds = 5 },
	},
	BileBomb = {
		id = "BileBomb",
		displayName = "Bile Bomb",
		description = "Lob a sticky bomb that bursts after a moment.",
		kind = "Choosable",
		cooldown = 25,
		params = {
			FuseSeconds = 3.5,
			Damage = 20,
			Radius = 14,
			LaunchSpeed = 80,
			StickRadius = 4,
			BurstVisualSeconds = 1,
		},
	},
	MagmaTrail = {
		id = "MagmaTrail",
		displayName = "Magma Trail",
		description = "Underground: leave a trail of burning magma.",
		kind = "Choosable",
		cooldown = 120,
		params = {
			Seconds = 10,
			PatchSeconds = 12,
			PatchInterval = 0.5, -- a new patch this often while active
			DamagePerSecond = 5,
			LingerSeconds = 1.5,
			PatchRadius = 7,
		},
	},
}

return Abilities
