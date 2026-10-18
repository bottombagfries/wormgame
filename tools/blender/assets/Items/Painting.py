# Painting — 2.5 x 2 x 0.3 studs. Framed desert landscape: sky, mesa, sand, sun.


def build():
    parts = [box((2.5, 0.3, 2.0), location=(0, 0, 1.0), bevel=0.03, color="Brass"),
             box((2.15, 0.05, 0.9), location=(0, -0.15, 1.35), color="Teal"),
             box((2.15, 0.05, 0.75), location=(0, -0.15, 0.55), color="SandLight"),
             box((0.9, 0.07, 0.45), location=(0.4, -0.16, 1.0), color="Rust"),
             cyl(0.18, 0.07, location=(-0.6, -0.17, 1.5), segments=8, color="Glow", rotation=(1.5708, 0, 0))]
    return finalize(parts, "Painting", (2.5, 2, 0.35))
