# Shelter — 16 x 10 x 12. Ranch lean-to: four posts and a flat plank roof you can stand on, hay inside.


def build():
    frame, deck, detail = [], [], []
    for x in (-7.25, 7.25):
        for y in (-5.25, 5.25):
            frame.append(box((1.5, 1.5, 9), location=(x, y, 4.5), color="WoodDark"))
    for y in (-5.25, 5.25):
        frame.append(box((16, 0.8, 0.8), location=(0, y, 8.6), color="WoodMid"))
    deck.append(box((16, 12, 1), location=(0, 0, 9.5), color="WoodMid"))
    for k in range(6):
        detail.append(box((2.4, 12.05, 0.05), location=(-6.5 + k * 2.6, 0, 10.02), color="WoodLight" if k % 2 else "WoodMid"))
    detail.append(box((3, 2, 2), location=(-3, 2, 1), bevel=0.2, color="Glow"))
    detail.append(box((3, 2, 2), location=(0.5, 2.5, 1), bevel=0.2, color="SandLight"))
    detail.append(box((3, 2, 2), location=(-1.2, 2.2, 3), bevel=0.2, color="Glow"))
    return finalize_group({"Frame": frame, "Deck": deck, "Detail": detail}, "Shelter", (16, 10, 12))
