# GrainSack — 2.5 x 1.5 x 3.5 studs. A lumpy burlap sack lying down, tied at one end.
import math


def build():
    sack = ico(1, location=(0, 0, 0.75), subdiv=2, name="sack")
    sack.scale = (1.2, 1.5, 0.72)
    jitter(sack, 0.06, seed=7)
    paint(sack, "ClothDark")
    paint(sack, "Cloth", faces={i for i in range(len(sack.data.polygons)) if i % 4 == 0})
    tie = cyl(0.28, 0.3, location=(0, 1.55, 0.8), segments=8, color="WoodDark", rotation=(math.pi / 2, 0, 0))
    tuft = cone(0.32, 0.1, 0.22, location=(0, 1.78, 0.8), segments=8, color="ClothDark", rotation=(-math.pi / 2, 0, 0))
    return finalize([sack, tie, tuft], "GrainSack", (2.5, 1.5, 3.5))
