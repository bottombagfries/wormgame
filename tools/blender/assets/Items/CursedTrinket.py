# CursedTrinket — 1 x 1 x 0.4 studs. A tarnished pocket watch with a purple stone and a short chain.
import math


def build():
    parts = [
        cyl(0.45, 0.25, location=(0, 0, 0.45), segments=12, color="MetalDark", rotation=(math.pi / 2, 0, 0)),
        cyl(0.38, 0.27, location=(0, 0, 0.45), segments=12, color="Bone", rotation=(math.pi / 2, 0, 0)),
        box((0.03, 0.3, 0.25), location=(0, -0.01, 0.55), color="Ink"),
        box((0.18, 0.3, 0.03), location=(0.08, -0.01, 0.45), color="Ink"),
        ico(0.1, location=(0, 0, 0.98), subdiv=1, color="Purple"),
        torus(0.08, 0.025, location=(0, 0, 0.9), major_seg=6, minor_seg=3, color="MetalDark", rotation=(0, math.pi / 2, 0)),
    ]
    return finalize(parts, "CursedTrinket", (1, 1, 0.3))
