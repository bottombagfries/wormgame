# Horseshoe — 1 x 0.3 x 1 studs. Iron U built from short segments.
import math


def build():
    parts = []
    seg = 9
    for k in range(seg):
        a = math.pi * (-0.15 + 1.3 * k / (seg - 1))
        parts.append(box((0.22, 0.26, 0.3), location=(math.cos(a) * 0.38, math.sin(a) * 0.38, 0.15),
                         rotation=(0, 0, a), color="MetalLight" if k % 2 else "MetalDark"))
    return finalize(parts, "Horseshoe", (1, 0.3, 0.85))
