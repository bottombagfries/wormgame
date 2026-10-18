# Lantern — 0.8 x 1.5 x 0.8 studs. Iron frame, glowing glass chimney, brass cap, carry handle.
import math


def build():
    parts = [
        box((0.8, 0.8, 0.14), location=(0, 0, 0.07), bevel=0.02, color="Iron"),
        cyl(0.27, 0.72, location=(0, 0, 0.5), segments=8, color="Glow"),
    ]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box((0.07, 0.07, 0.78), location=(sx * 0.31, sy * 0.31, 0.53), color="Iron"))
    parts.append(cone(0.42, 0.12, 0.3, location=(0, 0, 1.05), segments=8, color="Iron"))
    parts.append(cyl(0.12, 0.08, location=(0, 0, 1.24), segments=8, color="Brass"))
    parts.append(
        torus(0.2, 0.035, location=(0, 0, 1.3), major_seg=10, minor_seg=4, color="Iron", rotation=(math.pi / 2, 0, 0))
    )
    return finalize(parts, "Lantern", (0.8, 1.5, 0.8))
