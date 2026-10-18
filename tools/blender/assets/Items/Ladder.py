# Ladder — 2.5 x 14 x 0.5 studs. Two rails and 12 rungs.


def build():
    parts = []
    for x in (-1.1, 1.1):
        parts.append(box((0.3, 0.5, 14), location=(x, 0, 7), bevel=0.03, color="WoodMid"))
    for k in range(12):
        parts.append(box((2.0, 0.3, 0.22), location=(0, 0, 0.8 + k * 1.15), color="WoodLight"))
    return finalize(parts, "Ladder", (2.5, 14, 0.5))
