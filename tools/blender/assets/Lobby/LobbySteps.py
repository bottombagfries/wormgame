# LobbySteps — 8 x 3 x 6. Three wooden steps up to the platform; the top step is at the back (+Y), so the
# front (-Y) faces away from the platform. The side boards follow the steps, so the Hull collision is a
# smooth ramp for walking.


def build():
    parts = []
    for k in range(3):
        depth = 6 - k * 2
        y = 3 - depth / 2
        parts.append(box((7.2, depth, 1.0), location=(0, y, k + 0.5), color="WoodMid"))
        parts.append(box((7.25, 0.4, 0.06), location=(0, 3 - depth + 0.2, k + 1.02), color="Brass"))
        for x in (-3.8, 3.8):  # side boards, stepped like the treads
            parts.append(box((0.4, depth, 1.0), location=(x, y, k + 0.5), color="WoodDark"))
    return finalize(parts, "LobbySteps", (8, 3, 6))
