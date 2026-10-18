# Canteen — 1.2 x 1.4 x 0.6 studs. Round felt-covered canteen with a cap and a strap loop.
import math


def build():
    parts = [
        cyl(0.6, 0.58, location=(0, 0, 0.6), segments=12, color="ClothDark", rotation=(math.pi / 2, 0, 0)),
        torus(0.6, 0.06, location=(0, 0, 0.6), major_seg=12, minor_seg=3, color="MetalLight", rotation=(math.pi / 2, 0, 0)),
        cyl(0.12, 0.2, location=(0, 0, 1.25), segments=8, color="MetalLight"),
        cyl(0.13, 0.08, location=(0, 0, 1.36), segments=8, color="Iron"),
    ]
    return finalize(parts, "Canteen", (1.2, 1.4, 0.6))
