# Cattlebug — 3 x 2.5 x 5. A placid purple beetle with a domed shell, stubby horns and six legs; faces front.
import math


def build():
    shell = ico(1, location=(0, 0.4, 1.35), subdiv=2, name="shell")
    shell.scale = (1.35, 1.9, 0.95)
    paint(shell, "Purple")
    paint(shell, "Ink", faces={i for i in range(len(shell.data.polygons)) if i % 8 == 0})
    parts = [shell,
             box((0.08, 3.6, 0.2), location=(0, 0.4, 2.25), color="Ink"),
             ico(0.75, location=(0, -1.75, 1.0), subdiv=1, color="TealDark")]
    for x in (-0.4, 0.4):
        parts.append(cone(0.15, 0.02, 0.8, location=(x, -2.3, 1.5), segments=4, color="Bone", rotation=(-0.9, x, 0)))
        parts.append(ico(0.14, location=(x * 0.9, -2.35, 1.15), subdiv=1, color="Glow"))
    for side in (-1, 1):
        for k, y in enumerate((-0.9, 0.3, 1.5)):
            parts.append(cyl(0.12, 1.4, location=(side * 1.35, y, 0.55), segments=4, color="Ink", rotation=(0, side * 0.7, 0)))
    return finalize(parts, "Cattlebug", (3.8, 2.5, 5))
