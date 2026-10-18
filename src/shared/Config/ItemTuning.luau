--!strict
-- Numbers for specific item mechanics (§6.5, §6.7, §10). Item *definitions* live in Config/Items.

return {
	-- Dynamite (§6.7)
	DynamiteFuse = 4, -- TUNE
	DynamiteChainFuseMult = 0.5, -- hit by another blast
	DynamiteBlastRadius = 18, -- TUNE (worm damage is Config.Worm.DynamiteDamageFraction)
	QuarryStartDynamite = 3, -- TUNE
	QuarryDynamiteSeconds = 90,
	LitSparkleColor = Color3.fromRGB(255, 200, 80),

	-- Thrown kit projectiles (cactus seeds, cymbal monkey): they "land" when they slow down or touch ground.
	ProjectileMinFlight = 0.25, -- TUNE: seconds before a projectile can land
	ProjectileMaxFlight = 4, -- TUNE: lands wherever it is after this long
	ProjectileLandSpeed = 3, -- TUNE: slower than this = landed
	ProjectileGroundGap = 1, -- TUNE: this close to the ground = landed

	-- Explosions (ExplosionService)
	BlastFling = 70, -- TUNE: studs/s given to loose items at the center of a blast, fading to 0 at the edge
	CraterSeconds = 60, -- TUNE: how long the crater mark stays
	CraterSizeMult = 1, -- TUNE: crater diameter = blast radius * this

	-- Cactus fruit (§6.5)
	CactusFruitHeal = 15,
	CactusFruitDigestionBonus = 20,

	-- Tumbleweed (§6.4)
	TumbleweedBurnSeconds = 80,

	-- Sassparilla (§10.6)
	BottlesPerCrate = 6,
	-- TUNE: broken = floor(impactSpeed / BottleBreakSpeed). 40 lets a crate be dropped from the hands (~34 studs/s
	-- on landing) without breaking anything, while a full throw breaks one or two.
	BottleBreakSpeed = 40,

	-- Cursed trinket (§6.5)
	CursedTrinketKillSeconds = 7 * 60,
}
