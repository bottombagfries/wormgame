# WormHead — 10 x 10 x 10. A burrowing sand-worm head: armored brow plates, round toothy maw at the
# front (Roblox -Z), fleshy throat. One mesh (welded to the physics root by WormService).
import math


def build():
    parts = []
    head = ico(4.6, location=(0, 0.3, 5), subdiv=2, name="head")
    head.scale = (1.0, 1.05, 0.95)
    jitter(head, 0.12, seed=41)
    paint(head, "Flesh")
    paint(head, "FleshDark", faces={i for i in range(len(head.data.polygons)) if i % 7 == 0})
    parts.append(head)
    for k in range(5):
        a = -0.9 + k * 0.45
        plate = box((3.2, 4.2, 0.7), location=(math.sin(a) * 3.9, 0.8, 5 + math.cos(a) * 3.9), rotation=(0, a, 0), bevel=0.2, color="SandDark" if k % 2 else "Rust")
        parts.append(plate)
    parts.append(cyl(3.3, 0.6, location=(0, -4.1, 4.8), segments=12, color="FleshDark", rotation=(math.pi / 2, 0, 0)))
    parts.append(cyl(2.4, 0.7, location=(0, -4.35, 4.8), segments=12, color="Ink", rotation=(math.pi / 2, 0, 0)))
    for k in range(10):
        a = k * 2 * math.pi / 10
        parts.append(cone(0.45, 0.02, 1.3, location=(math.cos(a) * 2.6, -4.6, 4.8 + math.sin(a) * 2.6), segments=4, color="Bone",
                          rotation=(math.pi / 2, 0, 0)))
    for x in (-2.4, 2.4):
        parts.append(ico(0.45, location=(x, -3.3, 7.6), subdiv=1, color="Glow"))
    return finalize(parts, "WormHead", (10, 10, 10))
