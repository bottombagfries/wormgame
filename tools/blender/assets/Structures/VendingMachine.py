# VendingMachine — 4 x 7 x 3. An old red-and-brass supply dispenser with a window of maps and flowers.


def build():
    parts = [
        box((4, 3, 6.4), location=(0, 0, 3.4), bevel=0.15, color="Red"),
        box((4.2, 3.2, 0.4), location=(0, 0, 0.2), color="Iron"),
        box((4.2, 3.2, 0.6), location=(0, 0, 6.7), bevel=0.1, color="Brass"),
        box((2.8, 0.1, 2.8), location=(-0.3, -1.52, 4.2), color="Glass"),
        box((0.6, 0.12, 1.4), location=(1.5, -1.52, 4.2), color="Brass"),
        cyl(0.12, 0.15, location=(1.5, -1.6, 4.5), segments=6, color="Ink", rotation=(1.5708, 0, 0)),
        box((2.4, 0.2, 0.9), location=(0, -1.55, 1.4), color="Iron"),
        box((3.4, 0.12, 0.8), location=(0, -1.55, 6.1), color="Paper"),
    ]
    for k in range(3):
        parts.append(box((0.6, 0.1, 0.5), location=(-1.2 + k * 0.9, -1.45, 4.9), color="Paper"))
        parts.append(ico(0.22, location=(-1.2 + k * 0.9, -1.45, 3.6), subdiv=1, color="Glow"))
    return finalize(parts, "VendingMachine", (4, 7, 3))
