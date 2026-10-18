# LookoutTower — 12 x 40 x 12. Tall timber tower: braced legs, a ladder, and a railed deck on top.
import math


def build():
    frame, deck, rail, detail = [], [], [], []
    top = 38.0
    for x in (-1, 1):
        for y in (-1, 1):
            leg = box((1.2, 1.2, top), location=(x * 5.0, y * 5.0, top / 2), rotation=(-y * 0.03, x * 0.03, 0), color="WoodDark")
            frame.append(leg)
    for z in (8, 18, 28):
        for y in (-5.0, 5.0):
            frame.append(box((10.5, 0.6, 0.6), location=(0, y, z), color="WoodMid"))
        for x in (-5.0, 5.0):
            frame.append(box((0.6, 10.5, 0.6), location=(x, 0, z), color="WoodMid"))
    for z0 in (8, 18, 28):
        for y in (-5.0, 5.0):
            frame.append(box((14.0, 0.4, 0.4), location=(0, y, z0 + 5), rotation=(0, math.atan2(10, 10), 0), color="WoodLight"))
    deck.append(box((12, 12, 1), location=(0, 0, top - 0.5), color="WoodMid"))
    for x in (-5.8, 5.8):
        rail.append(box((0.4, 12, 0.4), location=(x, 0, top + 1.8), color="WoodDark"))
        rail.append(box((0.4, 0.4, 2), location=(x, -5.8, top + 1), color="WoodDark"))
        rail.append(box((0.4, 0.4, 2), location=(x, 5.8, top + 1), color="WoodDark"))
    for y in (-5.8, 5.8):
        rail.append(box((12, 0.4, 0.4), location=(0, y, top + 1.8), color="WoodDark"))
    for x in (-1.0, 1.0):
        detail.append(box((0.3, 0.3, top), location=(x, -5.9, top / 2), color="WoodLight"))
    for k in range(int(top / 1.2)):
        detail.append(box((2.2, 0.25, 0.2), location=(0, -5.9, 0.8 + k * 1.2), color="WoodMid"))
    return finalize_group({"Frame": frame, "Deck": deck, "Rail": rail, "Ladder": detail}, "LookoutTower", (12, 40, 12))
