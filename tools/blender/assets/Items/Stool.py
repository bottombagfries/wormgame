# Stool — 1.5 x 1.5 x 1.5 studs. Round seat on three splayed legs.
import math


def build():
    parts = [cyl(0.75, 0.2, location=(0, 0, 1.4), segments=10, bevel=0.03, color="WoodLight")]
    for k in range(3):
        a = k * 2 * math.pi / 3
        parts.append(cyl(0.09, 1.4, location=(math.cos(a) * 0.45, math.sin(a) * 0.45, 0.68), segments=6, color="WoodMid",
                         rotation=(math.sin(a) * 0.2, -math.cos(a) * 0.2, 0)))
    parts.append(torus(0.42, 0.04, location=(0, 0, 0.5), major_seg=10, minor_seg=4, color="WoodDark"))
    return finalize(parts, "Stool", (1.5, 1.5, 1.5))
