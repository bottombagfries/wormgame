# PogoStick — 1 x 4 x 1 studs. Red pole, T handlebars, foot pegs, a spring, and a rubber tip.
import math


def build():
    parts = [
        cyl(0.11, 3.0, location=(0, 0, 2.3), segments=8, color="Red"),
        cyl(0.07, 1.0, location=(0, 0, 3.75), segments=6, color="Iron", rotation=(0, math.pi / 2, 0)),
        cyl(0.1, 0.3, location=(-0.45, 0, 3.75), segments=6, color="Ink", rotation=(0, math.pi / 2, 0)),
        cyl(0.1, 0.3, location=(0.45, 0, 3.75), segments=6, color="Ink", rotation=(0, math.pi / 2, 0)),
        box((0.9, 0.3, 0.1), location=(0, 0, 0.95), color="Iron"),
        cyl(0.08, 0.8, location=(0, 0, 0.4), segments=6, color="MetalLight"),
        cyl(0.12, 0.15, location=(0, 0, 0.07), segments=6, color="Ink"),
    ]
    for k in range(5):
        parts.append(torus(0.17, 0.03, location=(0, 0, 1.2 + k * 0.14), major_seg=8, minor_seg=3, color="MetalLight"))
    return finalize(parts, "PogoStick", (1.2, 4, 0.4))
