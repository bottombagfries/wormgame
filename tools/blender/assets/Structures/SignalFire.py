# SignalFire — 6 x 5 x 6. A stone ring and a teepee of logs; the inner kindling (untextured) turns the lit
# color when the fire is lit (LightSignalFires recolors every part).
import math


def build():
    stones, logs, kindling = [], [], []
    for k in range(10):
        a = k * 2 * math.pi / 10
        s = ico(0.55, location=(math.cos(a) * 2.6, math.sin(a) * 2.6, 0.4), subdiv=1, color="MetalLight" if k % 2 else "MetalDark")
        jitter(s, 0.08, seed=k)
        stones.append(s)
    for k in range(6):
        a = k * 2 * math.pi / 6
        logs.append(cyl(0.3, 5.2, location=(math.cos(a) * 1.0, math.sin(a) * 1.0, 2.4), segments=6, color="WoodDark" if k % 2 else "WoodMid",
                        rotation=(-math.sin(a) * 0.38, math.cos(a) * 0.38, 0)))
    kindling.append(cone(1.4, 0.2, 2.8, location=(0, 0, 1.4), segments=6))
    return finalize_group({"Stones": stones, "Logs": logs, "Kindling": kindling}, "SignalFire", (6, 5, 6), untextured=("Kindling",))
