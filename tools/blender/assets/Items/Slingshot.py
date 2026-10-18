# Slingshot — 1.2 x 1.8 x 0.4 studs. Forked branch with a leather pouch on the band.
import math


def build():
    parts = [
        cyl(0.11, 0.9, location=(0, 0, 0.45), segments=6, color="WoodMid"),
        cyl(0.09, 1.0, location=(-0.3, 0, 1.25), segments=6, color="WoodMid", rotation=(0, -0.55, 0)),
        cyl(0.09, 1.0, location=(0.3, 0, 1.25), segments=6, color="WoodMid", rotation=(0, 0.55, 0)),
        box((0.22, 0.24, 0.3), location=(0, 0, 0.4), color="WoodDark"),
        box((1.0, 0.04, 0.04), location=(0, -0.05, 1.68), color="Ink"),
        box((0.28, 0.1, 0.18), location=(0, -0.12, 1.66), color="WoodDark"),
    ]
    return finalize(parts, "Slingshot", (1.2, 1.8, 0.3))
