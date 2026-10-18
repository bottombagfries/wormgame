# Chair — 2 x 3.5 x 2 studs. Ladder-back chair.


def build():
    parts = [box((2, 2, 0.25), location=(0, 0, 1.6), bevel=0.04, color="WoodLight")]
    for x in (-0.85, 0.85):
        parts.append(box((0.22, 0.22, 1.5), location=(x, -0.85, 0.75), color="WoodMid"))
        parts.append(box((0.22, 0.22, 3.5), location=(x, 0.85, 1.75), color="WoodMid"))
    for z in (2.35, 2.85, 3.3):
        parts.append(box((1.5, 0.12, 0.22), location=(0, 0.85, z), color="WoodDark"))
    return finalize(parts, "Chair", (2, 3.5, 2))
