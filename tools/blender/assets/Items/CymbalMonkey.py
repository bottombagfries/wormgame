# CymbalMonkey — 1.2 x 1.6 x 1.2 studs. A wind-up tin toy critter holding two brass cymbals.
import math


def build():
    parts = [
        cyl(0.38, 0.65, location=(0, 0, 0.55), segments=10, color="Red"),
        cyl(0.4, 0.15, location=(0, 0, 0.2), segments=10, color="Brass"),
        ico(0.33, location=(0, 0, 1.15), subdiv=1, color="Flesh"),
        ico(0.14, location=(0, -0.28, 1.1), subdiv=1, color="Bone"),
        ico(0.12, location=(-0.3, 0, 1.38), subdiv=1, color="FleshDark"),
        ico(0.12, location=(0.3, 0, 1.38), subdiv=1, color="FleshDark"),
        cyl(0.25, 0.04, location=(-0.52, -0.15, 0.7), segments=10, color="Brass", rotation=(0, math.pi / 2, 0)),
        cyl(0.25, 0.04, location=(0.52, -0.15, 0.7), segments=10, color="Brass", rotation=(0, math.pi / 2, 0)),
        box((0.9, 0.12, 0.12), location=(0, -0.1, 0.75), color="Flesh"),
        cyl(0.04, 0.25, location=(0, 0.42, 0.6), segments=4, color="Brass", rotation=(math.pi / 2, 0, 0)),
        box((0.3, 0.04, 0.08), location=(0, 0.55, 0.6), color="Brass"),
    ]
    return finalize(parts, "CymbalMonkey", (1.2, 1.6, 1))
