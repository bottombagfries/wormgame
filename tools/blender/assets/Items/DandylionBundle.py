# DandylionBundle — 0.8 x 2 x 0.8 studs. A tied bunch of tall stems with yellow flower heads.
import math


def build():
    parts = [cyl(0.15, 0.25, location=(0, 0, 0.55), segments=6, color="Red")]
    for k in range(5):
        a = k * 2 * math.pi / 5
        tilt = 0.18
        x, y = math.cos(a) * 0.12, math.sin(a) * 0.12
        parts.append(cyl(0.03, 1.5, location=(x, y, 0.75), segments=4, color="Cactus", rotation=(-math.sin(a) * tilt, math.cos(a) * tilt, 0)))
        parts.append(ico(0.17, location=(x + math.cos(a) * 0.13, y + math.sin(a) * 0.13, 1.6 + (k % 2) * 0.15), subdiv=1, color="Glow"))
    return finalize(parts, "DandylionBundle", (0.8, 2, 0.8))
