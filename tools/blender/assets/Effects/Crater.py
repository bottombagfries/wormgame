# Crater — 18 x 0.2 x 18 (the game sets its width). Scorched sand: a dark burn with a lighter cracked rim.
import math


def build():
    parts = [cyl(9, 0.05, location=(0, 0, 0.025), segments=16, color="SandDark"),
             cyl(7, 0.08, location=(0, 0, 0.06), segments=14, color="WoodDark"),
             cyl(4.5, 0.1, location=(0, 0, 0.1), segments=12, color="Coal")]
    for k in range(10):
        a = k * 2 * math.pi / 10 + 0.2
        parts.append(box((3.2, 0.5, 0.15), location=(math.cos(a) * 6.5, math.sin(a) * 6.5, 0.12), rotation=(0, 0, a), color="CoalHighlight"))
    return finalize(parts, "Crater", (18, 0.2, 18))
