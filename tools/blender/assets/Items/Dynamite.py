# Dynamite — 0.8 x 2 x 0.8 studs. Three red sticks tied with a paper band, a bent fuse with a spark.
import math


def build():
    parts = []
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.3
        parts.append(cyl(0.19, 1.7, location=(math.cos(a) * 0.2, math.sin(a) * 0.2, 0.85), segments=8, color="Red"))
    parts.append(cyl(0.4, 0.28, location=(0, 0, 0.85), segments=10, color="Paper"))
    parts.append(cyl(0.035, 0.42, location=(0.05, 0, 1.88), segments=5, color="Ink", rotation=(0, 0.35, 0)))
    parts.append(ico(0.06, location=(0.13, 0, 2.03), subdiv=1, color="Fire"))
    return finalize(parts, "Dynamite", (0.8, 2.0, 0.8))
