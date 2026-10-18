# Scrap — 3 x 0.8 x 2.5 studs. A pile of bent rusty sheet metal and a broken rail bolt plate.


def build():
    parts = [
        box((2.6, 2.1, 0.12), location=(0, 0, 0.1), rotation=(0.05, -0.04, 0.2), color="Rust"),
        box((2.0, 1.4, 0.1), location=(0.3, -0.2, 0.3), rotation=(-0.12, 0.15, -0.35), color="MetalDark"),
        box((1.6, 0.9, 0.1), location=(-0.5, 0.4, 0.45), rotation=(0.2, -0.1, 0.6), color="Rust"),
        box((1.3, 0.3, 0.25), location=(0.6, 0.6, 0.5), rotation=(0, 0.2, -0.2), color="Iron"),
        cyl(0.12, 0.35, location=(-0.9, -0.6, 0.55), segments=6, color="MetalLight"),
        cyl(0.12, 0.35, location=(0.95, -0.5, 0.5), segments=6, color="MetalLight"),
    ]
    return finalize(parts, "Scrap", (3, 0.8, 2.5))
