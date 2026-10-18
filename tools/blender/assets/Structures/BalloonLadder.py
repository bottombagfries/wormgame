# BalloonLadder — 2 x 80 x 0.5. A long rope ladder (the game stretches it a little to reach the ground).


def build():
    parts = []
    for x in (-0.9, 0.9):
        parts.append(box((0.15, 0.15, 80), location=(x, 0, 40), color="Cloth"))
    for k in range(53):
        parts.append(box((1.9, 0.4, 0.15), location=(0, 0, 0.6 + k * 1.5), color="WoodMid"))
    return finalize(parts, "BalloonLadder", (2, 80, 0.4))
