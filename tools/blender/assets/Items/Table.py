# Table — 5 x 3 x 3 studs. Plank table top on four square legs with a stretcher.


def build():
    parts = [box((5, 3, 0.3), location=(0, 0, 2.85), bevel=0.05, color="WoodLight")]
    for i, x in enumerate((-1.6, -0.55, 0.55, 1.6)):
        parts.append(box((1.0, 3.0, 0.02), location=(x, 0, 3.0), color="WoodMid" if i % 2 else "WoodLight"))
    for x in (-2.15, 2.15):
        for y in (-1.15, 1.15):
            parts.append(box((0.32, 0.32, 2.7), location=(x, y, 1.35), color="WoodMid"))
    parts.append(box((4.3, 0.18, 0.25), location=(0, 0, 0.6), color="WoodDark"))
    return finalize(parts, "Table", (5, 3, 3))
