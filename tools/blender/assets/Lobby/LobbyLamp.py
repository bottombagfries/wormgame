# LobbyLamp — 1.5 x 10 x 1.5. A platform lamp post: iron post, lantern that glows, small cap.


def build():
    parts = [
        cyl(0.6, 0.6, location=(0, 0, 0.3), segments=8, color="Iron"),
        cyl(0.2, 8.0, location=(0, 0, 4.3), segments=8, color="Iron"),
        box((1.3, 1.3, 0.2), location=(0, 0, 8.2), color="Iron"),
        box((1.0, 1.0, 1.2), location=(0, 0, 8.9), color="Glow"),
        box((1.5, 1.5, 0.3), location=(0, 0, 9.65), color="Iron"),
        cone(0.5, 0.05, 0.2, location=(0, 0, 9.9), segments=6, color="Iron"),
    ]
    return finalize(parts, "LobbyLamp", (1.5, 10, 1.5))
