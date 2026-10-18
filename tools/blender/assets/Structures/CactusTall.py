# CactusTall — 3 x 16 x 3. A saguaro: ribbed trunk with two upturned arms (fruit can sit on top).
import math


def build():
    trunk = lathe([(1.0, 0), (1.05, 8), (0.95, 14), (0.6, 15.6), (0.1, 16)], segments=8, name="trunk")
    paint(trunk, "Cactus")
    paint(trunk, "CactusDark", faces={c * 4 + i for c in range(0, 8, 2) for i in range(4)})
    parts = [trunk]
    for side, h, up in ((-1, 6.5, 4.0), (1, 9.0, 3.0)):
        parts.append(cyl(0.45, 1.2, location=(side * 1.0, 0, h), segments=8, color="Cactus", rotation=(0, side * math.pi / 2, 0)))
        parts.append(cyl(0.45, up, location=(side * 1.3, 0, h + up / 2), segments=8, color="CactusDark"))
        parts.append(ico(0.45, location=(side * 1.3, 0, h + up), subdiv=1, color="Cactus"))
    return finalize(parts, "CactusTall", (3.5, 16, 2.1))
