# PROGRESS

Last updated: 2026-10-18 (Phase 13 — Lobby & UI overhaul built, all 6 steps; awaiting human tests).
Rewrite this file at the end of every phase (CLAUDE.md §17).

## Phases completed

- **Phases 1–8** (skeleton, Pardner basics, items, Train & fuel, match flow, worm core, death & revive, map
  population). Done; each confirmed in Studio.
- **Phases 9–12** (objectives 2–7, all kits, worm abilities, sundown/airdrop/balloon/sound hooks). Written;
  RepairTracks confirmed by the user; the rest passed an automated solo MCP pass on 2026-10-17 (every
  objective, every kit, airdrop, night). Not testable solo: worm abilities, balloon escape, anything 2P.
- **Art pass (2026-10-17):** all 94 assets have real low-poly models; see `assets/ASSET_STATUS.md`.
- **Lobby models (2026-10-18):** 8 lobby assets modelled, uploaded and imported (ground, track, platform,
  depot, departures board with a `Screen` part, ticket booth, bench, new `LobbyLamp`); the station layout now
  also reuses the map's watertower, a derelict traincar, a stagecoach, barrels, crates and cacti. 0 greyboxes.
- **Phase 13 — Lobby & UI overhaul** (CLAUDE.md §15, CHECKLIST.md). All six steps built, self-tested solo
  through the Studio MCP (selene/stylua clean, no script errors), one commit per step:
  1. Theme + components (style approved).
  2. Round loop: Lobby (waiting) → Intermission (20 s, needs `Config.Lobby.MinPlayers` non-AFK) →
     RoleAssign (map loaded) → WormLoadout → Playing (Pardners teleported) → Ending (results) → lobby.
     Lobby train station at `Config.Lobby.Origin` (0,0,3000). Map template + Train wait in ServerStorage
     between rounds; runtime destroyed (verified: Workspace back to Lobby + empty runtime folders).
  3. Weighted Worm roll (`shared/RoleRoll`), AFK skipped, role card, timed ability picker.
  4. Lobby HUD (status, last result, host difficulty, Shop/Cosmetics/Settings/Spectate/AFK, players +
     Worm chance %), spectate (living Pardners + Worm heads, name + role chip).
  5. In-match HUDs rebuilt from components (Pardner vitals, inventory slots, objectives + sundown clock,
     worm status + ability slots, ghost), compact layout under 760 px, toasts / kill feed.
  6. Results (banner, escaped / didn't make it, 6 round stats, countdown), Settings (music, SFX, camera
     speed, worm mouth view; session only), Shop (game passes from `Config/Shop`, cosmetic only).
- Deferred by the spec ("Later"): wormlings, cosmetics, mobile controls, data saving.

## What each file does (Phase 13 additions; older files are described in their header comments)

`src/shared`
- `Config/Theme` — every UI color, font, corner, stroke, padding, size, tween, UI sound key, toast timing.
- `Config/Lobby` — round timings, role-roll weights, role-card text, station layout, board, pads, walls.
- `Config/Settings` — settings defaults/ranges, mouth-view camera, music ids. `Config/Shop` — game passes.
- `RoleRoll` — weighted pick without replacement + chance %. `Types` — `MatchPhase` adds Intermission;
  `MatchState.activeCount/lastResult`; `MatchResult.worms/stats` (`RoundStats`); `ToastKind`.
`src/server`
- `Map/Lobby` — builds the station via AssetService, spawn pads, invisible walls, departures board text.
- `Services/MatchService` — round loop, weights + `WormChance`, AFK (`Request_SetAfk`), teleports, board,
  results with stats. `MapService.loadMap/unloadMap/getTrainSpawn`; `TrainService.setActive`;
  `ReviveService.getRoundStats`; `ObjectiveService.getSummary` + objective toasts.
`src/client/Controllers`
- `LobbyController` (lobby HUD + windows), `SpectateController`, `ToastController` (`Fx_Notify`),
  `SettingsController` (values, Music/Sfx sound groups, mouse sensitivity, music player).
- `UI/Components/` — Style (+`fitRow`), UiSound, Label, Panel, Button, Bar, Slot, Modal, Slider.
- `UI/` — LobbyHud, SpectateHud, RoleCard, LoadoutScreen, ResultsScreen, SettingsScreen, ShopScreen,
  Toasts, PardnerHud, InventoryHud, ObjectivesHud, WormHud, GhostHud, StyleSample (debug), plus the
  older MinigameHud, KeypadScreen, PuzzleMapHud (not restyled yet).

## Decisions and deviations from the spec

Phase 13
- Fonts: Antique (titles), Merriweather Heavy (buttons/headings), Builder Sans (body) — Arvo isn't in Roblox.
- No Ready button any more (MM2-style countdown). Host difficulty button stays in the lobby HUD.
- "Map built far away and cleaned up": the hand-built / greybox map stays at the origin, the lobby is 3000
  studs away; between rounds the template is parented to ServerStorage (not destroyed, so a hand-built
  MapTemplate survives) and everything spawned per round is destroyed.
- Worm weights: base 1, +1 per round played as a Pardner (max 10), reset to 1 as the Worm; session only.
  Chance % shown = weight share × Worm slots (exact for 1 Worm). Solo (Debug.AllowSoloMatch) shows 0 %.
- AFK players keep playing a round they're already in; AFK only affects the next roll.
- Toasts reuse `Fx_Notify(text, kind?)`: no kind = personal hint above the inventory.
- Settings are client-side for the session (no data saving yet). Camera speed sets
  `UserInputService.MouseDeltaSensitivity`. Mouth view = first-person camera just in front of the worm head.
- Shop is cosmetic only (user decision): Worm skins, hats, train horn sounds, trails. Worm chance is never
  sold or boosted. All passes have id 0 ("Coming soon") until created; perks are not granted yet.
- Spectate is local camera only; it's offered to anyone without a role while a round is Playing.

Earlier (still true)
- Characters are loaded by MatchService (`CharacterAutoLoads = false`). Dead Pardners are ghosts.
- Worm and ghosts have no humanoid; client-owned models driven by `LinearVelocity`.
- Extra remotes beyond §13: `Request_Sprint/Jump/SetDifficulty/SetAfk/SelectAbilities/GhostPush/UseHeld/
  Dig/SafeCode`, `State_Inventory/Minigame/Safe`, `Ui_SafeKeypad`, `Pardner_Impulse`, `Worm_Launch`,
  `Fx_Ability`, `Fx_Sound`, `Fx_Notify`.
- Balloon escape = hold F at the ladder's foot. Sundown/airdrop details as in Phase 12 file headers.

## Known bugs / risks

- Untested by a human: everything in Phase 13; anything 2-player (Worm card + picker in a real round,
  spectate, weights over several rounds, kill feed from a real grab); Phase 11 abilities; balloon escape.
- Studio's play viewport during the MCP checks was portrait (296–540 px wide), narrower than real phones
  (landscape). Layouts were fixed for it, but check the Device emulator at a landscape phone and 1080p.
- No real sounds/music/particles/animations (`TODO(asset)`; UI and music ids empty).
- The lobby platform is 3 studs tall, so getting back up from the track side needs a jump (no steps yet).
- Results match the local player by DisplayName. Each OpenSafe adds a `Request_SafeCode` limiter (tiny leak).
- Zipline ends hooked high up drop you at the hit point. Rifle recoil can launch you upward.
- `ContentId rbxassetid://203785492 ... Asset type does not match` warning on Play — not from our code.
- MinigameHud, KeypadScreen and PuzzleMapHud still use the old plain style.
- `rojo` on PATH is an old Aftman install (7.7.0-rc.1), not the Rokit-pinned 7.7.1.

## Exact next step

1. User runs CHECKLIST.md Phase 13 steps 2–6 (2-player local server for roles, spectate, kill feed).
2. Fix what they find; then restyle MinigameHud / KeypadScreen / PuzzleMapHud with the components.
3. Still owed: 2P tests of worm abilities, balloon escape, grab-related kits (CHECKLIST 10–12).
4. Create the game passes and paste their ids into `Config/Shop`; add sound / music ids.
