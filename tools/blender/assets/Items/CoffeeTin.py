# CoffeeTin — 1 x 1.3 x 1 studs. A red tin of coffee beans with a gold band and pry-off lid.


def build():
    parts = [
        cyl(0.5, 1.15, location=(0, 0, 0.58), segments=12, color="Red"),
        cyl(0.51, 0.35, location=(0, 0, 0.6), segments=12, color="Brass"),
        cyl(0.52, 0.12, location=(0, 0, 1.22), segments=12, color="MetalLight"),
        box((0.3, 0.06, 0.2), location=(0, -0.51, 0.6), color="WoodDark"),
    ]
    return finalize(parts, "CoffeeTin", (1, 1.3, 1))
