# Worm skins: palette variants for WormHead / WormSegment (same UVs, recolored cells).
# Run in Blender after wt_style.py:  exec(open(r"<repo>\tools\blender\skins\worm_skins.py").read()); build_worm_skins()
# Writes assets/textures/skins/WT_Worm_<Skin>_<A|B>.png. "A" is the head and odd segments; "B" (optional) is
# used for even segments so a skin can have bands. Upload each as a Decal, then put the image ids in
# src/shared/Config/WormSkins.luau (whose swatch colors mirror these).
#
# Cells the worm uses: Flesh (body), FleshDark (body spots, rings, mouth rim), Rust + SandDark (armor
# plates), Glow (eyes). Bone (teeth, side nubs) and Ink (throat) stay as they are.

WORM_SKINS = {
    "Dune": {
        "A": {"Flesh": "D2B07A", "FleshDark": "9E7C4E", "Rust": "6E5236", "SandDark": "E8C994", "Glow": "FF6B3D"},
    },
    "Rattlesnake": {
        "A": {"Flesh": "8B6B3E", "FleshDark": "4A3420", "Rust": "2E2216", "SandDark": "C9A66B", "Glow": "E8D24A"},
        "B": {"Flesh": "D9C48E", "FleshDark": "A88F5A", "Rust": "3A2A1A", "SandDark": "8B6B3E", "Glow": "E8D24A"},
    },
    "Bone": {
        "A": {"Flesh": "E6DDC8", "FleshDark": "B5A88C", "Rust": "8C8473", "SandDark": "CFC6B0", "Glow": "7FD4FF"},
    },
    "Copper": {
        "A": {"Flesh": "B8643A", "FleshDark": "7A3B1E", "Rust": "4E8A96", "SandDark": "D4A23A", "Glow": "FFB347"},
        "B": {"Flesh": "9A5230", "FleshDark": "6A3018", "Rust": "355F68", "SandDark": "B8643A", "Glow": "FFB347"},
    },
}


def build_worm_skins():
    paths = []
    for skin, variants in WORM_SKINS.items():
        for variant, overrides in variants.items():
            path = os.path.join(PROJECT, "assets", "textures", "skins", f"WT_Worm_{skin}_{variant}.png")
            paths.append(build_palette_variant(path, overrides))
    return paths
