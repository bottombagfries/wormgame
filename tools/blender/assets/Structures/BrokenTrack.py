# BrokenTrack — 12 x 1 x 8. Railroad ties with two rails, one snapped and bent up; the rails are untextured
# so RepairTracks' repaired color shows.


def build():
    ties, rails = [], []
    for k in range(6):
        ties.append(box((1.2, 8, 0.4), location=(-5 + k * 2, 0, 0.2), rotation=(0, 0, 0.04 * (k - 2)), color="WoodDark" if k % 2 else "WoodMid"))
    for y in (-2.5, 2.5):
        rails.append(box((5, 0.5, 0.5), location=(-3.5, y, 0.65), name="rail"))
    rails.append(box((4.6, 0.5, 0.4), location=(3.7, -2.5, 0.62), rotation=(0, -0.06, 0.1), name="rail"))
    rails.append(box((4.6, 0.5, 0.5), location=(3.5, 2.5, 0.65), rotation=(0, 0.05, -0.15), name="rail"))
    return finalize_group({"Ties": ties, "Rails": rails}, "BrokenTrack", (12, 1, 8), untextured=("Rails",))
