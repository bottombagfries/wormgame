# Dandylion — 1 x 1 x 1 (thrown, it rolls until it lands). A yellow flower head with a green collar.
import math


def build():
    parts = [ico(0.28, location=(0, 0, 0.5), subdiv=1, color="Brass")]
    for k in range(8):
        a = k * 2 * math.pi / 8
        parts.append(box((0.42, 0.18, 0.08), location=(math.cos(a) * 0.32, math.sin(a) * 0.32, 0.55), rotation=(0, 0.25, a), color="Glow"))
    parts.append(cone(0.3, 0.08, 0.3, location=(0, 0, 0.25), segments=6, color="Cactus"))
    parts.append(cyl(0.04, 0.3, location=(0, 0, 0.05), segments=4, color="CactusDark"))
    return finalize(parts, "Dandylion", (1, 1, 1))
