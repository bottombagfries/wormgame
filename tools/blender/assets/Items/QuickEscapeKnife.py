# QuickEscapeKnife — 0.3 x 0.5 x 2 studs. A bowie knife lying flat: steel blade, brass guard, wood grip.
import math


def build():
    parts = [
        box((0.08, 1.1, 0.38), location=(0, -0.42, 0.25), color="MetalLight"),
        box((0.06, 0.25, 0.2), location=(0, -1.0, 0.33), rotation=(0.6, 0, 0), color="MetalLight"),
        box((0.22, 0.08, 0.5), location=(0, 0.17, 0.25), color="Brass"),
        box((0.2, 0.7, 0.25), location=(0, 0.55, 0.25), bevel=0.04, color="WoodDark"),
        box((0.22, 0.08, 0.28), location=(0, 0.92, 0.25), color="Brass"),
    ]
    return finalize(parts, "QuickEscapeKnife", (0.22, 0.5, 2))
