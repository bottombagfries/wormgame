# Gramophone — 2 x 3 x 2 studs. Wooden box, turntable, and a big brass horn.
import math


def build():
    parts = [
        box((1.8, 1.8, 0.9), location=(0, 0, 0.45), bevel=0.04, color="WoodMid"),
        box((1.9, 1.9, 0.1), location=(0, 0, 0.95), color="WoodDark"),
        cyl(0.75, 0.06, location=(0, 0, 1.03), segments=12, color="Iron"),
        cyl(0.06, 1.0, location=(0.45, 0.45, 1.45), segments=6, color="Brass", rotation=(0, -0.3, 0)),
    ]
    horn = lathe([(0.08, 0), (0.15, 0.5), (0.35, 0.95), (0.85, 1.2)], segments=12, cap_bottom=True, cap_top=False, name="horn")
    horn.rotation_euler = (0, -0.55, math.pi / 4)
    horn.location = (0.25, 0.25, 1.75)
    paint(horn, "Brass")
    parts.append(horn)
    return finalize(parts, "Gramophone", (2, 3, 2))
