# LobbyGround — 170 x 2 x 130. The packed-sand yard the station stands on, with darker wheel ruts and
# patches so it does not read as a flat slab.


def build():
    parts = [box((170, 130, 2), location=(0, 0, 1), color="SandLight")]
    patches = [(-60, 40, 26, 14), (55, -40, 30, 12), (-20, -48, 18, 10), (64, 44, 16, 20), (-70, -30, 14, 18)]
    for x, y, w, d in patches:
        parts.append(box((w, d, 0.05), location=(x, y, 2.02), color="SandDark"))
    for y in (24, 29):  # old wagon ruts running behind the depot
        parts.append(box((150, 1.2, 0.05), location=(0, y, 2.02), color="SandDark"))
    return finalize(parts, "LobbyGround", (170, 2, 130))
