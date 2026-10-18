# Safe — 4 x 5 x 4. A heavy iron safe on feet: dial, handle, brass hinges.
import math


def build():
    parts = [
        box((4, 4, 4.4), location=(0, 0, 2.8), bevel=0.15, color="MetalDark"),
        box((3.2, 0.2, 3.6), location=(0, -2.05, 2.8), bevel=0.05, color="Iron"),
        cyl(0.55, 0.2, location=(0.6, -2.2, 3.4), segments=12, color="MetalLight", rotation=(1.5708, 0, 0)),
        cyl(0.15, 0.25, location=(0.6, -2.3, 3.4), segments=6, color="Ink", rotation=(1.5708, 0, 0)),
        box((1.2, 0.3, 0.2), location=(0.6, -2.25, 2.3), color="Brass"),
        box((0.3, 0.3, 0.8), location=(-1.55, -2.1, 3.8), color="Brass"),
        box((0.3, 0.3, 0.8), location=(-1.55, -2.1, 1.8), color="Brass"),
        box((2.0, 0.1, 0.6), location=(0, -2.12, 4.3), color="Glow"),
    ]
    for x in (-1.6, 1.6):
        for y in (-1.6, 1.6):
            parts.append(box((0.6, 0.6, 0.6), location=(x, y, 0.3), color="Iron"))
    return finalize(parts, "Safe", (4, 5, 4))
