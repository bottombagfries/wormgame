# Train — 90 x 5 x 14. A long, low flatbed train you can jump onto: deck planks, iron frame, wheels.
# The furnace, lever, horn and keyhole are separate models the game places on the deck.


def build():
    deck, frame, detail = [], [], []
    deck.append(box((90, 14, 1.2), location=(0, 0, 4.4), color="WoodMid"))
    for k in range(18):
        detail.append(box((4.6, 14.05, 0.05), location=(-42.5 + k * 5, 0, 5.02), color="WoodLight" if k % 2 else "WoodMid"))
    frame.append(box((88, 10, 1.4), location=(0, 0, 3.1), color="Iron"))
    for y in (-6.8, 6.8):
        detail.append(box((90, 0.4, 1.2), location=(0, y, 4.4), color="Iron"))
    for x in [-40 + k * 10 for k in range(9)]:
        for y in (-5.2, 5.2):
            frame.append(cyl(1.6, 0.7, location=(x, y, 1.6), segments=12, color="Iron", rotation=(1.5708, 0, 0)))
            detail.append(cyl(0.5, 0.75, location=(x, y, 1.6), segments=8, color="Red", rotation=(1.5708, 0, 0)))
    for x in (-45, 45):
        detail.append(box((1.2, 3, 1.2), location=(x, 0, 3.0), color="MetalDark"))
    detail.append(box((2, 12, 2.6), location=(45.6, 0, 1.4), rotation=(0, 0.4, 0), color="Red"))
    return finalize_group({"Deck": deck, "Frame": frame, "Detail": detail}, "Train", (90, 5, 14))
