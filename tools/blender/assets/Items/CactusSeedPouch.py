# CactusSeedPouch — 1 x 1.2 x 1 studs. A drawstring leather pouch with a cactus patch and seeds spilling out.


def build():
    pouch = ico(0.5, location=(0, 0, 0.5), subdiv=2, name="pouch")
    pouch.scale = (1, 1, 0.95)
    jitter(pouch, 0.03, seed=9)
    paint(pouch, "WoodLight")
    parts = [pouch,
             cone(0.3, 0.12, 0.35, location=(0, 0, 1.0), segments=8, color="WoodLight"),
             torus(0.18, 0.04, location=(0, 0, 0.92), major_seg=8, minor_seg=3, color="WoodDark"),
             box((0.2, 0.05, 0.35), location=(0, -0.5, 0.5), color="Cactus"),
             box((0.12, 0.05, 0.12), location=(0.13, -0.5, 0.55), color="Cactus"),
             ico(0.06, location=(0.05, 0.05, 1.18), subdiv=1, color="CactusDark")]
    return finalize(parts, "CactusSeedPouch", (1, 1.2, 1))
