# CactusFruit — 1 x 1 x 1 studs (it rolls). Pink prickly pear with a little green crown.


def build():
    fruit = ico(0.45, location=(0, 0, 0.47), subdiv=2, name="fruit")
    paint(fruit, "FruitPink")
    paint(fruit, "Red", faces={i for i in range(len(fruit.data.polygons)) if i % 9 == 0})
    crown = cone(0.22, 0.05, 0.15, location=(0, 0, 0.95), segments=6, color="Cactus")
    return finalize([fruit, crown], "CactusFruit", (1, 1, 1))
