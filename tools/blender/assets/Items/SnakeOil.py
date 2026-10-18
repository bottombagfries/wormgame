# SnakeOil — 0.7 x 1.5 x 0.7 studs. A tall square tonic bottle, green glass, snake label, wax seal.


def build():
    parts = [
        box((0.6, 0.6, 1.0), location=(0, 0, 0.5), bevel=0.06, color="Cactus"),
        cyl(0.15, 0.3, location=(0, 0, 1.15), segments=8, color="CactusDark"),
        cyl(0.17, 0.12, location=(0, 0, 1.35), segments=8, color="Red"),
        box((0.5, 0.04, 0.5), location=(0, -0.31, 0.5), color="Paper"),
        box((0.3, 0.05, 0.08), location=(0, -0.33, 0.55), rotation=(0, 0.4, 0), color="CactusDark"),
        box((0.3, 0.05, 0.08), location=(0, -0.33, 0.45), rotation=(0, -0.4, 0), color="CactusDark"),
    ]
    return finalize(parts, "SnakeOil", (0.7, 1.5, 0.7))
