# HeartJar — 1.2 x 1.8 x 1.2 studs. A glass jar with a cork lid and a red heart inside.


def build():
    jar = lathe([(0.5, 0.0), (0.6, 0.15), (0.6, 1.25), (0.45, 1.45), (0.42, 1.5)], segments=10, name="jar")
    paint(jar, "Glass")
    cork = cyl(0.4, 0.3, location=(0, 0, 1.65), segments=10, color="WoodLight")
    band = torus(0.6, 0.04, location=(0, 0, 1.05), major_seg=10, minor_seg=3, color="WoodDark")
    heart = []
    for x in (-0.15, 0.15):
        heart.append(ico(0.22, location=(x, -0.4, 0.85), subdiv=1, color="Red"))
    heart.append(cone(0.3, 0.02, 0.4, location=(0, -0.4, 0.55), segments=6, color="Red", rotation=(3.1416, 0, 0)))
    return finalize([jar, cork, band] + heart, "HeartJar", (1.2, 1.8, 1.2))
