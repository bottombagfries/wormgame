# DeadBook — 1.5 x 0.5 x 2 studs. A heavy black tome with bone clasps and a red eye on the cover.


def build():
    parts = [
        box((1.5, 2, 0.5), location=(0, 0, 0.25), bevel=0.04, color="Ink"),
        box((1.38, 1.9, 0.38), location=(0.07, 0, 0.25), color="Paper"),
        box((0.2, 2.02, 0.52), location=(-0.66, 0, 0.25), color="Iron"),
        cyl(0.2, 0.04, location=(0.1, 0.1, 0.51), segments=8, color="Red"),
        box((0.9, 0.08, 0.04), location=(0.1, -0.45, 0.51), color="Bone"),
        box((0.14, 0.3, 0.54), location=(0.72, 0.6, 0.25), color="Bone"),
        box((0.14, 0.3, 0.54), location=(0.72, -0.6, 0.25), color="Bone"),
    ]
    return finalize(parts, "DeadBook", (1.5, 0.5, 2))
