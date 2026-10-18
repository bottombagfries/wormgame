# CLAUDE.md — Wormtown-style Asymmetric Roblox Game (Rojo + Luau)

> Read this whole file before writing code. It is the single source of truth.
> Build in the numbered **Phases** at the bottom, one at a time. Stop at every
> ✅ CHECKPOINT and tell the user exactly what to test in Studio before continuing.

---

## 0. What we're building (one paragraph)

An asymmetric multiplayer survival game. **Pardners** (2–9+ players) run around a desert
town on foot, scavenging items and completing **objectives** so they can start the **Train**
in the middle of the map and escape. One (or more) **Worm** player swims underneath the sand,
senses Pardners only when they **move on sand**, pounces out to swallow them, and uses
abilities to hunt. A **Sundown** timer makes the Worm stronger if the Pardners take too long.
Dead Pardners become **ghosts** and can be revived by bringing their **heart jar** to the Church.

Reference data comes from the Last Train Outta' Wormtown fandom wiki. Numbers marked
`-- TUNE` are either not on the wiki or are guesses — keep them in Config so they're easy to change.

---

## 1. Hard rules (never break these)

1. **Server-authoritative.** Server owns all game state: inventory, health, stamina, objectives,
   item spawning, damage. Clients send *intents* ("I want to pick up item X"), server validates
   (distance, cooldown, state) and applies. Never trust a client number.
2. **All tunable values live in `src/shared/Config/`.** No magic numbers in systems. If you need a
   number, add it to the relevant Config table first.
3. **Every model is swappable.** Code NEVER references a mesh/model by asset ID. It asks
   `AssetService.get(assetId)` (see §3). If the user hasn't dropped a real model in yet, a
   greybox is generated from Config. Tag every greybox spot in code with `-- TODO(asset): <Name>`.
4. **Data-driven items/abilities/objectives.** Adding a new item = adding one entry to
   `Config/Items.luau` (+ optional behavior module). No giant if/else chains on item names.
5. **Strict Luau.** `--!strict` at the top of every file. Type your module exports.
6. **One module = one job.** Services on server, Controllers on client, pure logic in `shared/`.
7. **No `wait()`, `spawn()`, `delay()`.** Use `task.wait`, `task.spawn`, `task.delay`.
8. **Clean up connections.** Every system that connects to events per-player/per-match must
   disconnect them on match end (use a simple `Janitor`/`Trove` in `shared/Util`).
9. Don't use the original game's name, logo, or art anywhere player-facing. Use the display
   names in Config (some are already renamed — see §6).

---

## 2. Toolchain & project layout

**Tools** (install with Rokit): `rojo`, `luau-lsp` (Zed Luau extension), `selene`, `stylua`, `wally` (optional).

```
rokit.toml
default.project.json
selene.toml
stylua.toml
CLAUDE.md
src/
  server/                      -> ServerScriptService.Server
    init.server.luau           (bootstraps all Services in order)
    Services/
      MatchService.luau        (lobby -> roles -> match -> end, sundown timer)
      MapService.luau          (spawns map layout from markers, structures, loot)
      ItemService.luau         (spawn/pickup/drop/throw/bag/kit slot)
      PardnerService.luau      (health, stamina, grip, status effects, death, ghost)
      WormService.luau         (worm character, movement validation, health rings, grab)
      AbilityService.luau      (worm abilities, cooldowns, sundown multiplier)
      DetectionService.luau    (who is "visible" to worms; ground pings)
      ObjectiveService.luau    (picks objectives, tracks progress)
      TrainService.luau        (furnace, lever, depart timer, horn)
      ReviveService.luau       (heart jars, church zone, necronomicon)
      StructureService.luau    (HP, destruction, scrap drops)
      ExplosionService.luau    (dynamite, bile bomb, craters)
      DigService.luau          (dig spots, buried key/horseshoes/items, metal detector)
      NPCService.luau          (cattlebugs, balloon pilot airdrops)
  client/                      -> StarterPlayer.StarterPlayerScripts.Client
    init.client.luau
    Controllers/
      InputController.luau     (keybinds, mobile later)
      CameraController.luau    (pardner third-person + aim; worm underground cam)
      PardnerMovementController.luau (sprint, climb, stamina prediction)
      WormController.luau      (worm steering, burrow/unburrow, pounce aim)
      InventoryController.luau (bag UI, kit slot, hold/throw)
      HUDController.luau       (health/stamina/grip, objectives list, sundown clock)
      WormVisionController.luau (hides pardners/items unless server says visible, pings)
      MinigameController.luau  (mouth escape arrows)
      GhostController.luau     (fly, push items)
      UI/                      (one file per screen)
  shared/                      -> ReplicatedStorage.Shared
    Config/
      Game.luau  Difficulty.luau  Items.luau  Kits.luau  Objectives.luau
      Pardner.luau  Worm.luau  Abilities.luau  Structures.luau  Loot.luau  Assets.luau
    Net.luau                   (declares every RemoteEvent/RemoteFunction by name)
    Types.luau
    Util/ (Janitor.luau, Signal.luau, Random.luau, Geometry.luau, Tags.luau)
    ItemBehaviors/             (one module per item with special behavior)
    AbilityBehaviors/          (one module per worm ability; server + client halves)
```

**default.project.json** — IMPORTANT: asset folders use `$ignoreUnknownInstances: true` so the
user can drag models into them in Studio and Rojo won't delete them on sync.

```json
{
  "name": "Wormtown",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" },
      "Assets": {
        "$className": "Folder",
        "$ignoreUnknownInstances": true,
        "Items": { "$className": "Folder", "$ignoreUnknownInstances": true },
        "Structures": { "$className": "Folder", "$ignoreUnknownInstances": true },
        "Characters": { "$className": "Folder", "$ignoreUnknownInstances": true },
        "Effects": { "$className": "Folder", "$ignoreUnknownInstances": true }
      }
    },
    "ServerScriptService": { "Server": { "$path": "src/server" } },
    "StarterPlayer": {
      "StarterPlayerScripts": { "Client": { "$path": "src/client" } }
    },
    "Workspace": {
      "$ignoreUnknownInstances": true,
      "MapTemplate": { "$className": "Folder", "$ignoreUnknownInstances": true }
    }
  }
}
```

---

## 3. The swappable-asset system (most important convenience feature)

`shared/Config/Assets.luau` lists every visual thing with a greybox fallback:

```lua
--!strict
export type AssetDef = {
  folder: "Items" | "Structures" | "Characters" | "Effects",
  size: Vector3,          -- greybox size in studs
  color: Color3,
  shape: Enum.PartType?,  -- Block default
  material: Enum.Material?,
}
return {
  SmallCoal = { folder = "Items", size = Vector3.new(1,1,1), color = Color3.fromRGB(30,30,30) },
  -- ...one entry per item/structure/character (see tables in §6–§8)
} :: { [string]: AssetDef }
```

`AssetService.get(assetId: string): Model` (shared, usable on both sides):
1. Look for `ReplicatedStorage.Assets[folder][assetId]`. If it exists, `:Clone()` it.
2. Otherwise build a greybox `Model` containing one `Part` from the AssetDef, with a
   `BillboardGui` label showing the asset id (so it's obvious what still needs art).
3. Ensure the result has a `PrimaryPart`; if a user model has none, pick its largest BasePart.
4. Set attribute `AssetId = assetId` on the model.

**User instructions (put these in README.md too):** To replace a model, make a Model in Studio
named exactly the asset id (e.g. `SmallCoal`), set its PrimaryPart, and drop it in
`ReplicatedStorage/Assets/Items`. Collision/physics settings are applied by code, not the model.
Keep roughly the same size as the greybox or update `size` in Assets.luau.

---

## 4. Map layout via markers (no procedural terrain required)

The user builds (or greyboxes) the map by hand inside `Workspace/MapTemplate`. Code reads
**marker parts** (invisible, anchored, CanCollide off) identified by CollectionService tags.
`MapService` picks random markers each match so layouts vary.

| Tag | Count on map | Used for |
|---|---|---|
| `Sand` | any | Parts/terrain regions that count as "sand" (detection + burrowing). Terrain material `Sand` also counts. |
| `TrainSpot` | 1 | Center of map. Train + Watertower spawn here. |
| `RanchSpot` | 4–8 | Ranch = 1 large house + 1 shelter. Pardners spawn at random ranches. Safe spawns in a ranch house. |
| `TownHouseSpot` | 10–20 | Town houses (random variant/tier/color). |
| `TownWell` | 1 | Town well interactable. |
| `ChurchSpot` | 1–3 | One chosen per match. |
| `QuarrySpot` | 1 | Dynamite minecarts. |
| `LookoutSpot` | 6+ | 3 chosen, spread apart (pick farthest-point sampling). |
| `TraincarSpot` | 10+ | 6 chosen when Repair Tracks is active. |
| `BrokenTrackSpot` | 8+ | Along the track; N chosen by difficulty. |
| `StagecoachSpot` | 4+ | 2 chosen when Deliver Sassparilla is active. |
| `SignalFireSpot` | 8+ | N chosen by difficulty. |
| `DigArea` | 1+ | Big box volumes; buried key/horseshoes/items spawn at random points inside. |
| `LooseItemArea` | 1+ | Volumes for random sand loot (tumbleweeds, backpacks, crates, chests). |
| `CactusSpot` | many | Tall cacti; some get a Cactus Fruit on top. |

If a required tag has zero markers, `MapService` must `warn()` clearly and spawn a greybox at a
fallback position instead of erroring. Provide a `GreyboxMap` builder that creates a flat 1024×1024
sand baseplate with auto-placed markers so the game is playable with **zero** user building.

---

## 5. Core rules & numbers

### 5.1 Match flow
`Lobby -> RoleAssign -> WormLoadout (pick 2 abilities, 20s) -> Playing -> Ending -> Lobby`

- Default 1 Worm; `Config.Game.WormCount` setting. Rest are Pardners.
- Match settings object (host-editable later, defaults from Config): difficulty, sundown time,
  objective count mode (auto/flat), enabled objectives, revive limit, escape balloon on/off,
  wormlings on/off.
- **Pardners win** if at least one escapes on the Train (or balloon). **Worm wins** if all Pardners are dead
  when the match ends (no living Pardners and no revivable heart jars, or train left with nobody).

### 5.2 Difficulty table (`Config/Difficulty.luau`)

| Key | Easy | Normal | Hard | Wormfood |
|---|---|---|---|---|
| horseshoes (fake key signals) | 0 | 2 | 4 | 7 |
| signalFires | 1 | 3 | 5 | 8 |
| cattlebugs | 1 | 3 | 5 | 8 |
| brokenTracks | 1 | 3 | 5 | 8 |
| sassparillaBottles | 12 | 18 | 30 | 48 |
| safeDigits | 2 | 3 | 5 | 8 |
| fuelPointsBase `-- TUNE` | 30 | 45 | 60 | 80 |
| fuelPointsPerPardner `-- TUNE` | 3 | 5 | 7 | 9 |
| wormlingLimit | 3 | 6 | 8 | 12 |
| wormlingSpawnSeconds | 90 | 60 | 40 | 20 |
| wormlingHatchMult | 0.75 | 1 | 1.25 | 2 |

Fuel meter shows 0–100 to players; internally `required = base + perPardner * pardnerCount`,
and meter = `delivered / required * 100`.

### 5.3 Objective count (auto mode)
| Pardners | 1–2 | 3 | 4–5 | 6 | 7 | 8 | 9+ |
|---|---|---|---|---|---|---|---|
| Objectives | 1 | 2 | 3 | 4 | 5 | 6 | 7 |

"Fuel the Train" is always active (counts toward the total). The rest are chosen randomly from enabled
objectives. "Escape Balloon" is always on (if enabled) and does NOT count. Items/NPCs for inactive
objectives do not spawn (no shovels' metal detector, cattlebugs, scrap, stagecoaches, puzzle maps, etc.).

### 5.4 Sundown
- Default 15 min after start (range 5–40, or disabled).
- At 66% of the way to sundown: balloon pilot airdrops **5 chests** at random sand spots.
- After sundown: lighting goes night; all worm ability cooldowns × `Config.Worm.NightCooldownMult` (0.67 `-- TUNE`);
  Sonar Scream range becomes infinite; worm rings 2 and 3 heal much faster; **no Church revives**
  (Necronomicon still works); any Pardner whose health is below what a revive would give them is topped up to that.

---

## 6. Items

### 6.1 Item model
```lua
export type ItemDef = {
  id: string, displayName: string,
  category: "Objective" | "Utility" | "Kit" | "Fuel" | "Misc",
  size: number | "X" | "Kit" | 0,  -- bag slots; X = hands only; Kit = kit slot; 0 = instant use on pickup
  fuel: number?,                   -- nil = not fuel
  swallowable: boolean,            -- default true unless size X and big
  behavior: string?,               -- module name in shared/ItemBehaviors
}
```

### 6.2 Holding rules
- Bag capacity **3** slots, **+2 per Backpack** (backpacks stack, can't be dropped, kept through death).
- Size 1/2/3 items can go in bag if space. Size X items can only be **held in hands** (one at a time).
- Kit items go in the separate **kit slot** (1 kit at a time; picking up another swaps and drops old).
- Size 0 items apply instantly on pickup.
- Pardner can hold one item "out" in hands; can **throw** it (aim mode gives a trajectory arc).
- Trying to climb while holding an item drops it.
- Any item on the ground: can be stood on (Pardner on top of item = not on sand = invisible to worm),
  thrown as a distraction (moving items on sand create pings), and most can be swallowed by the worm.
- Show `name / size / fuel` in a small label above the Pardner's head when they hover an item.

### 6.3 Fuel items (fuel value / bag size)
| id | fuel | size |
|---|---|---|
| MassiveCoal | 12 | 3 |
| BigCoal | 7 | 2 |
| SmallCoal | 3 | 1 |
| Gramophone | 7 | 3 |
| Pew | 6 | X |
| Bench | 5 | 3 |
| DutchOven | 5 | 3 |
| Pulpit | 5 | X |
| Table | 5 | X |
| Barrel | 4 | X |
| Chair | 4 | 2 |
| Bed | 3 | X |
| GrainSack | 3 | X |
| Bucket | 2 | 1 |
| CoffeePot | 2 | 1 |
| Lantern | 2 | 1 |
| Skillet | 2 | 1 |
| Stool | 2 | 1 |
| Painting | 2 | 2 |
| CactusFruit | 1 | 1 |
| Horseshoe | 1 | 1 |
| RustyTinCan | 1 | 1 |

Fueling = throw/drop the item into the furnace trigger on the Train. Item is destroyed, fuel added.

### 6.4 Objective items
| id | size | notes |
|---|---|---|
| TrainKey | X | Buried with a skeleton. Insert into Train. |
| Shovel | Kit | 8 in the caboose at start. Digs. Has metal detector when key objective active. |
| Dynamite | 2 | See §6.7. |
| Scrap | 3 | Dropped by destroyed structures. 2 per broken track. |
| Tumbleweed | 1 | Light at furnace, burns 80s, carry to signal fire. Rolls far (low friction, round). Respawns when burnt out. |
| DandylionBundle | Kit | Infinite throws; max 4 active flowers per Pardner (5th deletes oldest). Attracts cattlebugs. |
| SassparillaCrate | X | 6 bottles. Dropping breaks bottles based on impact speed. |
| PuzzleMap | 1 | Shows digit + safe locations. Written digits sync to all maps. |
| TrainManual | 0 | In the safe; picking it up completes the safe objective. |

### 6.5 Utility / misc items
| id | size | notes |
|---|---|---|
| Backpack | 0 | +2 bag slots permanently. |
| CactusFruit | 1 | Eat: +15 HP and +20s heart-jar digestion time (resets after being eaten). Also 1 fuel. |
| HeartJar | 2 | Dropped on death. See §9. |
| Ladder | X | Place anywhere, stands upright, climbing it costs no grip/stamina. |
| Crate | X | Just a platform/distraction. 3 always on the Train. |
| CursedTrinket (wiki: "Watch Me") | X | Easter egg: kills holder 7 min after pickup. 1/200 from the well. |

### 6.6 Kit items (`Config/Kits.luau`)
Rename the ones marked ⚠ to avoid trademark issues; the wiki name is kept as `refName`.

| id | displayName | effect |
|---|---|---|
| BullwormRifle | Bullworm Rifle | 1 shot. Hit worm: −40% worm HP, releases grabbed Pardner, forces burrow. Kills wormlings. Instantly detonates dynamite. Recoil pushes shooter back. **≥1 guaranteed per match.** |
| CactusSeedPouch | Cactus Seed Pouch | 7 throws; each plants a large cactus where it lands (small cactus if near Train). |
| Canteen | Canteen | Passive: −35% stamina use from jump & sprint. |
| CoffeeTin | Coffee Tin | 3 uses: +45% speed, −80% stamina use for 15s; reveals user to worms for 20s. |
| CymbalMonkey | Cymbal Monkey | Throw: disorients worms/wormlings in radius for 12s (can't see Pardners, props, or pings). |
| DandylionBundle | Dandylion Bundle | see §6.4 |
| SpiritBoard ⚠ (ref: Luigi Board) | Spirit Board | Passive: see & hear ghosts; +speed per ghost up to +30%; ghost push cooldown 25s → 12.5s. **≥1 guaranteed.** |
| MysteriousConcoction | Mysterious Concoction | 3 uses, random effect (weights below). |
| DeadBook ⚠ (ref: Necronomicon) | Book of the Dead | Use while holding a heart jar: revive that Pardner at your position; costs user 35 HP over 1s (can kill user). **≥1 guaranteed.** |
| PogoStick | Pogo Stick | 5 uses: big vertical launch. |
| QuickEscapeKnife | Quick Escape Knife | 1 use: instantly escape worm mouth. Auto-triggers if HP would hit 0 while grabbed. |
| Shovel | Shovel | see §10 |
| Slingshot | Slingshot | Passive: +50% throw power. |
| SnakeOil | Snake Oil | 2 uses, max 1 buff per Pardner: permanent +10% speed and +1–10 HP each mouth escape. Persists through death. |
| ZiplineCrossbow | Zipline Crossbow | Fires a harpoon, creates a zipline from the user to the hit point. Pardners ride it. **≥3 guaranteed.** |

Mysterious Concoction weights: +10HP 10.27, +25HP 20.54, +50HP 7.99, −25HP 22.83, −50HP 9.13,
+100HP 1.82, die 4.56, explode (dynamite blast) 2.28, revealed to worms 20s 11.41, teleport random 9.13.

**Chests:** always contain exactly 1 random kit (respecting guarantees). Randomly spawned chests and
airdrop chests may also contain Dynamite, CactusFruit, or any Coal. Guarantee logic: build the full
list of chests at match start, assign guaranteed kits first, fill rest randomly.

### 6.7 Dynamite
- Found in Quarry minecarts: a few at start, +1 every 90s forever. Rarely in chests.
- Light while held → fuse `Config.Items.DynamiteFuse` (4s `-- TUNE`). Hit by another blast → fuse halved.
  Shot by rifle → instant. Swallowed by worm → explodes instantly (lit or not).
- Blast (radius `-- TUNE` 18 studs): kills Pardners instantly, big worm damage (50% `-- TUNE`) + forced burrow,
  kills wormlings, destroys structures (drops scrap), rocks, cacti, sandtraps; unearths dig spots; leaves crater decal.

---

## 7. Locations & structures (`Config/Structures.luau`)

| Structure | Scrap on destroy | Notes |
|---|---|---|
| House (5 variants × 3 tiers × 5 colors × 2 trims) | 1 | Contains loot (§7.1). Maybe a ladder on the side. |
| Shelter | 0 | Ranch only. Easily destroyed. Just a platform. |
| LookoutTower | 1 | 3 per match, spread out. 1 ladder, 2 chests on top. |
| Church | 2 | Revive zone (yellow ring). 1 pulpit, 4–6 pews, ladder at back. |
| Watertower | 1 | Next to Train, 1 ladder, landmark. |
| Traincar | 3 | 6 per match (Repair Tracks only). Half buried. **Worm can't damage** — dynamite only. |
| Train | — | Indestructible. |

Structure HP `-- TUNE`: House 3, Shelter 1, LookoutTower 3, Church 4, Watertower 4. Worm pounce = 1 dmg,
bodyslam = 1 dmg, armored carapace pounce = instant destroy, dynamite = instant destroy.
When a structure collapses: Pardners inside/on it die instantly, loot inside becomes loose physics items.

**Town Well:** use → gives RustyTinCan. Gains a token every 35s (max 2). With a token, gives a random
one of Bucket/Chair/CoffeePot/Lantern/Skillet/Stool. 1/200 chance of CursedTrinket. (Anti-softlock fuel source.)

**Train caboose contents at start:** 8 shovels, 3 crates on the Train, up to 4 ladders on the caboose side,
puzzle maps (if safe objective), dandylion bundles behind the caboose (if cattlebug objective).
A **vending machine** at the Train dispenses 1 puzzle map / dandylion bundle every 2 min (if active).

### 7.1 House loot (`Config/Loot.luau`) — tier chosen randomly
- **Tall** T1: SmallCoal, Bed, RustyTinCan×4, Stool · T2: SmallCoal, Bed, Gramophone, Table, Stool, Bucket, Bench · T3: Stool×2, SmallCoal, Painting, RustyTinCan×4, Bucket, Barrel, Lantern, Bench, CoffeePot, Table, Bed
- **Small** T1: SmallCoal, GrainSack, Bench, Bucket, Barrel, Bed · T2: SmallCoal, Painting, RustyTinCan×4, DutchOven, Skillet, GrainSack, Bucket, Stool, Bed · T3: Lantern, Bench, Painting×2, Gramophone, Bed, Table, Chair, SmallCoal×3
- **Medium** T1: SmallCoal, GrainSack, Barrel, Lantern, RustyTinCan×3, Bucket, Stool, Bed · T2: SmallCoal, Bench, Chair×2, RustyTinCan×2, Table, Painting, Bed · T3: SmallCoal, Bucket, DutchOven, Bench×2, RustyTinCan×3, Chair, Table, Lantern, GrainSack, Stool, Bed, Painting
- **Large** T1: Bed, SmallCoal, Painting, RustyTinCan, Bucket, Chair, Table · T2: RustyTinCan×4, GrainSack×2, CoffeePot, Skillet, Bench, Table, SmallCoal, Chair, Bed · T3: Barrel, GrainSack, RustyTinCan×5, Chair×2, Table, DutchOven, Stool, SmallCoal, Bed, Painting, Bucket
- **TwoStory** T1: SmallCoal, Gramophone, Table×3, Painting×3, Chair×3, Bucket, Stool, Bed, DutchOven · T2/T3: `-- TUNE` (copy T1 with small variations)

Loot spawns at `LootPoint` attachments inside the house model if present; otherwise random points inside its bounding box floor.

**Loose sand loot:** tumbleweeds, backpacks, crates, random chests (`-- TUNE` counts in Config.Loot.Loose).

---

## 8. Characters

### 8.1 Pardner (`Config/Pardner.luau`)
- Standard R15 Humanoid character, third-person, over-the-shoulder **aim mode** (RMB) for throwing/kits.
  Aim mode also shows teammate health, cardinal directions, and heart jar markers.
- **Health** 100. **Stamina** 100 max; max stamina scales with health: `max = 100 * max(0.4, hp/maxHp)`.
  Sprint & jump drain stamina (can still jump at 0). Regen when not using. `-- TUNE` rates.
- **Grip** 100: drains only while climbing; when empty, climbing drains stamina; both empty = fall.
  Jumping while climbing costs 8% grip. Climb any wall via raycast (can't climb while holding item).
- **Detection:** A Pardner is visible to the worm ONLY when standing on sand AND moving
  (horizontal speed > `Config.Pardner.PingSpeed` 1 stud/s `-- TUNE`). Standing still or standing on any
  prop/structure/item = invisible.
- **Adrenaline** after escaping a worm mouth: +50% speed and no stamina drain for 10s.
- Revive: max HP −25% of the base each revive, min 10. Revive limit setting (default unlimited); once hit, the
  jar becomes an **Ossified Heart** (only DeadBook can revive).
- Status effects system: `StatusService`-style table on PardnerService (`{id, expires, mods}`) with particles.

### 8.2 Worm (`Config/Worm.luau`)
- Custom character: 8 segments, shrinking toward the tail. Head is the physics root; segments follow with a
  chain-follow on each **client** (visual only, not replicated per-segment).
- Movement: underground (below sand surface, fast `-- TUNE`), surface/airborne (launched arcs).
  **Implementation:** worm client gets network ownership of an unanchored head part driven by
  `LinearVelocity`/`AlignOrientation`. Server validates speed/position each heartbeat and snaps back if exceeded.
  Worm can only burrow while on sand (or anywhere when force-burrowed by damage).
- **Health** 100. Loses HP only from: a Pardner escaping its mouth (`-- TUNE` 15%), rifle (40%), dynamite (50% `-- TUNE`).
  Any HP loss **forces burrow** and blocks unburrowing until healed to full `-- TUNE` (or a threshold).
- **Healing rings:** 3 rings centered on where damage was taken (radii `-- TUNE` 60/140/260). Heal rate
  slow/medium/fast by ring; rings 2–3 much faster after sundown.
- **Vision:** underground sees red **pings** globally for moving Pardners on sand; above ground sees nearby
  red dots only; sees nothing while airborne. Always sees very large objects and items very close to it, and
  items a Pardner is holding up that touch sand.
- **Grab:** pounce hitbox touches Pardner → Pardner goes into mouth, takes flat 5 HP (unless ≤10), then drains
  HP over time `-- TUNE`. Items that enter the mouth are swallowed after ~1.5s (dynamite explodes).
- Worms can see other worms underground.

### 8.3 Mouth-escape minigame (MinigameController)
Grabbed Pardner sees a sequence of color-coded arrow prompts; correct input fills a bar, wrong input loses
progress, with checkpoints (bar can't fall below last checkpoint). Full bar = escape (worm loses HP, Pardner
gets Adrenaline). Pressing the drop key toggles **auto-escape**, which completes in 5.5s. Server validates
timing (min time between correct inputs) so it can't be macro-spammed.

### 8.4 Ghost (dead Pardner)
Free-fly camera/character, invisible to everyone except ghosts and Spirit Board holders. Can **push** an item:
hold interact to charge (max force 24), arrow shows direction; cooldown 25s (12.5s if any Pardner has Spirit Board).
Multiple ghosts pushing the same item stack force.

---

## 9. Death & revive
- Eaten: after **digestion** (60s + 20s per cactus fruit eaten since last being eaten), a HeartJar drops where the worm is.
- Any other death (dynamite, collapse, bile bomb, magma, concoction): HeartJar drops immediately at the body.
- Revive: drop jar inside Church ring (not after sundown, not if ossified) or DeadBook. Revived Pardner spawns
  at the Church (or DeadBook user) with reduced max HP (§8.1). Reviving resets the train depart timer and recalls
  the balloon (§11).

---

## 10. Objectives (`Config/Objectives.luau`) — each is a module with `setup(match)`, `getProgress()`, `cleanup()`

1. **FuelTrain** (always): throw fuel items into the furnace until meter = 100.
2. **FindTrainKey:** key + skeleton buried at a random DigArea point; `horseshoes` decoys buried too.
   Shovel has a metal detector: bulb lights + shows % closeness (`100 - dist/maxDist*100`, nearest of key/horseshoes)
   while key is still buried. Dig with shovel (hold interact on sand, ~2s `-- TUNE`), dynamite, or worm bodyslam.
   Insert key into the Train keyhole.
3. **LightSignalFires:** light a tumbleweed at the furnace (it burns 80s), carry to an unlit signal fire before it burns out.
4. **HerdCattlebugs:** NPC bugs wander; they walk to and eat the nearest dandylion within range `-- TUNE` 40.
   Count delivered when a bug enters the zone behind the caboose (then it stays/despawns).
5. **RepairTracks:** bring 2 Scrap to each broken track spot.
6. **DeliverSassparilla:** 2 stagecoaches, 2 crates each. Deliver crates to the caboose; count bottles.
   Drop/impact breaks bottles: `broken = floor(impactSpeed / Config.BottleBreakSpeed)` `-- TUNE`. New crate spawns
   when one is delivered or fully broken.
7. **OpenSafe:** safe in a random ranch house. 12 digit markers placed around the map, but the code only uses
   `safeDigits` of them (puzzle map highlights which). Pardner holding map interacts with a digit to record it
   (shared across all maps). Enter the code at the safe keypad UI → TrainManual appears → pick up.
8. **EscapeBalloon** (config flag `EnableBalloon`; the user may later replace this with an original mechanic):
   see §11.

---

## 11. Train & escape (TrainService)
- When all active objectives are done, the **lever** becomes usable. Pull → 2:00 depart timer (resets whenever
  a Pardner is revived). If **all living Pardners** stand on the Train for 5 continuous seconds, depart early.
  On depart: Pardners on the Train escape; everyone else is dead.
- **Horn:** disorients all worms/wormlings in a wide radius for 10s (same effect as cymbal monkey).
  3 min cooldown; lever is locked 12s after a horn blast; horn disabled after the lever is pulled.
- **Balloon pilot** (NPC, only if `EnableBalloon`): when exactly 1 Pardner is alive, a balloon flies to a random
  spot and drops a ladder. Climbing it = escape. If someone is revived, the ladder lifts and the balloon returns
  to center until there's 1 Pardner again. The same NPC does the 5-chest airdrop at 66% sundown.

---

## 12. Worm abilities (`Config/Abilities.luau` + `shared/AbilityBehaviors/*`)

Each ability module exports: `id, cooldown, canUse(worm): boolean, serverActivate(worm, payload), clientFx(worm, payload)`.
AbilityService handles cooldowns (× night multiplier), validation, and replication.

**Default (all worms):**
| id | cd | effect |
|---|---|---|
| Pounce | 3s `-- TUNE` | Launch forward; grabs Pardner/item in path; damages structures (not traincars). Much farther when done while unburrowing. |
| Sneak | hold | No rumble/noise while moving; mid-air slows momentum. |
| Burrow/Unburrow | — | Toggle. Burrow only on sand unless forced. |
| SonarScream | 60s | Reveal Pardners, props, cattlebugs, ziplines, balloon within radius `-- TUNE` 120 for 6s. After sundown: whole map, shorter cd. |
| Sinkhole | 70s | Vortex zone; Pardners inside slowed 80%. |

**Choose 2 before the match:**
| id | cd | effect |
|---|---|---|
| Sandstorm | 90s | Moving tornado 16s; flings props/Pardners randomly; reveals caught Pardners. |
| ArmoredCarapace | 60s | 16s shell: immune to damage (ends on first nullified hit), one-hit structures (ends after one). Surfacing makes a sand blast: hit Pardners −30 stamina, +30% stamina use, +30% damage taken for 15s. |
| Stealth | 90s | 20s or until pounce: no sounds, tremors, or breach particles. |
| Bodyslam | 60s | Mid-air only. Crater, 30-stud-wide impact: 10 dmg to Pardners, 1 to structures, knockback; unearths dig spots. |
| TarWall | 65s | Not mid-air. Ring of tar spires for 18s; Pardners can't pass/climb, tar slows; worms pass freely. |
| Sandtrap | 45s | Above ground on sand. Trap zone; Pardner who lands in it is pulled down, revealed, and must do the mouth minigame. Dynamite destroys it. |
| BileBomb | 25s | Above ground. Sticky projectile, explodes after 3.5s, 20 dmg. |
| MagmaTrail | 120s | Underground. For 10s leaves magma patches (each lasts 12s): 5 dmg/s, lingers 1.5s after leaving. |

---

## 13. Networking (`shared/Net.luau`)
Declare every remote in one place; server creates them in `ReplicatedStorage.Remotes`, client waits for them.
Naming: `Verb_Noun`. Examples:
`Request_Pickup(itemInstance)`, `Request_Drop()`, `Request_Throw(dir: Vector3, power: number)`,
`Request_StoreInBag()`, `Request_TakeFromBag(slot)`, `Request_UseKit(payload)`, `Request_Interact(target)`,
`Request_Ability(abilityId, payload)`, `Request_Climb(state)`, `Request_MinigameInput(arrow)`,
`State_Pardner(stats)`, `State_Objectives(list)`, `State_Match(phase, sundownT)`,
`Worm_Pings(list)` (sent ONLY to worm clients), `Worm_Visible(set)`, `Fx_Play(effectId, cframe)`.
Rate-limit every `Request_*` per player (simple token bucket in `Util/RateLimit.luau`).

Worm-vision: pardner characters replicate normally (Roblox limitation). `WormVisionController` on the worm
client sets `LocalTransparencyModifier = 1` on Pardners/items not in the server's visible set. Note this is
client-side hiding (exploitable); acceptable for v1.

---

## 14. UI (minimal, functional, replace art later)
- Pardner HUD: health/stamina/grip bars, bag slots (3–5+), kit slot, held-item label, objective checklist,
  sundown sun/moon dial, interaction prompts (use ProximityPrompt where simple).
- Worm HUD: ability bar with cooldowns (5 default + 2 chosen), health + current ring indicator, ping overlay.
- Lobby: role display, worm ability picker, match settings panel (host), ready button.
- End screen: who escaped, who died, winner.

---

## 15. Build Phases (do them in order; stop at each checkpoint)

**Phase 1 — Skeleton.** Rojo project, folders, `init` bootstraps, Net module, Config stubs, AssetService with
greybox fallback, GreyboxMap builder.
✅ CHECKPOINT: `rojo serve` → Studio connects → Play → flat sand map, greybox labeled cubes for a few test items, no errors in output.

**Phase 2 — Pardner basics.** Movement, sprint, stamina, health, climbing with grip, aim mode camera, HUD bars.
✅ CHECKPOINT: run/sprint/jump/climb a wall; bars drain and refill correctly; can't climb with both bars empty.

**Phase 3 — Items & inventory.** ItemService pickup/drop/hold/throw, bag + backpack, kit slot, hover label, stand-on-items.
✅ CHECKPOINT: pick up SmallCoal to bag, hold a Barrel (X), throw it with aim arc, backpack gives 5 slots.

**Phase 4 — Train & fuel.** Train at TrainSpot, furnace fueling, fuel meter, lever, depart timer, early depart, horn stub.
✅ CHECKPOINT: solo test — fill fuel to 100, pull lever, stand on train 5s → "escaped" end screen.

**Phase 5 — Match flow.** Lobby → roles → worm loadout → playing → end; sundown timer; difficulty; objective picker.
✅ CHECKPOINT: 2-player local server (Test tab → Clients & Servers → 2): one becomes Worm, one Pardner.

**Phase 6 — Worm core.** Worm character, underground/surface movement, burrow rules, pounce, grab, mouth minigame,
health + forced burrow + rings, DetectionService pings.
✅ CHECKPOINT: 2-player: worm sees pings only when Pardner runs on sand; still Pardner is hidden; grab → minigame → escape works.

**Phase 7 — Death & revive.** Heart jars, digestion, ghosts (fly, push), Church revive, revive limits, ossified hearts.
✅ CHECKPOINT: die, jar drops, carry jar to church, revive with lower max HP; ghost can push a crate.

**Phase 8 — Map population.** MapService markers, houses w/ loot tiers, ranches, town well, quarry dynamite respawn,
lookout towers + chests with guarantees, structures + HP + scrap, dynamite explosions.
✅ CHECKPOINT: every marker type spawns; blow up a house with dynamite → scrap drops; well tokens tick.

**Phase 9 — Objectives 2–7** (one at a time; each one gets its own mini-checkpoint).

**Phase 10 — All kit items** (one behavior module each, test each via a debug `/give <id>` chat command in Studio only).

**Phase 11 — Worm abilities** (default 5 first, then the 8 choosables, one at a time).

**Phase 12 — Sundown effects, airdrops, balloon escape, polish, sounds hooks** (`-- TODO(asset)` sound ids in Config).

**Phase 13 — Lobby & UI overhaul** (MM2-style round loop on one server; server-authoritative; every number in
Config; UI built from `Config/Theme.luau` + `Controllers/UI/Components/`). Steps, each with its own checkpoint:
1. **Theme + shared UI components** (Panel, Button, Bar, Label, Slot, Tween helpers, UI sound hooks).
   ✅ CHECKPOINT: screen_capture of a sample panel / button / bar; user approves the style.
2. **Round loop + intermission + lobby greybox.** Lobby → Intermission countdown (needs ≥ 2 players, else
   "Waiting for players") → role roll → role reveal → worm loadout → teleport to the map → match → results →
   back to the lobby. The map is built far from the lobby and fully cleaned up after each round. Lobby = a small
   abandoned desert train station (platform, benches, ticket booth, big board with countdown + last result),
   greyboxed through AssetService ids; spawn pads, invisible walls, no combat. Late joiners wait in the lobby.
3. **Role roll + reveal + loadout.** Worm picked by weighted chance that grows each round a player isn't the
   Worm; AFK players skipped. Full-screen role card ("YOU ARE THE WORM" / "YOU ARE A PARDNER": description,
   color, sound, tween), then the worm's timed ability pick.
4. **Lobby HUD + spectate + AFK.** Countdown, player count, your Worm chance %, buttons: Shop, Inventory /
   Cosmetics, Settings, Spectate, AFK. Spectate cycles living players and shows name + role.
5. **In-match HUD cleanup + toasts** for both roles (roblox-ui skill). Kill feed / event toasts ("X was eaten",
   "Objective complete", "Sundown!").
6. **Results + settings + shop.** Winner banner, escaped / died, round stats (fuel delivered, Pardners eaten, …).
   Settings: music / SFX volume, camera sensitivity, worm first-person mouth view toggle. Shop = game passes,
   cosmetic / convenience only — never paid Worm chance or any gameplay advantage.

**Later / deferred:** Wormlings AI (5 types: Spicy, Icy, Grub, Onyx, Jr.; states Hunting/Investigating/Wandering;
eggs hatch over time per difficulty table), cosmetics, mobile controls, data saving.

---

## 16. Coding conventions
- Files: `PascalCase.luau`. Functions/locals `camelCase`. Constants in Config `PascalCase` keys.
- Services expose `Service.init()` then `Service.start()`; bootstrap calls all `init` then all `start`.
- Use `CollectionService` tags for anything the map places; attributes (`:SetAttribute`) for per-instance state that
  clients need to read (e.g. `ItemId`, `Fuel`, `Size`, `Lit`, `Bottles`).
- Physics items: server spawns, then `SetNetworkOwner(holder)` while held/thrown, back to server (`nil`) after resting.
- Every system has a debug toggle in `Config.Game.Debug` (draw hitboxes, rings, ping radius).
- When unsure of a number: put it in Config with `-- TUNE` and move on. Don't stall the build.
- After each phase: run `selene src` and `stylua src`, fix warnings, then summarize what changed + how to test.

---

## 17. Session protocol
- At the start of every session, read `PROGRESS.md` before doing anything.
- At the end of every phase, update `PROGRESS.md` with:
  - phases completed,
  - what each file does (one line each),
  - any decisions or deviations from the spec,
  - known bugs,
  - the exact next step.
- Keep `PROGRESS.md` under 150 lines. Rewrite it, don't just append.
