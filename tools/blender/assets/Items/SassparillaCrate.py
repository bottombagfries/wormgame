# SassparillaCrate — 3 x 2 x 2 studs. Open slatted crate with six brown bottles standing in it.


def build():
    parts = [box((3, 2, 0.2), location=(0, 0, 0.1), color="WoodMid")]
    for y in (-0.95, 0.95):
        parts.append(box((3, 0.1, 1.0), location=(0, y, 0.6), color="WoodLight"))
    for x in (-1.45, 1.45):
        parts.append(box((0.1, 2, 1.0), location=(x, 0, 0.6), color="WoodLight"))
        parts.append(box((0.1, 1.2, 0.35), location=(x, 0, 1.25), color="WoodDark"))
    for i in range(3):
        for j in range(2):
            x, y = -0.9 + i * 0.9, -0.45 + j * 0.9
            parts.append(cyl(0.28, 1.1, location=(x, y, 0.75), segments=8, color="WoodDark"))
            parts.append(cyl(0.1, 0.45, location=(x, y, 1.5), segments=6, color="WoodDark"))
            parts.append(cyl(0.12, 0.12, location=(x, y, 1.78), segments=6, color="Red"))
            parts.append(cyl(0.29, 0.3, location=(x, y, 0.8), segments=8, color="Paper"))
    return finalize(parts, "SassparillaCrate", (3, 2, 2))
