# Shovel — 1 x 0.4 x 5 studs. A long-handled spade lying flat, with a small metal-detector bulb on the shaft.
import math


def build():
    parts = [
        cyl(0.09, 3.5, location=(0, 0.6, 0.2), segments=6, color="WoodLight", rotation=(math.pi / 2, 0, 0)),
        box((0.7, 0.14, 0.14), location=(0, 2.4, 0.2), color="WoodDark"),
        box((0.9, 1.5, 0.08), location=(0, -1.75, 0.15), bevel=0.02, color="MetalLight"),
        cyl(0.11, 0.3, location=(0, -1.1, 0.2), segments=6, color="MetalDark", rotation=(math.pi / 2, 0, 0)),
        ico(0.12, location=(0, 0.2, 0.33), subdiv=1, color="Glow"),
        box((0.14, 0.2, 0.06), location=(0, 0.2, 0.22), color="Brass"),
    ]
    return finalize(parts, "Shovel", (1, 0.4, 5))
