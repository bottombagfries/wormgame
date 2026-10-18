# Stagecoach — 14 x 10 x 8. A red coach on big spoked wheels, driver's bench and a roof rack.
import math


def build():
    body, wheels, detail = [], [], []
    body.append(box((7, 6, 5), location=(0, 0, 5.0), bevel=0.3, color="Red"))
    body.append(box((7.4, 6.4, 0.5), location=(0, 0, 7.7), color="RedDark"))
    body.append(box((3, 5, 1.2), location=(5.0, 0, 3.6), color="WoodDark"))
    body.append(box((1.2, 5, 2), location=(6.2, 0, 5.2), rotation=(0, -0.3, 0), color="WoodDark"))
    for x in (-3.0, 3.0):
        for y in (-3.4, 3.4):
            r = 2.3 if x < 0 else 1.9
            wheels.append(torus(r, 0.18, location=(x, y, r), major_seg=14, minor_seg=4, color="WoodDark", rotation=(1.5708, 0, 0)))
            wheels.append(cyl(0.4, 0.5, location=(x, y, r), segments=8, color="Iron", rotation=(1.5708, 0, 0)))
            for k in range(4):
                a = k * math.pi / 4
                wheels.append(box((2 * r, 0.12, 0.12), location=(x, y, r), rotation=(0, a, 0), color="WoodLight"))
    detail.append(box((6.8, 0.2, 2), location=(0, -3.05, 5.6), color="Glass"))
    detail.append(box((6.8, 0.2, 2), location=(0, 3.05, 5.6), color="Glass"))
    detail.append(box((0.2, 6.6, 0.2), location=(0, 0, 4.0), color="Brass"))
    for x in (-3.0, 3.0):
        detail.append(box((0.3, 6.4, 0.6), location=(x, 0, 8.3), color="Brass"))
    detail.append(box((1.2, 2, 1), location=(-2, 1, 8.5), color="ClothDark"))
    detail.append(box((1.6, 1.4, 1.2), location=(0.5, -1.4, 8.6), color="WoodLight"))
    return finalize_group({"Body": body, "Wheels": wheels, "Detail": detail}, "Stagecoach", (14, 10, 8))
