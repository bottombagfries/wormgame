# TrainLever — 1 x 4 x 1. A floor quadrant with a tall iron lever and red grip.


def build():
    parts = [
        box((1, 1, 0.5), location=(0, 0, 0.25), color="MetalDark"),
        box((0.3, 0.9, 0.6), location=(0, 0, 0.7), color="Brass"),
        cyl(0.1, 3.0, location=(0, 0.15, 2.0), segments=6, color="Iron", rotation=(0.12, 0, 0)),
        cyl(0.22, 0.6, location=(0, 0.33, 3.6), segments=8, color="Red", rotation=(0.12, 0, 0)),
    ]
    return finalize(parts, "TrainLever", (1, 4, 1))
