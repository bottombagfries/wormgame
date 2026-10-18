# LobbyBoard — 22 x 13 x 1. The departures board on two posts. "Screen" is a flat dark panel facing -Y
# (Roblox -Z / Front); the game draws the countdown and last result on it with a SurfaceGui.


def build():
    frame, screen, detail = [], [], []
    for x in (-10.4, 10.4):
        frame.append(box((0.9, 0.9, 13), location=(x, 0.05, 6.5), color="WoodDark"))
    frame.append(box((22, 0.7, 9.6), location=(0, 0.15, 8.0), color="WoodMid"))
    screen.append(box((20, 0.3, 8.0), location=(0, -0.35, 8.0), color="Coal"))
    detail.append(box((22, 0.8, 0.5), location=(0, 0.1, 12.75), color="Brass"))
    detail.append(box((22, 0.8, 0.4), location=(0, 0.1, 3.2), color="Brass"))
    for x in (-10.4, 10.4):
        detail.append(cyl(0.25, 0.2, location=(x, -0.4, 12.0), segments=6, color="Brass", rotation=(1.5708, 0, 0)))
    return finalize_group({"Frame": frame, "Screen": screen, "Detail": detail}, "LobbyBoard", (22, 13, 1))
