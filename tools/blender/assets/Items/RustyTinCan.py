# RustyTinCan — 0.7 x 1 x 0.7 studs. Dented, rusted can with a peeled label band.


def build():
    can = cyl(0.35, 1.0, location=(0, 0, 0.5), segments=10, color="Rust", name="can")
    jitter(can, 0.02, seed=5)
    parts = [can, cyl(0.355, 0.4, location=(0, 0, 0.5), segments=10, color="Paper"),
             torus(0.33, 0.02, location=(0, 0, 0.98), major_seg=10, minor_seg=3, color="MetalDark")]
    return finalize(parts, "RustyTinCan", (0.7, 1, 0.7))
