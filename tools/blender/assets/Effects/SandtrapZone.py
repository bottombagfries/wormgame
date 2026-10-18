# SandtrapZone — a flat 10 x 0.3 x 10 patch of loose sand with a faint ring pattern.
import math


def build():
    parts = [cyl(5, 0.1, location=(0, 0, 0.05), segments=16, color="SandLight")]
    for r in (1.5, 2.8, 4.1):
        parts.append(torus(r, 0.12, location=(0, 0, 0.15), major_seg=14, minor_seg=3, color="SandDark"))
    return finalize(parts, "SandtrapZone", (10, 0.25, 10))
