# LobbyDepot — 40 x 18 x 14. The abandoned station house behind the platform: plank walls, a pitched roof
# with the ridge along X, boarded windows, a nailed-shut door, a blank sign and a porch awning over the
# platform side (-Y).
import math


def roof_x(width, depth, rise, z, y0, thickness, overhang, color):
    # Two slabs meeting at a ridge along X over a building `depth` deep centered on y0; eaves at height z.
    slope = math.atan2(rise, depth / 2)
    run = depth / 2 + overhang
    drop = run * math.tan(slope)
    length = math.hypot(run, drop)
    parts = []
    for side in (-1, 1):
        parts.append(
            box(
                (width, length, thickness),
                location=(0, y0 + side * run / 2, z + rise - drop / 2 + thickness / 2),
                rotation=(side * slope, 0, 0),
                color=color,
                name="roof",
            )
        )
    return parts


def build():
    wall, roof, detail = [], [], []
    y0, depth, wall_h, rise = 2.5, 9.0, 11.0, 5.0
    wall.append(box((38, depth, wall_h), location=(0, y0, wall_h / 2), color="WoodLight"))
    gable_fill = prism(depth, 38, rise, location=(0, 0, 0), color="WoodLight")
    gable_fill.rotation_euler = (0, 0, math.pi / 2)
    gable_fill.location = (0, y0, wall_h)
    bpy.ops.object.transform_apply(location=True, rotation=True)
    wall.append(gable_fill)
    roof += roof_x(40, depth, rise, wall_h, y0, 0.5, 1.0, "RedDark")
    front = y0 - depth / 2
    for k in range(10):  # siding lines
        detail.append(box((38.05, 0.05, 0.12), location=(0, front - 0.02, 1 + k * 1.05), color="WoodMid"))
    detail.append(box((4, 0.2, 7.5), location=(0, front - 0.1, 3.75), color="WoodDark"))  # door
    for z in (2, 4.5, 6.5):
        detail.append(box((4.6, 0.3, 0.6), location=(0, front - 0.25, z), rotation=(0, 0.25, 0), color="WoodMid"))
    for x in (-12, -6, 6, 12):  # boarded windows
        detail.append(box((3.4, 0.15, 3.6), location=(x, front - 0.08, 6), color="Iron"))
        detail.append(box((4, 0.3, 0.5), location=(x, front - 0.2, 6.6), rotation=(0, 0.3, 0), color="WoodMid"))
        detail.append(box((4, 0.3, 0.5), location=(x, front - 0.2, 5.4), rotation=(0, -0.3, 0), color="WoodMid"))
    detail.append(box((14, 0.3, 2.2), location=(0, front - 0.25, 9.8), color="Paper"))  # blank station sign
    detail.append(box((14.6, 0.25, 2.8), location=(0, front - 0.1, 9.8), color="WoodDark"))
    # Porch awning over the platform side, on four posts
    for x in (-15, -5, 5, 15):
        detail.append(box((0.6, 0.6, 8.4), location=(x, -6.6, 4.2), color="WoodDark"))
    roof.append(box((38, 5, 0.4), location=(0, -4.5, 8.7), rotation=(-0.18, 0, 0), color="RedDark"))
    detail.append(box((1.2, 1.2, 3), location=(13, y0 + 2, wall_h + 4.5), color="MetalDark"))  # stovepipe
    return finalize_group({"Wall": wall, "Roof": roof, "Detail": detail}, "LobbyDepot", (40, 18, 14))
