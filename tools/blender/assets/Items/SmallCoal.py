# SmallCoal — 1 x 1 x 1 studs. A faceted lump of coal with a few lighter glints.


def build():
    lump = ico(0.5, location=(0, 0, 0.5), subdiv=2, name="lump")
    lump.scale = (1.0, 0.92, 0.95)
    jitter(lump, 0.07, seed=3)
    paint(lump, "Coal")
    paint(lump, "CoalHighlight", faces={i for i in range(len(lump.data.polygons)) if i % 7 == 0})
    return finalize([lump], "SmallCoal", (1, 1, 1))
