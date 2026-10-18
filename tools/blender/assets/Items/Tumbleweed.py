# Tumbleweed — 2.5 x 2.5 x 2.5 studs (it rolls). A tangled ball of dry twigs.
import math


def build():
    parts = []
    core = ico(1.0, location=(0, 0, 1.25), subdiv=1, color="SandDark", name="core")
    jitter(core, 0.12, seed=4)
    parts.append(core)
    for k in range(14):
        a = k * 2.39996
        z = -1 + 2 * (k + 0.5) / 14
        r = math.sqrt(1 - z * z)
        d = (math.cos(a) * r, math.sin(a) * r, z)
        twig = cyl(0.05, 2.2, location=(d[0] * 0.25, d[1] * 0.25, 1.25 + d[2] * 0.25), segments=4,
                   color="WoodLight" if k % 2 else "SandDark", rotation=(math.acos(z), 0, a))
        parts.append(twig)
    ring = torus(1.1, 0.06, location=(0, 0, 1.25), major_seg=12, minor_seg=3, color="WoodMid", rotation=(0.7, 0.3, 0))
    parts.append(ring)
    return finalize(parts, "Tumbleweed", (2.5, 2.5, 2.5))
