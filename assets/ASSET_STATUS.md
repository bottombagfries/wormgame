# ASSET STATUS

**All 103 assets in `Config/Assets.luau` have real models** (50 items, 27 structures, 9 lobby, 5 characters, 12 effects),
uploaded, imported into `ReplicatedStorage/Assets/*` and checked in play (2026-10-17). Studio models live in
the place file, not in Git: **save the place after any import.** Ids: `src/shared/Config/AssetIds.luau`.

Renders: `assets/renders/items_all.png`, `items_batch1.png`, `structures_all.png`, `characters_effects.png`.

## Pipeline
1. Blender: `exec(open(r"<repo>\tools\blender\wt_style.py").read())`, then `objs = build_any(folder, id)` and
   `export_any(objs, folder, id)`. Build scripts: `tools/blender/assets/<Folder>/<id>.py`. One-mesh assets use
   `finalize`; structures use `finalize_group` (several named meshes, one shared origin) or `house(...)`.
2. Upload: `powershell -File tools/upload_asset.ps1 -File assets/models/<Folder>/<id>.fbx -Type Model -Name <id>`.
3. Studio (edit, MCP): `game:GetObjects` the Model asset → for each MeshPart, `AssetService:CreateMeshPartAsync`
   with its MeshId, copy CFrame + Size, strip `.001` from names → Model in `ReplicatedStorage/Assets/<Folder>/<id>`.
   Rules used:
   - Texture = palette image 81576212373708, except untextured parts (game code recolors them):
     `Wall`/`Roof`/`Trim` on houses, `Kindling` (SignalFire), `Rails` (BrokenTrack).
   - Collision: single-mesh assets Hull; multi-part structures PreciseConvexDecomposition (doorways stay open);
     `Detail`/`Trim` parts CanCollide off; TrainFurnace CanCollide off (thrown items go in); Tornado
     CanCollide off + Transparency 0.35.
   - MagmaPatch and RifleTracer: Neon + color, no texture. Ghost: ForceField material.
   - Houses get a 5×5 grid of `LootPoint` attachments on the floor; the Church gets 7 (pulpit at the back,
     pews in rows).
- Export scale 1.0 (1 Blender unit = 1 stud). Blender −Y = Roblox −Z (front; doors face it).

## Config size changes (made to match the models; CLAUDE.md §3)
CoffeePot Z 0.7 · Skillet Z 1.1 · Painting Z 0.35 · Horseshoe Z 0.85 · TrainKey Y 0.5 · CursedTrinket Z 0.3 ·
BullwormRifle X 0.35 · CymbalMonkey Z 1 · PogoStick (1.2, 4, 0.4) · QuickEscapeKnife X 0.22 · Slingshot Z 0.3 ·
SafeDigitSign Z 0.6 · CactusTall (3.5, 16, 2.1) · Cattlebug X 3.8 · Tornado (40, 60, 40) (Sandstorm's real size) ·
BalloonLadder (2, 80, 0.4) (built long so the game's stretch doesn't space the rungs out).
Zone effects (Sinkhole/Sandtrap/Magma) keep their cylinder greybox sizes in Config; their meshes are flat discs
(10×0.4×10 etc.) that AbilityKit scales to the zone width.

## Lobby (Phase 13, 2026-10-18)
Folder `ReplicatedStorage/Assets/Structures`; build scripts `tools/blender/assets/Lobby/<id>.py`; FBX in
`assets/models/Lobby/`. Every part uses the palette texture; `Detail` parts don't collide; single meshes
Hull, multi-part PreciseConvexDecomposition. Layout: `Config.Lobby.Pieces`, which also places the map's
Barrel, Crate, Watertower, Traincar, Stagecoach and cacti around the station.

| Id | Size (studs) | Model asset | Parts → MeshId | Tris | Status |
|---|---|---|---|---|---|
| LobbyGround | 170 × 2 × 130 | 127883280147723 | LobbyGround 122022394204587 | 96 | imported |
| LobbyTrack | 150 × 1 × 8 | 123769058159554 | Ties 113050319227583, Rails 126588210309214 | 516 | imported |
| LobbyPlatform | 96 × 3 × 16 | 75240283348282 | Base 88642964795908, Deck 100885071806699, Detail 74473247410422 | 516 | imported |
| LobbyDepot | 40 × 18 × 14 | 113045279668002 | Wall 130460289893418, Roof 82245410907499, Detail 115081921873503 | 450 | imported |
| LobbyBoard | 22 × 13 × 1 | 100961181328186 | Frame 72285319738380, Screen 86099192794400, Detail 70857325126277 | 112 | imported; text drawn on `Screen`'s Front face |
| LobbyTicketBooth | 8 × 10 × 6 | 129243702915770 | Wall 88534139727081, Roof 115266202407703, Detail 86369668494112 | 126 | imported |
| LobbyBench | 7 × 2.5 × 2 | 89643827205478 | LobbyBench 75648135159826 | 132 | imported |
| LobbyLamp | 1.5 × 10 × 1.5 | 107570775533141 | LobbyLamp 116556373681543 | 112 | imported (new id) |
| LobbySteps | 8 × 3 × 6 | 72260182790306 | LobbySteps 130170019305368 | 132 | imported; one at each platform end, Hull = walkable ramp |

## Worm skins (2026-10-18)
Palette variants for WormHead / WormSegment (same meshes and UVs; the Flesh, FleshDark, plate and eye cells
are recolored). Source colors: `tools/blender/skins/worm_skins.py` → `assets/textures/skins/*.png`; uploaded as
Decals; the image ids are in `src/shared/Config/WormSkins.luau`. B textures dress even segments (bands).
Render: `assets/renders/worm_skins.png`.

| Skin | Unlock | Texture A (image) | Texture B (image) | Decal ids |
|---|---|---|---|---|
| Classic | Free | palette 81576212373708 | – | – |
| Dune | Free | 72328951713999 | – | 88733221188921 |
| Rattlesnake | Worm Skins Pack | 78479604786065 | 122295198316072 | 75492326466731, 74084866311593 |
| Bone | Worm Skins Pack | 123227177687544 | – | 109707528129975 |
| Copper | Worm Skins Pack | 113700087497112 | 109108725796998 | 133976884926654, 78769687878093 |

## Verified in play (solo)
- Every item, structure, character and effect spawned in a match is the mesh (0 greyboxes on the map).
- Items: pickup / hold / bag / throw on SmallCoal, BigCoal, Barrel, Lantern, Crate, Table, Bed, Tumbleweed,
  GrainSack, Pew, Shovel (kit); furnace +7 from BigCoal; dynamite lights, explodes, leaves the Crater mesh.
- Structures: walked through the door of every house type and the Church; side walls block; 282/288 house
  loot lands inside the walls.
- Effects: cactus seeds → CactusTall mesh, rifle → tracer, dandylion, crater. Ghost spawns with the mesh.
- No errors in Output.

## Not yet checked by a person (needs eyes or 2 players)
- How everything looks in Studio (the MCP screenshot of the Studio viewport comes back blank here).
- Worm head/segments and abilities' zones (Sinkhole, Sandtrap, Magma, Tornado, Tar spires, Bile bomb) in a 2P
  match; Balloon + ladder (needs 2 Pardners); stagecoach crates, signal fire lit color, repaired track color.

## Item triangle counts (all well under budget)
Items 80–660 tris each; structures 92–1596 total (largest single mesh: Train Frame 804); characters 154–548;
effects 20–384. Full per-asset numbers are printed by the build scripts.
