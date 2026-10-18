# Church — 30 x 34 x 50. White-board chapel: long nave, steep roof, bell tower over the front door.


def build():
    W, H, D = 30, 34, 50
    t = 1.0
    w, d = 28, 46
    wall_h = 16
    rise = 8
    door_w, door_h = 6.0, 9.0
    walls, roof, floor, detail = [], [], [], []
    floor.append(box((w, d, t), location=(0, 0, t / 2), color="WoodMid"))
    floor.append(box((door_w + 4, 2.0, 0.6), location=(0, -d / 2 - 1.0, 0.3), color="WoodDark"))
    zc, hh = t + (wall_h - t) / 2, wall_h - t
    walls.append(box((w, t, hh), location=(0, d / 2 - t / 2, zc), color="Bone"))
    walls.append(box((t, d - 2 * t, hh), location=(-w / 2 + t / 2, 0, zc), color="Bone"))
    walls.append(box((t, d - 2 * t, hh), location=(w / 2 - t / 2, 0, zc), color="Bone"))
    side = (w - door_w) / 2
    fy = -d / 2 + t / 2
    walls.append(box((side, t, hh), location=(-w / 2 + side / 2, fy, zc), color="Bone"))
    walls.append(box((side, t, hh), location=(w / 2 - side / 2, fy, zc), color="Bone"))
    walls.append(box((door_w, t, hh - door_h), location=(0, fy, t + door_h + (hh - door_h) / 2), color="Bone"))
    for y in (fy, d / 2 - t / 2):
        walls.append(prism(w, t, rise - 0.3, location=(0, y, wall_h), color="Bone"))
    roof.extend(gable(w, d, rise, location=(0, 0, wall_h), overhang=1.0, thickness=0.5, color="WoodDark"))
    # Bell tower above the door, steeple to the full height.
    tower_z = wall_h + rise - 2
    walls.append(box((7, 7, 6), location=(0, -d / 2 + 3.5, tower_z + 3), color="Bone"))
    detail.append(box((5, 7.2, 3), location=(0, -d / 2 + 3.5, tower_z + 3.5), color="Ink"))
    detail.append(box((7.2, 5, 3), location=(0, -d / 2 + 3.5, tower_z + 3.5), color="Ink"))
    roof.append(cone(5.2, 0.2, H - (tower_z + 6) - 2.5, location=(0, -d / 2 + 3.5, tower_z + 6 + (H - (tower_z + 6) - 2.5) / 2), segments=4, color="WoodDark", rotation=(0, 0, 0.785)))
    detail.append(box((0.4, 0.4, 2.5), location=(0, -d / 2 + 3.5, H - 1.25), color="Brass"))
    detail.append(box((1.5, 0.4, 0.4), location=(0, -d / 2 + 3.5, H - 0.9), color="Brass"))
    detail.append(cone(1.2, 1.2, 1.4, location=(0, -d / 2 + 3.5, tower_z + 3.5), segments=8, color="Brass"))
    for k in range(4):
        y = -d / 2 + 10 + k * 9
        for x in (-w / 2 - 0.05, w / 2 + 0.05):
            detail.append(box((0.3, 2.6, 6), location=(x, y, 8), color="Teal"))
            detail.append(box((0.35, 3.2, 0.4), location=(x, y, 11.2), color="WoodDark"))
    detail.append(box((door_w, 0.3, door_h), location=(-door_w / 2 - 0.1, -d / 2 - 0.3, t + door_h / 2), rotation=(0, 0, 1.2), color="WoodDark"))
    detail.append(cyl(1.8, 0.3, location=(0, -d / 2 - 0.1, wall_h + 3), segments=10, color="Glow", rotation=(1.5708, 0, 0)))
    return finalize_group({"Floor": floor, "Walls": walls, "Roof": roof, "Detail": detail}, "Church", (W, H, D))
