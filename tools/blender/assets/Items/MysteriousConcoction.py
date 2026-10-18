# MysteriousConcoction — 0.8 x 1.6 x 0.8 studs. A round-bellied flask of bubbling purple liquid, corked.


def build():
    flask = lathe([(0.25, 0.0), (0.4, 0.15), (0.4, 0.6), (0.15, 0.95), (0.13, 1.3)], segments=10, name="flask")
    paint(flask, "Glass")
    liquid = lathe([(0.26, 0.04), (0.39, 0.16), (0.39, 0.55), (0.25, 0.75)], segments=10, name="liquid")
    paint(liquid, "Purple")
    parts = [flask, liquid,
             cyl(0.14, 0.25, location=(0, 0, 1.42), segments=8, color="WoodLight"),
             box((0.5, 0.05, 0.3), location=(0, -0.38, 0.4), color="Paper"),
             ico(0.06, location=(0.1, -0.2, 0.85), subdiv=1, color="Purple")]
    return finalize(parts, "MysteriousConcoction", (0.8, 1.6, 0.8))
