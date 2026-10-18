# TrainManual — 1.2 x 0.4 x 1.6 studs. A thick brass-cornered engineer's manual.


def build():
    parts = [
        box((1.2, 1.6, 0.4), location=(0, 0, 0.2), bevel=0.03, color="RedDark"),
        box((1.1, 1.52, 0.3), location=(0.06, 0, 0.2), color="Paper"),
        box((0.6, 0.5, 0.02), location=(0, 0.2, 0.41), color="Brass"),
    ]
    for x in (-0.55, 0.55):
        for y in (-0.75, 0.75):
            parts.append(box((0.14, 0.14, 0.42), location=(x, y, 0.2), color="Brass"))
    return finalize(parts, "TrainManual", (1.2, 0.4, 1.6))
