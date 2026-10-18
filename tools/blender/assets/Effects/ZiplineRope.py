# ZiplineRope — 0.3 x 0.3 x 1, stretched along Z by the game. A braided rope.
import math


def build():
    parts = [cyl(0.15, 1.0, location=(0, 0, 0.15), segments=6, color="WoodLight", rotation=(math.pi / 2, 0, 0))]
    for k in range(4):
        parts.append(torus(0.14, 0.02, location=(0, -0.375 + k * 0.25, 0.15), major_seg=6, minor_seg=3, color="WoodDark", rotation=(math.pi / 2, 0, 0)))
    return finalize(parts, "ZiplineRope", (0.3, 0.3, 1))
