# RifleTracer — 0.2 x 0.2 x 1, stretched along Z by the game. A bright bullet streak (made Neon in Studio).
import math


def build():
    return finalize([cyl(0.1, 1.0, location=(0, 0, 0.1), segments=6, color="Glow", rotation=(math.pi / 2, 0, 0))], "RifleTracer", (0.2, 0.2, 1))
