# PROGRESS

Last updated: 2026-10-18 (Phase 13 — Lobby & UI overhaul in progress). Rewrite this
file at the end of every phase (CLAUDE.md §17).

## Phases completed

- **Phases 1–8** (skeleton, Pardner basics, items, Train & fuel, match flow, worm core, death & revive, map
  population). Done; each confirmed in Studio.
- **Phase 9 — Objectives 2–7.** All six written. Confirmed: RepairTracks. Never reported: the other five.
- **Phase 10 — All kit items.** Written; never reported in Studio.
- **Phase 11 — Worm abilities.** Written; never reported in Studio.
- **Phase 12 — Sundown effects, airdrops, balloon escape, sound hooks, polish.** Written; `stylua`, `selene`
  (0 warnings), `rojo build` pass. **Not yet confirmed in Studio.**
- **Test pass (2026-10-17), solo, driven through the Studio MCP** (a scripted client firing the real remotes,
  with every objective forced on and a 60 s sundown in a Studio-only config edit, since reverted):
  - Passed: all 6 objectives set up together without errors; Train Key → keyhole; fuel (3 Massive Coal =
    72/100, matches the formula); tumbleweed lit at furnace → signal fire lit; 2 scrap repairs a track;
    sassparilla crate delivered (6 bottles); safe (puzzle map → 3 digits → keypad → manual); dandylion
    lures a bug, which eats it; every kit (uses counted down, passives say so, rifle recoil, pogo ×5,
    coffee ×3, snake oil one dose, concoction ×3, cactus seeds plant small cacti near the Train, zipline
    builds and rides); airdrop (+5 chests at ~40 s); night at 60 s.
  - Fixed: (1) Roblox now keeps `PlayerModule` in `StarterPlayer` with no `GetControls` → InputController
    looked for it forever and `getMoveVector` returned zero (climbing input). It now finds either location and
    falls back to the raw WASD keybinds. (2) Thrown dandylions were rolling balls that rolled ~30 studs/s
    out of the bugs' reach → they now anchor where they land. (3) Cattlebugs could wander off the map edge
    into the void → they turn back when there's no ground ahead.
  - Not testable solo: worm abilities (Phase 11), balloon escape, anything 2P.
- **Art pass (2026-10-17):** all 94 assets have real low-poly models (Blender scripts → Open Cloud → Studio),
  verified in a solo playtest. Details, rules and Config size changes: `assets/ASSET_STATUS.md`.
- **Phase 13 — Lobby & UI overhaul** (added to CLAUDE.md §15 and CHECKLIST.md; 6 steps).
  - Step 1 done, **awaiting style approval**: `Config/Theme.luau` ("frontier notice board": paper panels on
    dark wood, hard drop shadow, brass accent; fonts Antique for titles, Merriweather Heavy for buttons /
    headings, Builder Sans for body + numbers — Arvo isn't available in Roblox). Components in
    `Controllers/UI/Components/`: Style (corner/stroke/padding/text limits/shadowed/tween/screen), UiSound
    (local UI sounds, `Ui*` keys in Config/Sounds, empty ids), Label, Panel (root + shadow + body, title
    banner, popIn), Button (hover 1.05 / press 0.95, click/hover/error sounds, disabled state), Bar (ghost
    fill, locked cap, pulse), Slot (key hint, selected stroke, cooldown overlay + seconds).
    `UI/StyleSample.luau` shows them all when `Config.Game.Debug.ShowUiSample = true`. Capture:
    `assets/renders/ui_style_sample.jpg` (checked at the ~540×710 Studio viewport = phone-ish). Approved.
  - Step 2 done: round loop on one server — Lobby (waiting, needs `Config.Lobby.MinPlayers` non-AFK) →
    Intermission (20 s) → RoleAssign (map loaded) → WormLoadout → Playing (Pardners teleported) → Ending →
    back to the lobby. `Map/Lobby.luau` builds the station at `Config.Lobby.Origin` (0,0,3000) from
    AssetService ids `Lobby*` + barrel/crate/cacti, spawn pads, invisible walls, departures board
    (SurfaceGui: countdown / waiting / in progress + last result). The map template and Train sit in
    ServerStorage between rounds (`MapService.loadMap/unloadMap`, `TrainService.setActive`); runtime is
    destroyed. Ready button removed (MM2-style countdown only). Only round players are teleported/returned.
  - Step 3 done: `shared/RoleRoll.luau` (weighted pick without replacement + chance %). MatchService keeps a
    per-UserId weight (session only): Pardners +1 per round (max 10), the Worm resets to 1; AFK players
    (`Afk` attribute via `Request_SetAfk`) are skipped. `WormChance` attribute (0–100) on every player.
    `UI/RoleCard.luau` (role-colored band, title slam, description fade, Reveal sound; text in
    `Config.Lobby.RoleCards`). `UI/LoadoutScreen.luau` rebuilt: timer bar + 2-column ability cards with
    descriptions (new `description` field in Config/Abilities); Pardners get a "Worm is choosing" strip.
- Deferred by the spec ("Later"): wormlings, cosmetics, mobile controls, data saving.

## What each file does

Root: `default.project.json` (Rojo tree + shift-lock off), `rokit.toml`, `selene.toml`, `stylua.toml`,
`README.md` (setup, model swapping, sounds, controls, testing helpers).

`src/server`
- `init.server.luau` — creates remotes, then loads Services in a fixed order (all `init`, then all `start`).
- `Services/MatchService` — match loop, roles, settings, loadout; sundown (night flags, health top-up, sound),
  the 66 % airdrop, balloon escape as a win; cleans every service up between matches.
- `Services/NPCService` — cattlebugs + dandylions; drives `NPC/BalloonPilot` (`beginMatch`, `airdrop`,
  `endMatch`, signal `balloonEscaped`).
- `NPC/BalloonPilot` — balloon model that flies to airdrop spots (chest each) and, when exactly one Pardner is
  alive (match started with ≥ 2), to a random spot with a ladder (hold F = escape); leaves if alive ≠ 1.
- `Services/PardnerService` — stats, death, revives, statuses, passive mods, Snake Oil, impulses,
  `sundownTopUp`. `Services/WormService`, `AbilityService`, `DetectionService`, `ItemService`, `KitService`,
  `MapService`, `StructureService`, `ExplosionService`, `TrainService`, `ReviveService`, `ObjectiveService`,
  `DigService`, `DebugService` — as before, plus sound cues.
- `Util/SoundCue` — `play(key, position?)` → `Fx_Sound` to every client (silent while the id is empty).
  `Util/Projectile`, `Util/AbilityKit` — as before.
- `Abilities/`, `Kits/`, `Map/`, `Objectives/` — ability halves, kit behaviours, map helpers, objectives.

`src/client`
- `Controllers/SoundController` — plays `Config.Sounds` entries on `Fx_Sound` (positional or everywhere).
- `Controllers/` — `InputController`, `MatchController`, `CameraController`, `PardnerMovementController`,
  `WormController`, `InventoryController`, `SafeController`, `HUDController`, `WormVisionController`,
  `MinigameController`, `GhostController`; `UI/` one file per screen.

`src/shared`
- `Config/Sounds` — one slot per game moment (Explosion, TrainHorn, LeverPulled, FurnaceBurn, Pounce, Grab,
  MouthEscape, SonarScream, ChestOpen, Dig, Revive, Airdrop, BalloonArrives, Sundown), ids empty.
- `Config/Game` (+ `Balloon` tuning), and the rest: `AssetService`, `Net`, `Types`, `PardnerLogic`,
  `ThrowLogic`, `ItemBehaviors/`, `AbilityBehaviors/`, `Config/*`, `Util/*`.

## Decisions and deviations from the spec

Structure
- Extra files not in §2: `Config/{ItemTuning,Keybinds,Sounds}`, `shared/{PardnerLogic,ThrowLogic}`,
  `Util/Ground`, `server/{Map,Objectives,Kits,Abilities,NPC,Util}/*`, `KitService`, `DebugService`,
  `Controllers/{MatchController,SafeController,SoundController}`.
- Kits (`server/Kits`) and abilities (`server/Abilities` + `shared/AbilityBehaviors` for client fx) are split
  from shared code because they need server services.
- Remotes beyond §13: `Request_Sprint/Jump/Ready/SetDifficulty/SelectAbilities/GhostPush/UseHeld/Dig/SafeCode`,
  `State_Inventory/Minigame/Safe`, `Ui_SafeKeypad`, `Pardner_Impulse`, `Worm_Launch`, `Fx_Ability`, `Fx_Sound`,
  `Fx_Notify`.

Sundown / balloon (Phase 12)
- Sundown: lighting → night, worm ability cooldowns × 0.67, Sonar covers the map (40 s cd), outer rings heal
  faster, no Church revives (Book of the Dead still works), and every living Pardner below the max health one
  more revive would give them is raised to it.
- Airdrop: at 66 % of the way to sundown (no sundown = no airdrop) the balloon flies to 5 random sand spots
  and drops a chest at each (`Chests.spawnOne`: random kit + maybe an extra), then leaves.
- Balloon escape: only with `EnableBalloon` and if the match started with ≥ `Balloon.MinPardners` (2). When
  exactly one Pardner is alive it flies to a random sand spot and lowers a ladder; **escaping = holding F at the
  ladder's foot** (not physically climbing it). A revive (alive ≠ 1) pulls the ladder up and the balloon leaves
  (despawns) until it's needed again, instead of hovering at the centre. Escaping ends the match: Pardners win.
- Sound hooks fire from: explosions, horn, lever, furnace, pounce, grab, mouth escape, sonar, chest, dig,
  revive, airdrop, balloon, sundown. All silent until ids are filled in `Config/Sounds`.

Earlier phases (still true; the per-system detail is in each file's header comment)
- Abilities: LMB/Space Pounce · E Burrow · Shift Sneak · Q Sonar · F Sinkhole · 1 / 2 picks; cooldowns on the
  worm HUD. Kits: T uses the kit (`xN` uses); passives via params. Objectives: modules with `setup`,
  `getProgress`, optional `step`, `cleanup`; `Debug.ForceObjectives` (now `{}`).
- Characters are loaded by MatchService (`CharacterAutoLoads = false`). Dead Pardners are ghosts.
- Worm and ghosts have no humanoid character; client-owned, non-colliding models driven by `LinearVelocity`.
- Greybox structures are walk-in; real models in `ReplicatedStorage/Assets` replace any greybox.

## Known bugs / risks

- Phase 11 (worm abilities) and the balloon escape are still untested in Studio; the rest of 9–12 has only
  the automated solo pass above (no human feel-testing yet).
- A zipline end the harpoon hooked high up (e.g. a watertower) can only be reached from up there; riding to
  it drops you at the hit point (you fall if there's nothing to stand on).
- Bullworm Rifle recoil is straight opposite the aim, so shooting at your feet launches you upward.
- `ContentId rbxassetid://203785492 ... Asset type does not match` warning on Play — not from our code.
- Phase 12 risks: the balloon/ladder are greybox and may sit oddly on uneven ground; airdrop chests land at
  sand height wherever the spot is.
- No real sounds, particles, animations or art yet (`TODO(asset)` everywhere).
- Cattlebugs and the worm pass through structures. A lost dug-up key never comes back.
- Each match's OpenSafe adds a `Request_SafeCode` limiter to Net's list (tiny leak).
- End screen matches players by DisplayName. Server ground check assumes R15; no `luau-lsp`.
- `rojo` on PATH is an old Aftman install (7.7.0-rc.1), not the Rokit-pinned 7.7.1.

## Exact next step

1. User approves (or adjusts) the UI style from Phase 13 step 1 (`assets/renders/ui_style_sample.jpg`).
2. Then Phase 13 step 2: round loop + intermission + lobby train-station greybox (map built far from the
   lobby and cleaned up each round). Steps 3–6 follow, each with its own checkpoint and commit.
3. Still owed from before: 2P tests of worm abilities, balloon escape, grab-related kits (CHECKLIST 10–12).
