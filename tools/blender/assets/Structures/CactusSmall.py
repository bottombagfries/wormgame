# CactusSmall — 2 x 5 x 2. A squat ribbed barrel cactus with a pink flower on top.


def build():
    body = lathe([(0.7, 0), (0.95, 1.2), (0.95, 3.4), (0.6, 4.5), (0.2, 4.75)], segments=10, name="barrel")
    paint(body, "Cactus")
    paint(body, "CactusDark", faces={c * 4 + i for c in range(0, 10, 2) for i in range(4)})
    flower = ico(0.3, location=(0, 0, 4.8), subdiv=1, color="FruitPink")
    return finalize([body, flower], "CactusSmall", (2, 5, 2))
