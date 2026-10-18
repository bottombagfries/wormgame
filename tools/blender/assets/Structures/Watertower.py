# Watertower — 14 x 44 x 14. Four braced legs, a deck, a rusty tank with a cone roof and a ladder.


def build():
    frame, deck, tank, detail = [], [], [], []
    deck_z = 28.0
    for x in (-1, 1):
        for y in (-1, 1):
            frame.append(box((1.2, 1.2, deck_z), location=(x * 5.5, y * 5.5, deck_z / 2), color="WoodDark"))
    for z in (9, 19):
        for y in (-5.5, 5.5):
            frame.append(box((11.5, 0.6, 0.6), location=(0, y, z), color="WoodMid"))
        for x in (-5.5, 5.5):
            frame.append(box((0.6, 11.5, 0.6), location=(x, 0, z), color="WoodMid"))
    deck.append(box((14, 14, 0.8), location=(0, 0, deck_z - 0.4), color="WoodMid"))
    body = lathe([(5.8, deck_z), (6.0, deck_z + 1), (6.0, deck_z + 10), (5.8, deck_z + 10.5)], segments=16, name="tank")
    paint(body, "Rust")
    tank.append(body)
    roof = cone(6.6, 0.4, 5.2, location=(0, 0, deck_z + 10.5 + 2.6), segments=16, color="MetalDark")
    tank.append(roof)
    for z in (deck_z + 2.5, deck_z + 8):
        detail.append(torus(6.05, 0.15, location=(0, 0, z), major_seg=16, minor_seg=3, color="Iron"))
    for x in (-0.9, 0.9):
        detail.append(box((0.3, 0.3, 40), location=(x, -6.3, 20), color="Iron"))
    for k in range(32):
        detail.append(box((2.0, 0.2, 0.2), location=(0, -6.3, 1 + k * 1.2), color="MetalDark"))
    return finalize_group({"Frame": frame, "Deck": deck, "Tank": tank, "Ladder": detail}, "Watertower", (14, 44, 14))
