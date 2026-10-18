# SinkholeZone — a flat 10 x 0.4 x 10 swirl of dark sand (the game scales it to the sinkhole's width).
import math


def build():
    parts = [cyl(5, 0.1, location=(0, 0, 0.05), segments=16, color="SandDark"),
             cyl(1.4, 0.4, location=(0, 0, 0.2), segments=10, color="Ink")]
    for ring in range(3):
        r = 1.8 + ring * 1.0
        for k in range(8):
            a = k * 2 * math.pi / 8 + ring * 0.4
            parts.append(box((1.6, 0.35, 0.12), location=(math.cos(a) * r, math.sin(a) * r, 0.15), rotation=(0, 0, a + 1.2), color="WoodDark" if ring % 2 else "WoodMid"))
    return finalize(parts, "SinkholeZone", (10, 0.4, 10))
