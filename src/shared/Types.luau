--!strict
-- Shared type definitions. Config tables and systems import their shapes from here.

export type ItemCategory = "Objective" | "Utility" | "Kit" | "Fuel" | "Misc"

-- Bag slots; "X" = hands only; "Kit" = kit slot; 0 = instant use on pickup.
export type ItemSize = number | "X" | "Kit"

export type ItemDef = {
	id: string,
	displayName: string,
	category: ItemCategory,
	size: ItemSize,
	fuel: number?, -- nil = not fuel
	swallowable: boolean,
	behavior: string?, -- module name in shared/ItemBehaviors
	physics: ItemPhysics?, -- custom physical properties while loose (e.g. tumbleweeds roll far)
}

export type ItemPhysics = {
	density: number,
	friction: number,
	elasticity: number,
}

-- Passed to an ItemBehaviors module's server callbacks.
export type ItemUseContext = {
	player: Player?, -- nil when nobody caused it (e.g. a fuse running out on the ground)
	itemId: string,
	model: Model,
	position: Vector3, -- where the item is now (its holder's position if it is in a bag)
	addBagSlots: (amount: number) -> (),
	light: () -> (), -- start the behavior's fuse
	explode: (radius: number) -> (), -- blast at `position`
}

-- shared/ItemBehaviors/<name>.luau returns one of these. All callbacks run on the server.
export type ItemBehavior = {
	onInstantUse: ((context: ItemUseContext) -> ())?, -- size 0 items, on pickup
	onUse: ((context: ItemUseContext) -> ())?, -- the "use held item" key
	fuseSeconds: number?, -- items with a fuse can be lit, and are set off by nearby blasts
	onFuseEnd: ((context: ItemUseContext) -> ())?, -- the item is removed right after
	explodesWhenSwallowed: boolean?,
	blastIgnites: boolean?, -- a nearby blast lights it / shortens its fuse (dynamite)
	litEffect: ("Sparkles" | "Fire")?, -- what a lit item shows; Sparkles by default
}

-- State_Inventory payload.
export type InventoryState = {
	hand: string?, -- item id
	handModel: Model?,
	bag: { string }, -- item ids, in slot order
	kit: string?,
	kitUses: number?, -- uses left on the kit (nil = passive / unlimited)
	capacity: number, -- bag slots
	used: number,
}

export type KitDef = {
	id: string,
	displayName: string,
	refName: string?, -- wiki name, when displayName was changed
	uses: number?, -- nil = passive / unlimited
	guaranteed: number, -- minimum copies per match
	inChests: boolean?, -- false = never rolled for a chest (objective kits); default true
	params: { [string]: any },
}

export type DifficultyDef = {
	horseshoes: number,
	signalFires: number,
	cattlebugs: number,
	brokenTracks: number,
	sassparillaBottles: number,
	safeDigits: number,
	fuelPointsBase: number,
	fuelPointsPerPardner: number,
	wormlingLimit: number,
	wormlingSpawnSeconds: number,
	wormlingHatchMult: number,
}

export type AbilityDef = {
	id: string,
	displayName: string,
	kind: "Default" | "Choosable",
	action: string?, -- Config/Keybinds action that fires it (default abilities)
	cooldown: number,
	params: { [string]: any },
}

-- Passed to a worm ability's server half (server/Abilities/<id>.luau).
export type AbilityContext = {
	player: Player, -- the worm
	abilityId: string,
	position: Vector3, -- the worm's head
	mode: WormMode,
	head: BasePart,
	model: Model,
	direction: Vector3, -- unit; where the worm is aiming (camera look)
	params: { [string]: any }, -- Config.Abilities[id].params
	night: boolean,
	folder: Instance, -- parent for anything the ability spawns (cleared at match end)
	notify: (text: string) -> (),
}

-- server/Abilities/<id>.luau returns one of these.
export type AbilityModule = {
	canUse: ((context: AbilityContext) -> (boolean, string?))?, -- false + reason = refused, no cooldown
	activate: (context: AbilityContext, payload: { [string]: any }) -> boolean, -- true = start the cooldown
	cooldown: ((context: AbilityContext) -> number)?, -- override (Sonar Scream at night)
	cleanup: (() -> ())?, -- match over
}

-- shared/AbilityBehaviors/<id>.luau returns one of these (client effects, every client).
export type AbilityFx = {
	clientFx: (wormModel: Model, data: { [string]: any }) -> (),
}

export type StructureDef = {
	id: string,
	hp: number?, -- nil = indestructible
	scrap: number,
	wormDamageable: boolean,
}

export type ObjectiveDef = {
	id: string,
	displayName: string,
	always: boolean, -- always active, never rolled
	countsTowardTotal: boolean,
	enabledByDefault: boolean,
	params: { [string]: any }?, -- tuning for the objective's module
}

-- Passed to a kit module's onUse (server/Kits/<id>.luau).
export type KitContext = {
	player: Player,
	kitId: string,
	root: BasePart, -- the user's HumanoidRootPart
	direction: Vector3, -- unit; where they're aiming (camera look) or facing
	params: { [string]: any }, -- Config.Kits[kitId].params
	notify: (text: string) -> (),
}

-- server/Kits/<id>.luau returns one of these (§6.6). All optional.
export type KitModule = {
	onUse: ((context: KitContext) -> boolean)?, -- true = spend one use
	passiveSpeedMult: ((player: Player) -> number)?, -- while the kit is in the slot
	passiveStaminaUseMult: number?, -- while the kit is in the slot
	savesFromMouth: boolean?, -- spent automatically when a worm's mouth would kill the holder
}

-- State_Safe payload (§10.7). Shown to Pardners holding a Puzzle Map. active = false when no safe objective.
export type SafeState = {
	active: boolean,
	safePosition: Vector3?,
	signs: { Vector3 }, -- the code's signs, in code order
	recorded: { [string]: number }, -- code position ("1", "2", ...) -> digit; strings so it survives remotes
	opened: boolean,
}

-- Replicated as the "Mode" attribute on a worm model.
export type WormMode = "Underground" | "Surface" | "Airborne"

-- State_Minigame payload (§8.3).
export type MinigameState = {
	active: boolean,
	sequence: { string }, -- arrow names; the next one to press is sequence[progress + 1]
	progress: number,
	checkpoint: number,
	auto: boolean,
	autoEndsAt: number?, -- server time when auto-escape completes
}

-- Replicated as the "Phase" attribute on the Train model.
export type TrainPhase = "Fueling" | "Ready" | "Departing" | "Departed"

-- Per-match options (§5.1). Defaults come from Config; the host can change some in the lobby.
export type MatchSettings = {
	difficulty: string,
	sundownSeconds: number, -- 0 = no sundown
	objectiveCountMode: "Auto" | "Flat",
	objectiveCountFlat: number,
	enabledObjectives: { [string]: boolean },
	reviveLimit: number, -- -1 = unlimited
	enableBalloon: boolean,
	enableWormlings: boolean,
}

-- State_Match payload. Times are Workspace:GetServerTimeNow() values.
export type MatchState = {
	phase: MatchPhase,
	endsAt: number?, -- when the current phase's countdown runs out
	sundownAt: number?,
	night: boolean,
	difficulty: string,
	hostUserId: number,
	playerCount: number,
	readyCount: number,
	minPlayers: number,
	result: MatchResult?, -- only while Ending
}

-- One line of the objective checklist (State_Objectives payload is a list of these).
export type ObjectiveProgress = {
	id: string,
	displayName: string,
	current: number,
	target: number,
	done: boolean,
}

export type ObjectiveContext = {
	pardnerCount: number,
	difficulty: string,
	settings: MatchSettings,
}

-- server/Objectives/<id>.luau returns one of these (§10).
export type ObjectiveModule = {
	setup: (context: ObjectiveContext) -> (),
	getProgress: () -> (number, number), -- current, target
	cleanup: () -> (),
	step: ((dt: number) -> ())?, -- every Heartbeat while active
}

-- Part of State_Match while Ending. Names are display names.
export type MatchResult = {
	winner: "Pardners" | "Worm",
	escaped: { string },
	dead: { string },
}

export type MatchPhase = "Lobby" | "RoleAssign" | "WormLoadout" | "Playing" | "Ending"

export type Role = "Pardner" | "Worm"

return {}
