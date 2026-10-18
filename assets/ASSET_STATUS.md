# ASSET STATUS

Statuses: `todo` · `script` (Blender build script exists) · `blender-ok` (built, size checked) ·
`imported` (uploaded + in Studio, verified in play). Studio models live in the place file, not in Git:
**save the place after each import.** Mesh ids are recorded in `src/shared/Config/AssetIds.luau`.

## Pipeline (settled 2026-10-17)
1. Blender: `exec(open(r"<repo>\tools\blender\wt_style.py").read())`, then `build_asset("Items", id)` and
   `export_fbx(obj, "Items")`. Build scripts: `tools/blender/assets/<Folder>/<id>.py`.
2. Upload: `powershell -File tools/upload_asset.ps1 -File assets/models/<Folder>/<id>.fbx -Type Model -Name <id>`
   (prints the Model asset id only; reads ROBLOX_API_KEY / ROBLOX_CREATOR_ID from the environment).
3. Studio (edit, MCP): `game:GetObjects` the Model asset → read its MeshPart's MeshId →
   `AssetService:CreateMeshPartAsync` (Hull collision) → TextureID = palette image → Model with PrimaryPart in
   `ReplicatedStorage/Assets/<Folder>/<id>`.
- **Export scale = 1.0**: 1 Blender unit came in as exactly 1 stud (SmallCoal 1×1×1 → MeshSize 1×1×1).
- Palette texture: Decal 86148081784505 → image 81576212373708 (every MeshPart's TextureID).
- The Studio viewport renders blank to the MCP screen capture here, so Studio checks are numeric (part class,
  size, greybox count in play) plus the Blender renders in `assets/renders/`.

## Items — batch 1 ✅ (render: `assets/renders/items_batch1.png`)
| id | status | tris | notes |
|---|---|---|---|
| SmallCoal | imported | 80 | faceted lump; 31/31 in a match are the mesh; pickup, hold, throw, settles |
| BigCoal | imported | 100 | two fused lumps; thrown fine; furnace +7 fuel (14/100 solo) ✓ |
| Barrel | imported | 404 | staves + 3 hoops; size-X hold + throw ✓ (lands on its side, rolls a bit) |
| Dynamite | imported | 156 | 3 sticks + band + fuse; light (R) → throw → explodes after the fuse ✓ |
| Lantern | imported | 250 | glowing chimney; Studio model adds a warm PointLight (range 10) in place of the greybox's Neon |

## Items — next batches (~5 each, in this order)
- Batch 2 (fuel, small): MassiveCoal, Bucket, CoffeePot, Skillet, RustyTinCan
- Batch 3 (fuel, furniture): Stool, Chair, Table, Bench, Bed
- Batch 4 (fuel, misc): Gramophone, DutchOven, Painting, GrainSack, Pew
- Batch 5: Pulpit, CactusFruit, Horseshoe, Crate, Chest
- Batch 6 (objective): TrainKey, Scrap, Tumbleweed, SassparillaCrate, PuzzleMap
- Batch 7: TrainManual, Backpack, HeartJar, Ladder, CursedTrinket
- Batches 8–10 (kits): BullwormRifle, CactusSeedPouch, Canteen, CoffeeTin, CymbalMonkey, DandylionBundle,
  SpiritBoard, MysteriousConcoction, DeadBook, PogoStick, QuickEscapeKnife, Shovel, Slingshot, SnakeOil,
  ZiplineCrossbow

## Structures, Characters, Effects
All `todo`. See `src/shared/Config/Assets.luau` for ids and sizes. Structures need LootPoint empties
(→ Attachments) and the 10k-triangles-per-mesh cap.
