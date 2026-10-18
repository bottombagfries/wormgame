# Pulpit — 2.5 x 4 x 2 studs. Tall lectern: panelled box, slanted book rest, small cross on the front.


def build():
    parts = [
        box((2.5, 2.0, 0.3), location=(0, 0, 0.15), bevel=0.04, color="WoodDark"),
        box((2.0, 1.6, 3.0), location=(0, 0, 1.8), bevel=0.04, color="WoodMid"),
        box((2.3, 1.7, 0.2), location=(0, 0.05, 3.5), rotation=(-0.3, 0, 0), bevel=0.03, color="WoodDark"),
        box((1.3, 0.06, 1.6), location=(0, -0.82, 1.8), color="WoodLight"),
        box((0.14, 0.06, 0.8), location=(0, -0.86, 1.9), color="Brass"),
        box((0.5, 0.06, 0.14), location=(0, -0.86, 2.05), color="Brass"),
    ]
    return finalize(parts, "Pulpit", (2.5, 4, 2))
