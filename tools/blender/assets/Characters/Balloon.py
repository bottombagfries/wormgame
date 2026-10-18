# Balloon — 20 x 30 x 20. A striped hot-air balloon with ropes, a wicker basket and its pilot.
import math


def build():
    env = lathe([(0.5, 9), (3, 9.5), (6.5, 12), (9.5, 17), (10, 21), (9, 25.5), (6, 28.5), (2.5, 29.8), (0.3, 30)], segments=16, name="envelope")
    rows = 8
    paint(env, "Cloth")
    paint(env, "Red", faces={c * rows + i for c in range(0, 16, 2) for i in range(rows)})
    parts = [env,
             box((4, 4, 2.6), location=(0, 0, 1.3), bevel=0.15, color="WoodLight"),
             box((4.2, 4.2, 0.4), location=(0, 0, 2.6), color="WoodDark")]
    for x in (-1.8, 1.8):
        for y in (-1.8, 1.8):
            top = (x * 0.25 * 4 / 1.8, y * 0.25 * 4 / 1.8)
            length = math.dist((x, y, 2.6), (top[0] * 1.0, top[1] * 1.0, 9.2))
            mid = ((x + top[0]) / 2, (y + top[1]) / 2, (2.6 + 9.2) / 2)
            dx, dy, dz = top[0] - x, top[1] - y, 9.2 - 2.6
            rope = cyl(0.06, length, location=mid, segments=4, color="WoodDark",
                       rotation=(-math.atan2(dy, dz), math.atan2(dx, math.hypot(dy, dz)), 0))
            parts.append(rope)
    parts.append(cyl(0.6, 1.2, location=(0, 0, 8.4), segments=8, color="Iron"))
    parts.append(ico(0.4, location=(0, 0, 7.6), subdiv=1, color="Fire"))
    parts.append(box((0.9, 0.6, 1.4), location=(0.6, -0.5, 3.4), color="Teal"))
    parts.append(ico(0.42, location=(0.6, -0.5, 4.5), subdiv=1, color="Flesh"))
    parts.append(cyl(0.7, 0.08, location=(0.6, -0.5, 4.75), segments=10, color="WoodDark"))
    parts.append(cyl(0.38, 0.4, location=(0.6, -0.5, 4.95), segments=10, color="WoodDark"))
    return finalize(parts, "Balloon", (20, 30, 20))
