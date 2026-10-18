# TrainKey — 3 x 0.6 x 1.2 studs. A huge brass skeleton key: ring bow, long shaft, toothed bit.
import math


def build():
    parts = [
        torus(0.42, 0.13, location=(-1.05, 0, 0.3), major_seg=12, minor_seg=5, color="Brass"),
        cyl(0.13, 1.9, location=(0.45, 0, 0.3), segments=8, color="Brass", rotation=(0, math.pi / 2, 0)),
        cyl(0.2, 0.2, location=(-0.45, 0, 0.3), segments=8, color="Copper", rotation=(0, math.pi / 2, 0)),
        box((0.55, 0.16, 0.5), location=(1.15, 0.2, 0.3), color="Brass"),
        box((0.18, 0.16, 0.3), location=(1.0, 0.45, 0.3), color="Brass"),
        box((0.18, 0.16, 0.3), location=(1.32, 0.45, 0.3), color="Brass"),
    ]
    return finalize(parts, "TrainKey", (3, 0.5, 1.2))
