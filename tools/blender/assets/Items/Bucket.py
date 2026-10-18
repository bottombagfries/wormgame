# Bucket — 1.2 x 1.4 x 1.2 studs. Tapered wooden pail with iron bands and a wire handle.
import math


def build():
    body = lathe([(0.45, 0.0), (0.58, 1.0)], segments=10, cap_top=False, name="pail")
    paint(body, "WoodLight")
    parts = [body, cyl(0.55, 0.05, location=(0, 0, 0.8), segments=10, color="WoodDark"),
             torus(0.49, 0.035, location=(0, 0, 0.2), major_seg=10, minor_seg=4, color="Iron"),
             torus(0.56, 0.035, location=(0, 0, 0.85), major_seg=10, minor_seg=4, color="Iron"),
             torus(0.55, 0.03, location=(0, 0, 1.0), major_seg=12, minor_seg=4, color="MetalDark", rotation=(math.pi / 2, 0, 0))]
    return finalize(parts, "Bucket", (1.2, 1.4, 1.2))
