# TrainKeyhole — 1.5 x 3 x 1.5. An iron post with a big brass keyhole plate.


def build():
    parts = [
        box((1.5, 1.5, 0.4), location=(0, 0, 0.2), color="Iron"),
        box((1.0, 1.0, 2.6), location=(0, 0, 1.6), bevel=0.05, color="MetalDark"),
        box((0.9, 0.1, 1.2), location=(0, -0.53, 2.1), color="Brass"),
        cyl(0.18, 0.12, location=(0, -0.6, 2.3), segments=8, color="Ink", rotation=(1.5708, 0, 0)),
        box((0.14, 0.12, 0.45), location=(0, -0.6, 2.0), color="Ink"),
    ]
    return finalize(parts, "TrainKeyhole", (1.5, 3, 1.5))
