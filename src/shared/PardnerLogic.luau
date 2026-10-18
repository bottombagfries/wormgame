--!strict
-- Pure stamina/grip rules (§8.1). The server runs this as the authority; the owning client runs the
-- same code between State_Pardner updates so its bars and sprint cutoff don't lag.

local PardnerConfig = require(script.Parent.Config.Pardner)

export type Stats = {
	health: number,
	maxHealth: number,
	stamina: number,
	grip: number,
	sprinting: boolean,
	climbing: boolean,
	exhausted: boolean, -- hit 0 stamina; sprint locked until SprintMinStamina
	regenDelay: number, -- seconds until stamina regen resumes
	grabbed: boolean, -- in a worm's mouth: no sprinting or climbing
	adrenaline: number, -- seconds left of +speed and free stamina (after a mouth escape)
	speedMult: number, -- from status effects and kits (PardnerService works it out)
	staminaUseMult: number, -- likewise; scales sprint and jump costs
}

export type StepInput = {
	wantsSprint: boolean,
	wantsClimb: boolean,
	moving: boolean,
	grounded: boolean,
}

local PardnerLogic = {}

function PardnerLogic.new(): Stats
	return {
		health = PardnerConfig.MaxHealth,
		maxHealth = PardnerConfig.MaxHealth,
		stamina = PardnerConfig.MaxStamina,
		grip = PardnerConfig.MaxGrip,
		sprinting = false,
		climbing = false,
		exhausted = false,
		regenDelay = 0,
		grabbed = false,
		adrenaline = 0,
		speedMult = 1,
		staminaUseMult = 1,
	}
end

-- Humanoid.WalkSpeed for these stats.
function PardnerLogic.walkSpeed(stats: Stats): number
	local speed = if stats.sprinting then PardnerConfig.SprintSpeed else PardnerConfig.WalkSpeed
	if stats.adrenaline > 0 then
		speed *= PardnerConfig.Adrenaline.SpeedMult
	end
	return speed * stats.speedMult
end

-- Max stamina shrinks with health, down to MinStaminaFraction.
function PardnerLogic.maxStamina(stats: Stats): number
	local healthFraction = if stats.maxHealth > 0 then stats.health / stats.maxHealth else 0
	return PardnerConfig.MaxStamina * math.max(PardnerConfig.MinStaminaFraction, healthFraction)
end

function PardnerLogic.canClimb(stats: Stats): boolean
	return stats.grip > 0 or stats.stamina > 0
end

function PardnerLogic.step(stats: Stats, input: StepInput, dt: number)
	local usingStamina = false
	local free = stats.adrenaline > 0 -- adrenaline: nothing costs stamina
	stats.adrenaline = math.max(0, stats.adrenaline - dt)

	-- Climbing drains grip first, then stamina; with both empty the Pardner falls.
	stats.climbing = input.wantsClimb and not stats.grabbed and PardnerLogic.canClimb(stats)
	if stats.climbing then
		if stats.grip > 0 then
			stats.grip = math.max(0, stats.grip - PardnerConfig.ClimbGripPerSecond * dt)
		else
			stats.stamina = math.max(0, stats.stamina - PardnerConfig.ClimbStaminaPerSecond * dt)
			usingStamina = true
		end
		if not PardnerLogic.canClimb(stats) then
			stats.climbing = false
		end
	elseif input.grounded then
		stats.grip = math.min(PardnerConfig.MaxGrip, stats.grip + PardnerConfig.GripRegenPerSecond * dt)
	end

	if stats.stamina <= 0 then
		stats.exhausted = true
	elseif stats.exhausted and stats.stamina >= PardnerConfig.SprintMinStamina then
		stats.exhausted = false
	end

	stats.sprinting = input.wantsSprint
		and input.moving
		and not stats.grabbed
		and not stats.climbing
		and (free or not stats.exhausted)
	if stats.sprinting and not free then
		stats.stamina -= PardnerConfig.SprintStaminaPerSecond * stats.staminaUseMult * dt
		usingStamina = true
	end

	if usingStamina then
		stats.regenDelay = PardnerConfig.StaminaRegenDelay
	elseif stats.regenDelay > 0 then
		stats.regenDelay -= dt
	else
		stats.stamina += PardnerConfig.StaminaRegenPerSecond * dt
	end
	stats.stamina = math.clamp(stats.stamina, 0, PardnerLogic.maxStamina(stats))
end

-- Jumping costs stamina but is still allowed at 0.
function PardnerLogic.applyJump(stats: Stats)
	if stats.adrenaline > 0 then
		return
	end
	stats.stamina = math.max(0, stats.stamina - PardnerConfig.JumpStaminaCost * stats.staminaUseMult)
	stats.regenDelay = PardnerConfig.StaminaRegenDelay
end

function PardnerLogic.applyClimbJump(stats: Stats)
	stats.grip = math.max(0, stats.grip - PardnerConfig.MaxGrip * PardnerConfig.ClimbJumpGripFraction)
end

return PardnerLogic
