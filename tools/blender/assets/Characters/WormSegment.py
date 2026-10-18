# WormSegment — 9 x 9 x 9. One ringed body segment: fleshy core, an armor band over the back, side nubs.
import math


def build():
    body = ico(4.3, location=(0, 0, 4.5), subdiv=2, name="body")
    jitter(body, 0.1, seed=42)
    paint(body, "Flesh")
    paint(body, "FleshDark", faces={i for i in range(len(body.data.polygons)) if i % 6 == 0})
    parts = [body]
    for k in range(4):
        a = -0.75 + k * 0.5
        parts.append(box((3.0, 3.4, 0.6), location=(math.sin(a) * 4.1, 0, 4.5 + math.cos(a) * 4.1), rotation=(0, a, 0), bevel=0.2, color="SandDark" if k % 2 else "Rust"))
    parts.append(torus(4.3, 0.25, location=(0, 0, 4.5), major_seg=12, minor_seg=4, color="FleshDark", rotation=(math.pi / 2, 0, 0)))
    for x in (-1, 1):
        parts.append(cone(0.6, 0.05, 0.9, location=(x * 4.4, 0, 3.6), segments=5, color="Bone", rotation=(0, x * math.pi / 2, 0)))
    return finalize(parts, "WormSegment", (9, 9, 9))
