# CactusSeed — 0.6 x 0.6 x 0.6 (a thrown seed). A green seed pod with a sprout.


def build():
    pod = ico(0.26, location=(0, 0, 0.27), subdiv=1, name="pod")
    pod.scale = (1.16, 1.36, 1.0)
    paint(pod, "Cactus")
    sprout = cone(0.1, 0.01, 0.14, location=(0, 0, 0.53), segments=4, color="Sage")
    return finalize([pod, sprout], "CactusSeed", (0.6, 0.6, 0.6))
