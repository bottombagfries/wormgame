# DutchOven — 2 x 1.5 x 2 studs. Squat cast-iron pot on stubby legs, lid with a loop handle.
import math


def build():
    body = lathe([(0.75, 0.15), (0.92, 0.35), (0.95, 0.8), (0.9, 1.05)], segments=12, name="pot")
    paint(body, "Iron")
    parts = [body,
             cyl(0.95, 0.12, location=(0, 0, 1.11), segments=12, color="MetalDark"),
             torus(0.2, 0.05, location=(0, 0, 1.25), major_seg=8, minor_seg=4, color="MetalDark", rotation=(math.pi / 2, 0, 0))]
    for k in range(3):
        a = k * 2 * math.pi / 3
        parts.append(cyl(0.09, 0.2, location=(math.cos(a) * 0.6, math.sin(a) * 0.6, 0.1), segments=6, color="Iron"))
    for side in (-1, 1):
        parts.append(torus(0.12, 0.035, location=(side * 0.92, 0, 0.9), major_seg=8, minor_seg=4, color="MetalDark", rotation=(0, math.pi / 2, 0)))
    return finalize(parts, "DutchOven", (2, 1.5, 2))
