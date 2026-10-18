# Tornado — 40 x 60 x 40 (Sandstorm's radius 20, height 60). A twisting funnel of sand (semi-transparent in Studio).
import math


def build():
    funnel = lathe([(3, 0), (5, 6), (7, 15), (10, 27), (14, 40), (18, 52), (20, 60)], segments=14, cap_bottom=True, cap_top=False, name="funnel")
    for v in funnel.data.vertices:
        twist = v.co.z * 0.03
        x, y = v.co.x, v.co.y
        v.co.x, v.co.y = x * math.cos(twist) - y * math.sin(twist), x * math.sin(twist) + y * math.cos(twist)
    paint(funnel, "SandLight")
    rows = 6
    paint(funnel, "SandDark", faces={c * rows + i for c in range(14) for i in range(rows) if (c + i) % 3 == 0})
    return finalize([funnel], "Tornado", (40, 60, 40))
