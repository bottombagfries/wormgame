# Bench — 5 x 2 x 1.5 studs. Plank bench on splayed legs.


def build():
    parts = [box((5, 1.5, 0.3), location=(0, 0, 1.85), bevel=0.04, color="WoodLight"),
             box((4.2, 0.15, 0.25), location=(0, 0, 0.7), color="WoodDark")]
    for x in (-1.9, 1.9):
        for y in (-0.45, 0.45):
            parts.append(box((0.25, 0.25, 1.75), location=(x, y, 0.85), rotation=(y * 0.25, 0, 0), color="WoodMid"))
    return finalize(parts, "Bench", (5, 2, 1.5))
