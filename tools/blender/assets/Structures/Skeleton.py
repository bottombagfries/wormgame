# Skeleton — 2 x 1 x 6. An old cowpoke's bones lying in the sand (marks where the key was buried).


def build():
    parts = [
        ico(0.5, location=(0, 2.4, 0.5), subdiv=1, color="Bone"),
        box((0.6, 0.5, 0.3), location=(0, 2.85, 0.3), color="Bone"),
        box((0.25, 2.2, 0.25), location=(0, 0.9, 0.3), color="Bone"),
        box((0.8, 0.5, 0.3), location=(0, -0.3, 0.3), color="Bone"),
    ]
    for k in range(4):
        parts.append(box((1.6, 0.15, 0.3), location=(0, 1.6 - k * 0.35, 0.35), color="Bone"))
    for x in (-0.35, 0.35):
        parts.append(box((0.22, 2.3, 0.22), location=(x, -1.7, 0.2), rotation=(0, 0, x * 0.2), color="Bone"))
        parts.append(box((0.2, 1.8, 0.2), location=(x * 2.4, 1.0, 0.2), rotation=(0, 0, -x * 0.4), color="Bone"))
    parts.append(box((1.2, 0.8, 0.5), location=(0.3, 2.5, 0.75), rotation=(0, 0.2, 0.3), color="WoodMid"))
    return finalize(parts, "Skeleton", (2, 1, 6))
