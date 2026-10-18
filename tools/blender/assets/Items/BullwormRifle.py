# BullwormRifle — 0.5 x 0.8 x 4.5 studs. Long-barrel lever rifle with a wooden stock and brass fittings.
import math


def build():
    parts = [
        cyl(0.09, 2.6, location=(0, -1.0, 0.55), segments=8, color="Iron", rotation=(math.pi / 2, 0, 0)),
        cyl(0.07, 2.2, location=(0, -0.8, 0.4), segments=6, color="MetalDark", rotation=(math.pi / 2, 0, 0)),
        box((0.32, 0.9, 0.38), location=(0, 0.6, 0.45), bevel=0.03, color="Iron"),
        box((0.3, 1.5, 0.45), location=(0, 1.55, 0.35), rotation=(-0.18, 0, 0), bevel=0.05, color="WoodMid"),
        box((0.32, 0.25, 0.6), location=(0, 2.2, 0.3), bevel=0.04, color="WoodDark"),
        box((0.28, 0.9, 0.2), location=(0, -0.2, 0.32), color="WoodMid"),
        torus(0.15, 0.03, location=(0, 0.75, 0.15), major_seg=8, minor_seg=3, color="Brass", rotation=(0, math.pi / 2, 0)),
        box((0.06, 0.1, 0.12), location=(0, -2.25, 0.68), color="Brass"),
        cyl(0.12, 0.2, location=(0, -0.3, 0.55), segments=8, color="Brass", rotation=(math.pi / 2, 0, 0)),
    ]
    return finalize(parts, "BullwormRifle", (0.35, 0.8, 4.5))
