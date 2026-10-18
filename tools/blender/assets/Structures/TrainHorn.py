# TrainHorn — 2 x 3 x 2. A brass steam horn on a pipe with a pull cord.


def build():
    horn = lathe([(0.25, 0), (0.3, 0.6), (0.5, 1.0), (0.85, 1.2)], segments=10, cap_top=False, name="bell")
    horn.rotation_euler = (1.5708, 0, 0)
    horn.location = (0, -0.2, 2.2)
    paint(horn, "Brass")
    parts = [
        box((1.2, 1.2, 0.4), location=(0, 0, 0.2), color="Iron"),
        cyl(0.18, 2.0, location=(0, 0, 1.2), segments=6, color="Iron"),
        horn,
        cyl(0.03, 1.2, location=(0.4, 0, 1.6), segments=4, color="Cloth"),
        ico(0.1, location=(0.4, 0, 1.0), subdiv=1, color="Red"),
    ]
    return finalize(parts, "TrainHorn", (2, 3, 2))
