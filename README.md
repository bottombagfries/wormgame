# Wormtown-style asymmetric Roblox game

Rojo + Luau project. `CLAUDE.md` is the design doc and build plan.

## Setup

1. Install the tools: `rokit install` (Rojo, selene, StyLua).
2. Install the Rojo plugin in Roblox Studio (same major/minor version as `rojo --version`).
3. In this folder: `rojo serve`
4. In Studio: open any place (a new Baseplate is fine) → Plugins → Rojo → **Connect**.
5. Press **Play**.

With an empty `Workspace/MapTemplate`, the game builds a flat sand greybox map with auto-placed
markers, so it is playable with zero building.

Lint and format: `selene src` and `stylua src`.

## Replacing a greybox with a real model

Everything visual starts as a labeled greybox cube. To replace one:

1. Make a **Model** in Studio named exactly the asset id shown on the greybox label (e.g. `SmallCoal`).
2. Set its **PrimaryPart**.
3. Drop it into the matching folder: `ReplicatedStorage/Assets/Items`, `Structures`, `Characters`,
   or `Effects`.

Rojo will not delete models you put in those folders. Collision and physics settings are applied
by code, not by the model. Keep roughly the same size as the greybox, or update `size` for that
asset in `src/shared/Config/Assets.luau`.

## Building your own map

Build inside `Workspace/MapTemplate` and place invisible, anchored, non-colliding marker parts with
CollectionService tags (`TrainSpot`, `RanchSpot`, `Sand`, …). The full tag list is in `CLAUDE.md` §4.
If a tag has no markers, the server prints a warning and uses a fallback position instead of erroring.

Structure models can carry extras the code looks for: parts named `Wall`/`Body` take the house color and
`Roof`/`Trim` the trim color, `LootPoint` attachments mark where loot goes, and a Church part named
`ReviveRing` sets where the revive ring is. The Train model can contain parts named `Furnace`, `Lever`,
`Horn` and `Keyhole`.

## Sounds

Every sound is a slot in `src/shared/Config/Sounds.luau` with an empty id (silent). Paste an asset id
(`"rbxassetid://123"`) into a slot and the game plays it at that moment.

## Controls

Keys are in `src/shared/Config/Keybinds.luau`.

- **Pardner:** WASD + Space · Shift sprint · jump at a wall to climb (Space climb-jump, C let go) ·
  E pick up (hold E on sand with a Shovel to dig) · Q store in bag · G drop · 1–9 take from bag ·
  R use held item (light dynamite) · T use kit · hold RMB to aim, LMB to throw · F prompts.
- **Worm:** WASD (camera-relative) · LMB/Space pounce · E burrow/surface · Shift sneak · Q Sonar Scream ·
  F Sinkhole · 1 / 2 the two abilities picked in the loadout.
- **Ghost:** WASD fly · Space up · Shift down · hold E on an item to push it.
- **Mouth minigame:** W/A/S/D or arrows as shown · G toggles auto-escape.

## Testing helpers (Studio only)

In `Config/Game.luau` → `Debug`: `AllowSoloMatch`, `NoWorm` (everyone is a Pardner), `ForceObjectives`
(e.g. `{ "OpenSafe" }`), `SpawnAtTrain`, `ShowBuried`, `SpawnTestItems`, `SpawnTestHouse`.
Chat commands: `!give <ItemId>`, `!hurt <n>`, `!heal <n>`. For quick sundown / airdrop tests, lower
`Sundown.Seconds` in the same file.

## Tuning

Every number lives in `src/shared/Config/`. Values marked `-- TUNE` are guesses.
