# Pew — 7 x 3 x 2 studs. Church bench: seat, tall backrest, carved end panels.


def build():
    parts = [
        box((6.6, 1.4, 0.25), location=(0, -0.15, 1.2), bevel=0.03, color="WoodMid"),
        box((6.6, 0.22, 1.6), location=(0, 0.75, 2.15), bevel=0.03, color="WoodMid"),
        box((6.6, 0.14, 0.3), location=(0, 0.8, 2.85), bevel=0.02, color="WoodDark"),
    ]
    for x in (-3.4, 3.4):
        parts.append(box((0.2, 2.0, 2.0), location=(x, 0, 1.0), bevel=0.03, color="WoodDark"))
        parts.append(box((0.24, 1.0, 1.0), location=(x, 0.5, 2.4), bevel=0.03, color="WoodDark"))
    return finalize(parts, "Pew", (7, 3, 2))
