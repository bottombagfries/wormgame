# LobbyTicketBooth — 8 x 10 x 6. A little red ticket booth: a glass window and counter on the front (-Y),
# a pitched roof and a blank sign.


def build():
    wall, roof, detail = [], [], []
    wall.append(box((7, 5, 7.6), location=(0, 0.5, 3.8), color="Red"))
    wall.append(box((7.4, 5.4, 0.5), location=(0, 0.5, 0.25), color="WoodDark"))
    roof += gable(7, 5, 2.1, location=(0, 0.5, 7.6), overhang=0.5, thickness=0.35, color="WoodDark")
    wall.append(prism(7, 5, 2.1, location=(0, 0.5, 7.6), color="Red"))
    detail.append(box((4.6, 0.12, 2.6), location=(0, -2.02, 4.4), color="Glass"))
    detail.append(box((5.2, 0.2, 0.3), location=(0, -2.05, 5.8), color="Brass"))
    detail.append(box((5.2, 0.2, 0.3), location=(0, -2.05, 3.0), color="Brass"))
    detail.append(box((5.6, 1.0, 0.3), location=(0, -2.5, 2.9), color="WoodMid"))  # counter
    detail.append(box((4.2, 0.15, 1.1), location=(0, -2.06, 6.6), color="Paper"))
    detail.append(box((1.0, 0.12, 5.6), location=(-3.0, -2.03, 2.9), color="RedDark"))
    return finalize_group({"Wall": wall, "Roof": roof, "Detail": detail}, "LobbyTicketBooth", (8, 10, 6))
