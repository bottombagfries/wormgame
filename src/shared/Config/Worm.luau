--!strict
-- Worm stats (§8.2), detection, and the mouth-escape minigame (§8.3).

return {
	Segments = 8,
	SegmentShrink = 0.9, -- TUNE: each segment's scale relative to the one before it
	SegmentSpacing = 0.6, -- TUNE: gap between segment centers, as a fraction of their combined radius
	MoundSize = Vector3.new(0.6, 14, 14), -- TUNE: the dirt bump above a burrowed worm (a cylinder on its side)
	MoundColor = Color3.fromRGB(150, 120, 80),

	MaxHealth = 100,

	-- Movement
	UndergroundSpeed = 45, -- TUNE
	SurfaceSpeed = 20, -- TUNE
	SneakSpeedMult = 0.5, -- TUNE
	UndergroundDepth = 6, -- TUNE: head center, in studs below the sand surface
	DepthGain = 6, -- TUNE: how hard the head is pulled to its target height
	MaxVerticalSpeed = 60, -- TUNE
	EdgeLookahead = 0.25, -- TUNE: seconds ahead the client checks for the end of the sand
	WallProbe = 3, -- TUNE: studs beyond the head's surface that block crawling above ground
	MaxForce = 1e7, -- TUNE
	SpawnRadius = 220, -- TUNE: worms start this far from the TrainSpot
	SpawnAttempts = 12,

	-- Ground probes (Util/Ground)
	GroundProbeUp = 8, -- TUNE: surface rays start this far above the point
	SandProbeUp = 200, -- TUNE: sand rays start this far above the point
	GroundProbeLength = 600,

	-- Server validation of the client-driven head
	SpeedTolerance = 1.25, -- TUNE
	ValidateWindow = 0.5, -- TUNE: seconds between checks
	ValidateSlack = 8, -- TUNE: free studs per window
	MaxAirSpeed = 220, -- TUNE
	SurfaceSlack = 4, -- TUNE: how far above the sand a burrowed head may be before it is pushed back down

	-- Pounce (Phase 11 moves abilities into AbilityService; cooldown comes from Config/Abilities)
	PounceAngle = 35, -- TUNE: degrees above the horizon
	PounceMinAirTime = 0.3, -- TUNE: landing is ignored for this long after launch
	GrabRadius = 7, -- TUNE: from the head's center, while airborne
	GrabImmunitySeconds = 3, -- TUNE: after escaping

	NightCooldownMult = 0.67, -- TUNE
	AbilityTickSeconds = 0.2, -- TUNE: how often ability zones (sinkhole, tar, magma, storm) affect Pardners
	ZoneTransparency = 0.4, -- ability zone greyboxes

	-- Damage, as a fraction of MaxHealth
	EscapeDamageFraction = 0.15, -- TUNE
	RifleDamageFraction = 0.4,
	DynamiteDamageFraction = 0.5, -- TUNE
	UnburrowHealthFraction = 1, -- TUNE: must heal to this before unburrowing again

	-- Healing rings, centered on where damage was taken. Past the last ring its rate still applies.
	HealRings = {
		{ radius = 60, healPerSecond = 1, nightHealPerSecond = 1 }, -- TUNE
		{ radius = 140, healPerSecond = 3, nightHealPerSecond = 9 }, -- TUNE
		{ radius = 260, healPerSecond = 6, nightHealPerSecond = 18 }, -- TUNE
	},

	-- Vision & detection
	DetectionTickSeconds = 0.1, -- TUNE
	SandProbeDown = 6, -- TUNE: how far below a Pardner's root part the "standing on sand" ray reaches
	SurfaceVisionRadius = 60, -- TUNE: red dots while above ground
	CloseItemRadius = 15, -- TUNE: items always seen this close
	PingLifetime = 1.2, -- TUNE: seconds a red dot stays on screen
	PingDotSize = 18, -- TUNE: pixels
	MaxPingDots = 40,
	VisionRefreshSeconds = 0.1, -- TUNE

	Camera = {
		MinZoom = 25, -- TUNE
		MaxZoom = 90, -- TUNE
		AnchorHeight = 4, -- TUNE: the camera looks at a point this far above the ground over a burrowed worm
	},

	Grab = {
		InitialDamage = 5,
		InitialDamageMinHealth = 10, -- no flat damage at or below this
		DrainPerSecond = 4, -- TUNE
		ItemSwallowSeconds = 1.5,
		ReleaseHeight = 4, -- TUNE: an escaping Pardner appears this far above the ground
	},

	Minigame = {
		ArrowsToEscape = 12, -- TUNE
		WrongInputPenalty = 2, -- TUNE: arrows of progress lost
		CheckpointEvery = 4, -- TUNE
		MinInputInterval = 0.12, -- TUNE: anti-macro
		AutoEscapeSeconds = 5.5,
		Arrows = { "Up", "Down", "Left", "Right" },
	},
}
