# LobbyPlatform — 96 x 3 x 16. A raised boardwalk platform on a sandstone base, a brass safety edge on the
# track side (-Y), and a few planks missing.


def build():
    base, deck, detail = [], [], []
    base.append(box((96, 16, 2.4), location=(0, 0, 1.2), color="SandDark"))
    for k in range(12):  # block joints on the track-side face
        detail.append(box((0.15, 0.05, 2.2), location=(-44 + k * 8, -8.02, 1.2), color="WoodDark"))
    detail.append(box((96, 0.05, 0.15), location=(0, -8.02, 1.2), color="WoodDark"))
    deck.append(box((96, 16, 0.6), location=(0, 0, 2.7), color="WoodMid"))
    for k in range(24):
        detail.append(box((3.8, 16.05, 0.05), location=(-46 + k * 4, 0, 3.02), color="WoodLight" if k % 2 else "WoodMid"))
    detail.append(box((96, 0.7, 0.06), location=(0, -7.6, 3.04), color="Brass"))
    for x, y in ((-26, 2), (12, -3), (33, 4)):  # missing planks
        detail.append(box((3.6, 2.2, 0.07), location=(x, y, 3.04), color="Coal"))
    return finalize_group({"Base": base, "Deck": deck, "Detail": detail}, "LobbyPlatform", (96, 3, 16))
