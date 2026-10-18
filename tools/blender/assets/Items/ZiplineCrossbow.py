# ZiplineCrossbow — 2.5 x 0.8 x 3.5 studs. A crossbow with a grappling harpoon loaded and a rope spool.
import math


def build():
    parts = [
        box((0.35, 2.6, 0.35), location=(0, 0.3, 0.4), bevel=0.03, color="WoodMid"),
        box((0.3, 0.8, 0.5), location=(0, 1.4, 0.3), rotation=(-0.25, 0, 0), color="WoodDark"),
        box((2.5, 0.25, 0.18), location=(0, -0.85, 0.5), rotation=(0.0, 0, 0), color="WoodDark"),
        box((0.6, 0.2, 0.15), location=(-1.05, -0.7, 0.5), rotation=(0, 0, -0.35), color="Iron"),
        box((0.6, 0.2, 0.15), location=(1.05, -0.7, 0.5), rotation=(0, 0, 0.35), color="Iron"),
        box((2.3, 0.04, 0.04), location=(0, -0.3, 0.55), color="Cloth"),
        cyl(0.05, 1.8, location=(0, -0.7, 0.62), segments=6, color="MetalLight", rotation=(math.pi / 2, 0, 0)),
        cone(0.14, 0.0, 0.3, location=(0, -1.75, 0.62), segments=6, color="MetalDark", rotation=(math.pi / 2, 0, 0)),
        cyl(0.25, 0.3, location=(0, 0.6, 0.15), segments=8, color="ClothDark", rotation=(0, math.pi / 2, 0)),
    ]
    return finalize(parts, "ZiplineCrossbow", (2.5, 0.8, 3.5))
