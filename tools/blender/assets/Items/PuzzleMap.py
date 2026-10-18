# PuzzleMap — 1.5 x 0.2 x 1.2 studs. A rolled-edge paper map with a red X and dotted trail.


def build():
    parts = [
        box((1.3, 1.2, 0.04), location=(0, 0, 0.04), color="Paper"),
        cyl(0.09, 1.2, location=(-0.66, 0, 0.09), segments=6, color="ClothDark", rotation=(1.5708, 0, 0)),
        cyl(0.09, 1.2, location=(0.66, 0, 0.09), segments=6, color="ClothDark", rotation=(1.5708, 0, 0)),
        box((0.3, 0.06, 0.02), location=(0.3, 0.25, 0.07), rotation=(0, 0, 0.785), color="Red"),
        box((0.3, 0.06, 0.02), location=(0.3, 0.25, 0.07), rotation=(0, 0, -0.785), color="Red"),
    ]
    for k in range(5):
        parts.append(box((0.07, 0.07, 0.02), location=(-0.45 + k * 0.15, -0.3 + k * 0.1, 0.07), color="Ink"))
    return finalize(parts, "PuzzleMap", (1.5, 0.2, 1.2))
