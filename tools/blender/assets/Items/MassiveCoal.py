# MassiveCoal — 3 x 3 x 3 studs. A heap of three fused coal boulders.


def build():
    parts = []
    for i, (r, loc) in enumerate([(1.35, (0, 0, 1.35)), (0.9, (0.9, 0.6, 0.9)), (0.8, (-0.85, -0.6, 0.8))]):
        lump = ico(r, location=loc, subdiv=2, name=f"lump{i}")
        jitter(lump, r * 0.12, seed=20 + i)
        paint(lump, "Coal")
        paint(lump, "CoalHighlight", faces={f for f in range(len(lump.data.polygons)) if f % 6 == i})
        parts.append(lump)
    return finalize(parts, "MassiveCoal", (3, 3, 3))
