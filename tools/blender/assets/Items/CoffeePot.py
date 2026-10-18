# CoffeePot — 1 x 1.4 x 1 studs. Enamel cowboy coffee pot: flared body, spout, handle, knob lid.
import math


def build():
    body = lathe([(0.36, 0.0), (0.34, 0.75), (0.24, 1.05), (0.26, 1.1)], segments=10, name="pot")
    paint(body, "Teal")
    parts = [body,
             cone(0.09, 0.04, 0.4, location=(0.38, 0, 0.7), segments=6, color="TealDark", rotation=(0, 0.9, 0)),
             torus(0.18, 0.045, location=(-0.36, 0, 0.6), major_seg=8, minor_seg=4, color="TealDark", rotation=(math.pi / 2, 0, 0)),
             cyl(0.27, 0.06, location=(0, 0, 1.13), segments=10, color="TealDark"),
             ico(0.08, location=(0, 0, 1.25), subdiv=1, color="Iron")]
    return finalize(parts, "CoffeePot", (1, 1.4, 0.7))
