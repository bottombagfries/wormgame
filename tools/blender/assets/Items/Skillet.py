# Skillet — 1.5 x 0.3 x 1.5 studs. Cast-iron pan with a short handle (kept inside the footprint).


def build():
    pan = lathe([(0.45, 0.0), (0.55, 0.3)], segments=12, cap_top=False, name="pan")
    paint(pan, "Iron")
    parts = [pan, cyl(0.52, 0.04, location=(0, 0, 0.06), segments=12, color="MetalDark"),
             box((0.45, 0.14, 0.08), location=(0.72, 0, 0.24), color="Iron"),
             torus(0.06, 0.02, location=(0.92, 0, 0.24), major_seg=6, minor_seg=3, color="Iron")]
    return finalize(parts, "Skillet", (1.5, 0.3, 1.1))
