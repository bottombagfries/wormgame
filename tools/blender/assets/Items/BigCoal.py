# BigCoal — 2 x 2 x 2 studs. A chunky coal block: one big faceted lump with a smaller one fused on.


def build():
    main = ico(0.95, location=(0, 0, 0.95), subdiv=2, name="main")
    main.scale = (1.0, 0.9, 0.95)
    jitter(main, 0.12, seed=11)
    side = ico(0.55, location=(0.55, 0.35, 0.55), subdiv=1, name="side")
    jitter(side, 0.08, seed=12)
    for part, step in ((main, 4), (side, 3)):
        paint(part, "Coal")
        paint(part, "CoalHighlight", faces={i for i in range(len(part.data.polygons)) if i % (step + 3) == 0})
    return finalize([main, side], "BigCoal", (2, 2, 2))
