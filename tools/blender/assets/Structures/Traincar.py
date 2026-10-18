# Traincar — 34 x 12 x 10. An old boxcar half-sunk in a sand drift, tilted, door hanging open.


def build():
    car, sand, detail = [], [], []
    body = box((32, 9, 9), location=(0, 0, 4.6), rotation=(0.0, 0.06, 0.0), color="RedDark")
    car.append(body)
    car.append(box((32.6, 9.6, 0.6), location=(0.3, 0, 9.3), rotation=(0, 0.06, 0), color="MetalDark"))
    for k in range(9):
        detail.append(box((0.3, 9.1, 8.6), location=(-14 + k * 3.5, 0, 4.4 - k * 0.2), rotation=(0, 0.06, 0), color="RedDark" if k % 2 else "Rust"))
    detail.append(box((6, 0.3, 7), location=(3, -4.7, 4.3), rotation=(0, 0.06, 0.25), color="Rust"))
    dune = ico(1, location=(0, 0, 0), subdiv=2, name="dune")
    dune.scale = (17, 5, 5.5)
    bpy.ops.object.transform_apply(scale=True)
    jitter(dune, 0.08, seed=33)
    for v in dune.data.vertices:
        v.co.z = max(v.co.z, 0.0)
    paint(dune, "SandLight")
    paint(dune, "SandDark", faces={i for i in range(len(dune.data.polygons)) if i % 5 == 0})
    sand.append(dune)
    return finalize_group({"Car": car, "Sand": sand, "Detail": detail}, "Traincar", (34, 12, 10))
