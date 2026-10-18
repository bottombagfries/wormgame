# TrainFurnace — 6 x 6 x 8. An iron firebox under a rounded boiler hood, open at the front (Roblox -Z) with
# glowing coals; thrown items go in (the game makes it non-colliding).
import math


def build():
    parts = [
        box((6, 8, 0.8), location=(0, 0, 0.4), color="Iron"),
        box((0.8, 8, 3.2), location=(-2.6, 0, 2.4), color="MetalDark"),
        box((0.8, 8, 3.2), location=(2.6, 0, 2.4), color="MetalDark"),
        box((6, 0.8, 3.2), location=(0, 3.6, 2.4), color="MetalDark"),
        box((4.4, 6.4, 0.3), location=(0, 0, 0.95), color="Fire"),
        ico(1.1, location=(0, 0.5, 1.5), subdiv=1, color="Glow"),
        ico(0.8, location=(-1, -0.8, 1.4), subdiv=1, color="Fire"),
        ico(0.7, location=(1.1, -0.5, 1.3), subdiv=1, color="Fire"),
        box((6.2, 0.4, 0.4), location=(0, -3.9, 3.6), color="Brass"),
    ]
    # Rounded hood: a half-cylinder (lathe profile swept along Y) sitting on the walls.
    seg = 8
    for k in range(seg):
        a0, a1 = math.pi * k / seg, math.pi * (k + 1) / seg
        am = (a0 + a1) / 2
        width = 2 * 3.0 * math.sin((a1 - a0) / 2) + 0.05
        parts.append(box((width, 8, 0.5), location=(math.cos(am) * 2.75, 0, 4.0 + math.sin(am) * 1.75),
                         rotation=(0, -(am - math.pi / 2) * 0.6, 0), color="Iron" if k % 2 else "MetalDark"))
    return finalize(parts, "TrainFurnace", (6, 6, 8))
