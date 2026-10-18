# Backpack — 1.5 x 2 x 1 studs. Canvas pack with a flap, front pocket, bedroll on top, straps.


def build():
    parts = [
        box((1.4, 0.8, 1.55), location=(0, 0, 0.78), bevel=0.12, color="ClothDark"),
        box((1.45, 0.85, 0.5), location=(0, -0.02, 1.35), bevel=0.08, color="WoodMid"),
        box((0.9, 0.25, 0.6), location=(0, -0.48, 0.55), bevel=0.06, color="Cloth"),
        cyl(0.22, 1.5, location=(0, 0.05, 1.75), segments=8, color="Red", rotation=(0, 1.5708, 0)),
    ]
    for x in (-0.45, 0.45):
        parts.append(box((0.14, 0.12, 1.5), location=(x, 0.45, 0.85), color="WoodDark"))
    return finalize(parts, "Backpack", (1.5, 2, 1))
