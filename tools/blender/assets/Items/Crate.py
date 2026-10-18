# Crate — 4 x 4 x 4 studs. Plank crate: dark edge frame on all 12 edges, a diagonal brace on four sides.
import math


def build():
    parts = [box((3.8, 3.8, 3.8), location=(0, 0, 2), color="WoodLight")]
    e = 0.4
    for x in (-1.8, 1.8):
        for y in (-1.8, 1.8):
            parts.append(box((e, e, 4), location=(x, y, 2), color="WoodDark"))
    for z in (0.2, 3.8):
        for y in (-1.8, 1.8):
            parts.append(box((4, e, e), location=(0, y, z), color="WoodDark"))
        for x in (-1.8, 1.8):
            parts.append(box((e, 4, e), location=(x, 0, z), color="WoodDark"))
    d = 3.6 * math.sqrt(2) - 0.4
    for y in (-1.95, 1.95):
        parts.append(box((d, 0.12, 0.35), location=(0, y, 2), rotation=(0, math.pi / 4, 0), color="WoodMid"))
    for x in (-1.95, 1.95):
        parts.append(box((0.12, d, 0.35), location=(x, 0, 2), rotation=(math.pi / 4, 0, 0), color="WoodMid"))
    return finalize(parts, "Crate", (4, 4, 4))
