# TarSpire — 4 x 14 x 4. A jagged black spike of hardened tar with glossy drips.
import math


def build():
    spire = cone(2.0, 0.15, 14, location=(0, 0, 7), segments=6, color="Iron", name="spire")
    jitter(spire, 0.15, seed=71)
    parts = [spire]
    for k in range(5):
        a = k * 2 * math.pi / 5
        parts.append(cone(0.5, 0.05, 3.5, location=(math.cos(a) * 1.5, math.sin(a) * 1.5, 1.5), segments=5, color="Coal",
                          rotation=(-math.sin(a) * 0.4, math.cos(a) * 0.4, 0)))
        parts.append(ico(0.3, location=(math.cos(a) * 1.2, math.sin(a) * 1.2, 4 + k * 1.5), subdiv=1, color="CoalHighlight"))
    return finalize(parts, "TarSpire", (4, 14, 4))
