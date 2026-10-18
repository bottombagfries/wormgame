# SafeDigitSign — 3 x 5 x 0.5. A post with a weathered board (the game writes the digit on it).


def build():
    parts = [
        box((0.4, 0.4, 5), location=(0, 0.05, 2.5), color="WoodDark"),
        box((3, 0.25, 2.2), location=(0, -0.12, 3.6), bevel=0.05, color="WoodLight"),
        box((2.4, 0.05, 1.6), location=(0, -0.26, 3.6), color="Paper"),
        box((0.3, 0.3, 0.3), location=(-1.2, -0.2, 4.55), color="Iron"),
        box((0.3, 0.3, 0.3), location=(1.2, -0.2, 4.55), color="Iron"),
    ]
    return finalize(parts, "SafeDigitSign", (3, 5, 0.6))
