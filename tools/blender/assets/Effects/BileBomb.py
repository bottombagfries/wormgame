# BileBomb — 1.5 x 1.5 x 1.5. A sticky glob of green bile with bubbles.


def build():
    glob = ico(0.7, location=(0, 0, 0.72), subdiv=2, name="glob")
    jitter(glob, 0.06, seed=61)
    paint(glob, "Sage")
    paint(glob, "Cactus", faces={i for i in range(len(glob.data.polygons)) if i % 4 == 0})
    parts = [glob, ico(0.2, location=(0.4, -0.3, 1.2), subdiv=1, color="Sage"), ico(0.15, location=(-0.35, 0.3, 1.25), subdiv=1, color="Cactus")]
    return finalize(parts, "BileBomb", (1.5, 1.5, 1.5))
