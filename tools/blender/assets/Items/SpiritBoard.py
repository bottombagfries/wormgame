# SpiritBoard — 2.5 x 0.3 x 1.8 studs. A worn wooden spirit board: sun and moon, letter rows, and a pointer.


def build():
    parts = [
        box((2.5, 1.8, 0.15), location=(0, 0, 0.075), bevel=0.04, color="WoodLight"),
        box((2.3, 1.6, 0.02), location=(0, 0, 0.16), color="Paper"),
        cyl(0.18, 0.03, location=(-0.9, 0.55, 0.18), segments=8, color="Glow"),
        cyl(0.16, 0.03, location=(0.9, 0.55, 0.18), segments=8, color="Purple"),
    ]
    for row, y in enumerate((0.15, -0.2)):
        for k in range(8):
            parts.append(box((0.1, 0.14, 0.02), location=(-0.75 + k * 0.215 + row * 0.1, y, 0.18), color="Ink"))
    pointer = cone(0.32, 0.12, 0.08, location=(0.3, -0.5, 0.24), segments=3, color="WoodDark")
    hole = cyl(0.08, 0.1, location=(0.3, -0.5, 0.26), segments=6, color="Glass")
    return finalize(parts + [pointer, hole], "SpiritBoard", (2.5, 0.3, 1.8))
