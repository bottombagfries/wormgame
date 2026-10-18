# ART STYLE — approved 2026-10-17

Original, low-poly "storybook frontier" look. Nothing here copies another game's models, logos or
characters. Sample: `assets/renders/style_sample.png` (Barrel, Dynamite, Lantern).

## Palette
- One shared 256 px texture, `assets/textures/WT_Palette.png`: an 8×8 grid of flat color cells (32 used,
  the rest magenta = "unused, flags a UV mistake"). The color names live in `tools/blender/wt_style.py`.
- Every mesh uses that one texture and one material. Faces are UV-mapped to the middle of a color cell, so
  there are no painted textures and no gradients. Nearest filtering.
- Families: sand (2), wood (3), cloth (3), metal/iron/coal (6), rust/brass/copper, reds, cactus greens + sage,
  fruit pink, teal, glow/fire, flesh (worm), paper/ink, glass, purple.
- Warm, sun-bleached, slightly desaturated. Saturated colors are only for things players must notice:
  red dynamite, glowing lanterns and fire, pink cactus fruit, brass objective items.

## Shape language
- Chunky, slightly exaggerated silhouettes that read at 30+ studs: bulging barrels, fat coal lumps, thick
  handles. Readable shape beats fine detail.
- Mostly straight cuts and low segment counts (8–12 around a cylinder). A small hand-made wobble
  (`jitter`) on organic things (coal, rocks, cacti, sacks), none on metal or machined parts.
- Wood is shown with alternating light/mid planks or staves, not grain textures.

## Detail level
- Triangle budgets: small props < 3k, large props < 5k, structures < 10k per mesh (split bigger
  ones). Typical item: 150–600 triangles.
- Detail goes into silhouette and 2–3 color bands, never tiny geometry (no nails, no text).

## Edges
- Flat shading (no smooth normals). Small bevels (0.02–0.05 studs) on boxy wood/metal so edges catch light.
  Organic shapes stay faceted with no bevel.

## Technical (from the skill)
- 1 Blender unit = 1 stud. The size matches `Config/Assets.luau` (`finalize` checks it is within 2 %).
  Origin at bottom-center; round items meant to roll (CactusFruit, Tumbleweed) are centered.
- Mesh object named exactly the asset id. Moving parts are separate meshes. Loot holders get
  `LootPoint` empties.
