# LobbyTrack — 150 x 1 x 8. A rusty stretch of track along the platform: gravel bed, ties, two rails.


def build():
    ties, rails = [], []
    ties.append(box((150, 7, 0.15), location=(0, 0, 0.075), color="SandDark"))
    for k in range(38):
        ties.append(box((1.4, 8, 0.35), location=(-74 + k * 4, 0, 0.32), color="WoodDark" if k % 3 else "WoodMid"))
    for y in (-2.4, 2.4):
        rails.append(box((150, 0.45, 0.5), location=(0, y, 0.75), color="Rust"))
        rails.append(box((150, 0.8, 0.12), location=(0, y, 0.55), color="Iron"))
    return finalize_group({"Ties": ties, "Rails": rails}, "LobbyTrack", (150, 1, 8))
