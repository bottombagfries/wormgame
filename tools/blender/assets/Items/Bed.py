# Bed — 4 x 2 x 7 studs. Wooden frame, mattress, pillow and a folded blanket; tall headboard.


def build():
    parts = [
        box((4, 7, 0.5), location=(0, 0, 0.6), bevel=0.04, color="WoodMid"),
        box((3.7, 6.5, 0.55), location=(0, 0.1, 1.1), bevel=0.08, color="Cloth"),
        box((2.6, 1.0, 0.35), location=(0, 2.6, 1.5), bevel=0.12, color="Bone"),
        box((3.8, 3.2, 0.2), location=(0, -1.6, 1.42), bevel=0.05, color="Red"),
        box((4, 0.3, 2.0), location=(0, 3.35, 1.0), bevel=0.04, color="WoodDark"),
        box((4, 0.3, 1.2), location=(0, -3.35, 0.6), bevel=0.04, color="WoodDark"),
    ]
    return finalize(parts, "Bed", (4, 2, 7))
