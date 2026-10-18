# Ghost — 2.5 x 2.5 x 2.5. A floating sheet ghost with a wavy hem and two dark eyes (front = Roblox -Z).
import math


def build():
    body = lathe([(0.9, 0.0), (1.2, 0.25), (1.15, 1.2), (0.9, 1.9), (0.45, 2.35), (0.05, 2.5)], segments=12, cap_bottom=False, name="sheet")
    for v in body.data.vertices:
        if v.co.z < 0.05:
            a = math.atan2(v.co.y, v.co.x)
            v.co.z += 0.18 * (1 + math.sin(a * 6))
    paint(body, "Bone")
    parts = [body]
    for x in (-0.35, 0.35):
        parts.append(box((0.25, 0.1, 0.4), location=(x, -1.02, 1.75), rotation=(0.35, 0, 0), color="Ink"))
    return finalize(parts, "Ghost", (2.5, 2.5, 2.5))
