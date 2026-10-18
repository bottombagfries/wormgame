# DigHole — 5 x 0.2 x 5. A patch of freshly dug, darker sand with a few clumps.
import math


def build():
    parts = [cyl(2.5, 0.06, location=(0, 0, 0.03), segments=12, color="SandDark"),
             cyl(1.6, 0.08, location=(0, 0, 0.06), segments=10, color="WoodMid")]
    for k in range(6):
        a = k * 2 * math.pi / 6
        c = box((0.6, 0.5, 0.2), location=(math.cos(a) * 2.0, math.sin(a) * 2.0, 0.1), rotation=(0, 0, a), color="SandDark")
        parts.append(c)
    return finalize(parts, "DigHole", (5, 0.2, 5))
