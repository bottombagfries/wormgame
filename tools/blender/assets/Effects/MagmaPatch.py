# MagmaPatch — a flat 14 x 0.3 x 14 pool of glowing magma with a dark crust (made Neon in Studio).
import math


def build():
    pool = cyl(7, 0.15, location=(0, 0, 0.075), segments=16, color="Fire", name="pool")
    jitter(pool, 0.1, seed=55)
    parts = [pool]
    for k in range(7):
        a = k * 2 * math.pi / 7
        crust = ico(1.1, location=(math.cos(a) * 4.5, math.sin(a) * 4.5, 0.1), subdiv=1, color="Coal", name="crust")
        crust.scale = (1.3, 0.9, 0.18)
        parts.append(crust)
    parts.append(cyl(2.0, 0.2, location=(0, 0, 0.1), segments=10, color="Glow"))
    return finalize(parts, "MagmaPatch", (14, 0.4, 14))
