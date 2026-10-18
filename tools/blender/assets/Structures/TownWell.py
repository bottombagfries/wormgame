# TownWell — 8 x 6 x 8. A round stone well with a little shingled roof, crank and bucket.
import math


def build():
    ring, roof, detail = [], [], []
    for k in range(12):
        a = k * 2 * math.pi / 12
        ring.append(box((2.2, 1.2, 2.4), location=(math.cos(a) * 3.0, math.sin(a) * 3.0, 1.2), rotation=(0, 0, a + math.pi / 2), color="MetalLight" if k % 2 else "MetalDark"))
    detail.append(cyl(2.5, 0.2, location=(0, 0, 1.6), segments=12, color="Teal"))
    for x in (-3.0, 3.0):
        detail.append(box((0.5, 0.5, 4.5), location=(x, 0, 3.5), color="WoodDark"))
    roof.extend(gable(6.5, 4, 1.5, location=(0, 0, 5.0), overhang=0.75, thickness=0.3, color="WoodMid"))
    detail.append(cyl(0.2, 6.2, location=(0, 0, 4.4), segments=6, color="WoodLight", rotation=(0, 1.5708, 0)))
    detail.append(box((0.2, 1.0, 0.2), location=(3.3, 0.4, 4.4), color="Iron"))
    detail.append(cyl(0.03, 1.4, location=(0, 0, 3.6), segments=4, color="Cloth"))
    b = lathe([(0.35, 2.4), (0.45, 3.0)], segments=8, cap_top=False, name="bucket")
    paint(b, "WoodLight")
    detail.append(b)
    return finalize_group({"Ring": ring, "Roof": roof, "Detail": detail}, "TownWell", (8, 6, 8))
