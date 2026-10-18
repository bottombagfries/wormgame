# LobbyBench — 7 x 2.5 x 2. A station bench: three seat slats, a slatted back, cast-iron ends.


def build():
    parts = []
    for k in range(3):
        parts.append(box((7, 0.42, 0.18), location=(0, -0.6 + k * 0.45, 1.3), color="WoodLight"))
    for k in range(2):
        parts.append(box((7, 0.16, 0.38), location=(0, 0.88, 1.75 + k * 0.5), color="WoodLight"))
    for x in (-3.1, 3.1):
        parts.append(box((0.25, 1.6, 0.2), location=(x, 0, 1.15), color="Iron"))
        parts.append(box((0.25, 0.2, 1.2), location=(x, -0.6, 0.6), color="Iron"))
        parts.append(box((0.25, 0.2, 2.5), location=(x, 0.85, 1.25), color="Iron"))
    return finalize(parts, "LobbyBench", (7, 2.5, 2))
