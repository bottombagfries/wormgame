--!strict
-- Pardner stats (§8.1), camera, ghost (§8.4), death & revive (§9).

return {
	MaxHealth = 100,

	WalkSpeed = 16, -- TUNE
	SprintSpeed = 24, -- TUNE
	MoveThreshold = 2, -- TUNE: studs/s of horizontal speed the server counts as "moving" for sprint drain

	-- Stamina
	MaxStamina = 100,
	MinStaminaFraction = 0.4, -- max stamina = MaxStamina * max(this, hp / maxHp)
	SprintStaminaPerSecond = 12, -- TUNE
	SprintMinStamina = 10, -- TUNE: after hitting 0, sprint is locked until stamina is back to this
	JumpStaminaCost = 10, -- TUNE
	JumpMinInterval = 0.3, -- TUNE: server ignores jump intents faster than this
	StaminaRegenPerSecond = 15, -- TUNE
	StaminaRegenDelay = 1, -- TUNE: seconds after last use

	-- Grip & climbing
	MaxGrip = 100,
	ClimbGripPerSecond = 10, -- TUNE
	ClimbStaminaPerSecond = 15, -- TUNE: once grip is empty
	ClimbJumpGripFraction = 0.08,
	GripRegenPerSecond = 25, -- TUNE: only while standing on something
	ClimbSpeed = 10, -- TUNE
	ClimbReach = 2.5, -- TUNE: wall raycast length from the root part
	ClimbWallOffset = 1.3, -- TUNE: how far the root part is held from the wall
	ClimbStickGain = 10, -- TUNE: how hard the climber is pulled to ClimbWallOffset
	ClimbMaxNormalY = 0.5, -- TUNE: surfaces flatter than this are not walls
	ClimbMaxForce = 1e6, -- TUNE
	ClimbRegrabCooldown = 0.5, -- TUNE: seconds after letting go before a wall can be grabbed again
	ClimbJumpSpeed = 30, -- TUNE: upward speed during a climb-jump
	ClimbJumpSeconds = 0.25, -- TUNE
	ClimbJumpCooldown = 0.6, -- TUNE
	MantleUpSpeed = 40, -- TUNE: launch when climbing over the top of a wall
	MantleForwardSpeed = 10, -- TUNE
	ClimbConfirmGrace = 0.5, -- TUNE: client waits this long for the server to confirm a climb
	ClimbServerSlack = 3, -- TUNE: extra studs on the server's wall check
	ClimbValidateGrace = 0.6, -- TUNE: seconds with no wall before the server cancels a climb
	GroundCheckSlack = 1, -- TUNE: extra studs on the server's ground check

	StateSendRate = 15, -- TUNE: State_Pardner updates per second

	Camera = {
		MinZoom = 4, -- TUNE
		MaxZoom = 30, -- TUNE
		DefaultFov = 70,
		AimFov = 55, -- TUNE
		AimZoom = 6, -- TUNE
		AimOffset = Vector3.new(2.2, 0.6, 0), -- TUNE: over the right shoulder
		AimLerpSpeed = 14, -- TUNE
		ZoomRestoreDelay = 0.15, -- TUNE
	},

	-- Inventory (§6.2)
	BagSlots = 3,
	BackpackSlots = 2,
	PickupRange = 10, -- TUNE: root part to item, plus half the item's size
	PickupSlack = 4, -- TUNE: extra studs the server allows
	HoverRayLength = 200, -- TUNE: camera ray used to find the hovered item
	HoldDistance = 1.2, -- TUNE: gap between the root part and a held item
	HoldHeight = 0, -- TUNE
	DropDistance = 2.5, -- TUNE: how far in front a dropped item lands
	DeathScatterRadius = 3, -- TUNE: bag contents spill in a ring this wide
	ThrowPower = 60, -- TUNE: studs/s
	ThrowUpTilt = 0.12, -- TUNE: throws aim slightly above the crosshair
	ThrowOriginHeight = 1.5, -- TUNE: above the root part
	ThrowOriginForward = 1.5, -- TUNE: plus half the item's size
	ThrowClientOwned = true, -- thrower's client simulates the item until it rests (§16)
	ItemRestSpeed = 0.5, -- TUNE: below this an item counts as resting
	ItemRestSeconds = 1, -- TUNE
	ItemLooseMaxSeconds = 12, -- TUNE: network ownership returns to the server after this regardless
	ThrowArc = {
		Points = 24, -- TUNE
		TimeStep = 0.07, -- TUNE: seconds between dots
		DotSize = 0.4, -- TUNE
	},

	-- Detection (§8.1)
	PingSpeed = 1, -- TUNE: studs/s of horizontal movement on sand

	Adrenaline = {
		SpeedMult = 1.5,
		Seconds = 10,
	},

	-- Death & revive (§8.1, §9)
	DigestionSeconds = 60,
	ReviveMaxHealthLossFraction = 0.25, -- of base MaxHealth, per revive
	MinMaxHealth = 10,
	BodyRemoveSeconds = 2, -- TUNE: how long a dead Pardner's body stays
	JarSpawnHeight = 2, -- TUNE: heart jars appear this far above the ground/body
	ReviveSpawnHeight = 4, -- TUNE: revived Pardners appear this far above the revive point
	ReviveTickSeconds = 0.2, -- TUNE: how often digestion and the Church ring are checked

	Ghost = {
		FlySpeed = 30, -- TUNE
		MaxForce = 1e6, -- TUNE
		SpawnHeight = 5, -- TUNE: above where the Pardner died
		PushMaxForce = 24, -- applied as a speed change in studs/s at full charge
		PushChargeSeconds = 2, -- TUNE
		PushCooldown = 25,
		PushRange = 12, -- TUNE: ghost to item, plus half the item's size
		PushSlack = 6, -- TUNE: extra studs the server allows
		ArrowLength = 10, -- TUNE: length of the direction arrow at full charge
	},
}
