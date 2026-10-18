# Chest — 3 x 2 x 2 studs. Banded treasure chest with a rounded lid and brass lock.
import math


def build():
    parts = [box((3, 2, 1.2), location=(0, 0, 0.6), bevel=0.04, color="WoodMid")]
    lid = cyl(1.0, 3.0, location=(0, 0, 1.2), segments=12, color="WoodLight", rotation=(0, math.pi / 2, 0), name="lid")
    parts.append(lid)
    for x in (-1.2, 0, 1.2):
        parts.append(box((0.18, 2.06, 1.24), location=(x, 0, 0.6), color="Iron"))
        parts.append(torus(1.0, 0.07, location=(x, 0, 1.2), major_seg=12, minor_seg=3, color="Iron", rotation=(0, math.pi / 2, 0)))
    parts.append(box((0.4, 0.12, 0.45), location=(0, -1.04, 1.05), color="Brass"))
    return finalize(parts, "Chest", (3, 2, 2))
