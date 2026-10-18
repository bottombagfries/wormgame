# QuarryMinecart — 6 x 4 x 4. An open iron mine cart on four wheels (dynamite spawns inside).


def build():
    body = []
    body.append(box((5.4, 3.4, 0.4), location=(0, 0, 1.4), color="Iron"))
    for y in (-1.6, 1.6):
        body.append(box((5.8, 0.3, 2.4), location=(0, y, 2.6), rotation=(y * 0.06, 0, 0), color="Rust"))
    for x in (-2.75, 2.75):
        body.append(box((0.3, 3.6, 2.4), location=(x, 0, 2.6), color="Rust"))
    detail = []
    for x in (-1.8, 1.8):
        for y in (-1.5, 1.5):
            detail.append(cyl(0.65, 0.3, location=(x, y, 0.65), segments=10, color="MetalDark", rotation=(1.5708, 0, 0)))
    for z in (2.0, 3.6):
        detail.append(box((6.0, 3.9, 0.15), location=(0, 0, z), color="Iron"))
    return finalize_group({"Cart": body, "Wheels": detail}, "QuarryMinecart", (6, 4, 4))
