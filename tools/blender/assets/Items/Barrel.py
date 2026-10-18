# Barrel — 2.5 x 3.5 x 2.5 studs. Bulging staved barrel with three iron hoops.
# Run after wt_style.py: build() returns the finalized object.


def build():
    seg = 12
    prof = [(1.02, 0.0), (1.17, 0.55), (1.25, 1.75), (1.17, 2.95), (1.02, 3.5)]
    body = lathe(prof, segments=seg, name="body")
    paint(body, "WoodMid")
    rows = len(prof) - 1
    staves = {c * rows + i for c in range(0, seg, 2) for i in range(rows)}  # every other stave lighter
    paint(body, "WoodLight", faces=staves)
    paint(body, "WoodDark", faces={seg * rows, seg * rows + 1})  # lids
    hoops = [
        torus(1.12, 0.06, location=(0, 0, 0.45), major_seg=seg, minor_seg=4, color="Iron"),
        torus(1.12, 0.06, location=(0, 0, 3.05), major_seg=seg, minor_seg=4, color="Iron"),
        torus(1.25, 0.05, location=(0, 0, 1.75), major_seg=seg, minor_seg=4, color="Iron"),
    ]
    return finalize([body] + hoops, "Barrel", (2.5, 3.5, 2.5))
