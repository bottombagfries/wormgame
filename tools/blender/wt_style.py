# Wormtown art pipeline helpers for Blender (run inside Blender: exec(open(path).read())).
# See ART_STYLE.md. Authoring units: 1 Blender unit = 1 Roblox stud (export scale is set in export_fbx).
#
# Workflow per asset:
#   reset_scene()
#   parts = [...]  built with box()/cyl()/... and paint(obj, "WoodMid")
#   obj = finalize(parts, "Barrel", (2.5, 3.5, 2.5))   # joins, palette-UVs, origin bottom-center, checks size
#   export_fbx(obj, "Items")
import os

import bmesh
import bpy
from mathutils import Vector

def _find_project():
    # exec() gives no __file__, so take WT_PROJECT, else the first known checkout that exists.
    candidates = [os.environ.get("WT_PROJECT", ""), r"C:\Users\james\Downloads\yaba", r"C:\Users\Rgut2\Downloads\yaba"]
    for path in candidates:
        if path and os.path.isdir(os.path.join(path, "tools", "blender")):
            return path
    raise RuntimeError("Set WT_PROJECT to the yaba checkout")


PROJECT = _find_project()
PALETTE_PNG = os.path.join(PROJECT, "assets", "textures", "WT_Palette.png")

# Palette: name -> hex. Order = cell index in the 8x8 palette texture (row-major from the top-left).
PALETTE = [
    ("SandLight", "E8C994"),
    ("SandDark", "C99A62"),
    ("WoodLight", "B98552"),
    ("WoodMid", "8A5A34"),
    ("WoodDark", "5E3B22"),
    ("Bone", "EFE6D2"),
    ("Cloth", "E3D5B4"),
    ("ClothDark", "B9A27C"),
    ("MetalLight", "A8A49C"),
    ("MetalDark", "5C5A58"),
    ("Iron", "2E2B2A"),
    ("Coal", "262322"),
    ("CoalHighlight", "45403C"),
    ("Rust", "A2532C"),
    ("Brass", "D4A23A"),
    ("Copper", "B8643A"),
    ("Red", "C23B2E"),
    ("RedDark", "8E2A22"),
    ("Cactus", "5E8C3E"),
    ("CactusDark", "416B2C"),
    ("Sage", "8FA374"),
    ("FruitPink", "C9467A"),
    ("Teal", "4E8A96"),
    ("TealDark", "355F68"),
    ("Glow", "FFD36B"),
    ("Fire", "F08A2E"),
    ("Flesh", "B0654F"),
    ("FleshDark", "7E4033"),
    ("Paper", "E9DDB8"),
    ("Ink", "3B2F2A"),
    ("Glass", "9CC3C0"),
    ("Purple", "6B4A8A"),
]
FIT_TOLERANCE = 0.15  # finalize() snaps to the Config size if every axis is within 15 %
GRID = 8  # cells per side
CELL_PX = 32  # 8 * 32 = 256 px texture (well under the 1024 cap)


def _rgb(hexstr):
    return tuple(int(hexstr[i : i + 2], 16) / 255 for i in (0, 2, 4))


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def palette_index(name):
    for i, (n, _) in enumerate(PALETTE):
        if n == name:
            return i
    raise KeyError(f"No palette color {name}")


def cell_center_uv(index):
    col, row = index % GRID, index // GRID
    u = (col + 0.5) / GRID
    v = 1 - (row + 0.5) / GRID  # row 0 at the top of the image
    return u, v


def build_palette_png():
    """Writes the shared palette texture (flat color cells) to assets/textures/WT_Palette.png."""
    size = GRID * CELL_PX
    img = bpy.data.images.get("WT_Palette_gen") or bpy.data.images.new("WT_Palette_gen", size, size, alpha=False)
    px = [0.0] * (size * size * 4)
    for i in range(GRID * GRID):
        hexstr = PALETTE[i][1] if i < len(PALETTE) else "FF00FF"
        r, g, b = _rgb(hexstr)
        col, row = i % GRID, i // GRID
        for y in range(CELL_PX):
            py = size - 1 - (row * CELL_PX + y)  # image rows start at the bottom
            for x in range(CELL_PX):
                p = (py * size + col * CELL_PX + x) * 4
                px[p : p + 4] = [r, g, b, 1.0]
    img.pixels[:] = px
    os.makedirs(os.path.dirname(PALETTE_PNG), exist_ok=True)
    img.filepath_raw = PALETTE_PNG
    img.file_format = "PNG"
    img.save()
    return PALETTE_PNG


def palette_material():
    """The one material every exported mesh uses: the palette texture, nearest filtering."""
    mat = bpy.data.materials.get("WT_Palette")
    if mat:
        return mat
    mat = bpy.data.materials.new("WT_Palette")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(PALETTE_PNG, check_existing=True)
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def paint_material(name):
    """Authoring material for one palette color (converted to palette UVs in finalize)."""
    mat_name = "pal_" + name
    mat = bpy.data.materials.get(mat_name)
    if mat:
        return mat
    palette_index(name)  # validate
    mat = bpy.data.materials.new(mat_name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    r, g, b = _rgb(dict(PALETTE)[name])
    bsdf.inputs["Base Color"].default_value = (_srgb_to_linear(r), _srgb_to_linear(g), _srgb_to_linear(b), 1)
    bsdf.inputs["Roughness"].default_value = 0.85
    return mat


def paint(obj, name, faces=None):
    """Colors a part (or only the given face indices) with a palette color."""
    mat = paint_material(name)
    slots = [s.material for s in obj.material_slots]
    if mat not in slots:
        obj.data.materials.append(mat)
        slots.append(mat)
    idx = slots.index(mat)
    for poly in obj.data.polygons:
        if faces is None or poly.index in faces:
            poly.material_index = idx
    return obj


def reset_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users == 0:
            bpy.data.meshes.remove(m)


def _active(o):
    bpy.context.view_layer.objects.active = o
    return o


def box(size, location=(0, 0, 0), bevel=0.0, color=None, rotation=(0, 0, 0), name="part"):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location, rotation=rotation)
    o = _active(bpy.context.active_object)
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        bevel_obj(o, bevel)
    if color:
        paint(o, color)
    return o


def cyl(radius, depth, location=(0, 0, 0), segments=10, bevel=0.0, color=None, rotation=(0, 0, 0), name="part"):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=segments, radius=radius, depth=depth, location=location, rotation=rotation
    )
    o = _active(bpy.context.active_object)
    o.name = name
    if bevel > 0:
        bevel_obj(o, bevel)
    if color:
        paint(o, color)
    return o


def cone(r1, r2, depth, location=(0, 0, 0), segments=10, color=None, rotation=(0, 0, 0), name="part"):
    bpy.ops.mesh.primitive_cone_add(
        vertices=segments, radius1=r1, radius2=r2, depth=depth, location=location, rotation=rotation
    )
    o = _active(bpy.context.active_object)
    o.name = name
    if color:
        paint(o, color)
    return o


def ico(radius, location=(0, 0, 0), subdiv=1, color=None, name="part"):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=radius, location=location)
    o = _active(bpy.context.active_object)
    o.name = name
    if color:
        paint(o, color)
    return o


def torus(major, minor, location=(0, 0, 0), major_seg=12, minor_seg=6, color=None, rotation=(0, 0, 0), name="part"):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major, minor_radius=minor, major_segments=major_seg, minor_segments=minor_seg,
        location=location, rotation=rotation,
    )
    o = _active(bpy.context.active_object)
    o.name = name
    if color:
        paint(o, color)
    return o


def lathe(profile, segments=10, location=(0, 0, 0), cap_bottom=True, cap_top=True, name="part"):
    """Spins a (radius, height) profile around Z into a closed low-poly solid. Returns the object; its
    side faces are in column-major order: column c (0..segments-1) spans faces c*(len-1) ... ."""
    import math

    bm = bmesh.new()
    rings = []
    for r, z in profile:
        ring = []
        for s in range(segments):
            a = 2 * math.pi * s / segments
            ring.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z)))
        rings.append(ring)
    for s in range(segments):
        s2 = (s + 1) % segments
        for i in range(len(rings) - 1):
            bm.faces.new((rings[i][s], rings[i][s2], rings[i + 1][s2], rings[i + 1][s]))
    if cap_bottom:
        bm.faces.new(list(reversed(rings[0])))
    if cap_top:
        bm.faces.new(rings[-1])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.location = location
    _active(o)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    return o


def bevel_obj(o, width, segments=1):
    mod = o.modifiers.new("bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    _active(o)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def jitter(o, amount, seed=1):
    """Hand-made wobble: nudges vertices a little (keeps the low-poly look from being too clean)."""
    import random

    rnd = random.Random(seed)
    for v in o.data.vertices:
        v.co += Vector((rnd.uniform(-amount, amount), rnd.uniform(-amount, amount), rnd.uniform(-amount, amount)))
    return o


def finalize(parts, asset_id, size):
    """Joins parts, converts paint to palette UVs + one material, cleans up, puts the origin at the
    bottom-center, and checks the result is within 2 % of `size` (studs, Roblox X,Y,Z = Blender X,Z,Y)."""
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    _active(parts[0])
    if len(parts) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = asset_id
    obj.data.name = asset_id
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Paint -> palette UVs
    me = obj.data
    names = [s.material.name[4:] if s.material else "Coal" for s in obj.material_slots]
    uv = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        u, v = cell_center_uv(palette_index(names[poly.material_index] if names else "Coal"))
        for li in poly.loop_indices:
            uv.data[li].uv = (u, v)
    me.materials.clear()
    me.materials.append(palette_material())
    for poly in me.polygons:
        poly.material_index = 0
        poly.use_smooth = False

    # Clean
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.001)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0001)
    loose = [v for v in bm.verts if not v.link_edges]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()

    # Origin at bottom-center, object at the world origin
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    offset = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)))
    for v in me.vertices:
        v.co -= offset
    obj.location = (0, 0, 0)

    # Snap to the exact Config size when the model is already close (≤ FIT_TOLERANCE off on an axis);
    # anything further off is left alone and reported, since that's a modelling mistake to fix.
    want = Vector((size[0], size[2], size[1]))  # Roblox (X, Y up, Z) -> Blender (X, Y, Z up)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    factors = [want[i] / dims[i] if dims[i] > 0 and abs(dims[i] - want[i]) / want[i] <= FIT_TOLERANCE else 1 for i in range(3)]
    for v in me.vertices:
        v.co = Vector((v.co.x * factors[0], v.co.y * factors[1], v.co.z * factors[2]))
    me.update()

    dims = Vector(
        tuple(max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices) for i in range(3))
    )
    errors = [abs(dims[i] - want[i]) / max(want[i], 0.01) for i in range(3)]
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    report = {
        "id": asset_id,
        "tris": tris,
        "size_studs": (round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)),
        "target": tuple(size),
        "size_ok": max(errors) <= 0.02,
    }
    print(report)
    return obj


def build_asset(folder, asset_id):
    """Runs tools/blender/assets/<folder>/<asset_id>.py and returns its finalized object."""
    path = os.path.join(PROJECT, "tools", "blender", "assets", folder, asset_id + ".py")
    scope = dict(globals())
    exec(open(path).read(), scope)
    return scope["build"]()


def export_fbx(obj, folder, scale=1.0):
    """Exports one asset to assets/models/<folder>/<id>.fbx. `scale` converts studs to the FBX units
    Roblox expects; it is pinned down in Step 2 (SmallCoal) and then kept for every asset."""
    path = os.path.join(PROJECT, "assets", "models", folder, obj.name + ".fbx")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    _active(obj)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"MESH", "EMPTY"},
        global_scale=scale,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="STRIP",
        embed_textures=False,
    )
    return path


# ---- Multi-mesh assets (structures, characters) ---------------------------------------------------


def _join(parts, name):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    _active(parts[0])
    if len(parts) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def _palettize(obj, untextured=False):
    me = obj.data
    names = [s.material.name[4:] if s.material else "Coal" for s in obj.material_slots]
    uv = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        u, v = cell_center_uv(palette_index(names[poly.material_index] if names else "Coal"))
        for li in poly.loop_indices:
            uv.data[li].uv = (u, v)
    me.materials.clear()
    me.materials.append(palette_material())
    for poly in me.polygons:
        poly.material_index = 0
        poly.use_smooth = False
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.001)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0001)
    loose = [v for v in bm.verts if not v.link_edges]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    obj["untextured"] = untextured


def finalize_group(groups, asset_id, size, untextured=()):
    """Joins each named group of parts into its own mesh object (name = group name, e.g. "Wall",
    "Roof", "Floor", "Detail"), gives them all one shared bottom-center origin at the world origin, snaps
    the whole set to `size` (studs, Roblox X,Y,Z) like finalize(), and returns the list of objects.
    Groups named in `untextured` are colored by game code in Roblox (house body/trim)."""
    objs = []
    for name, parts in groups.items():
        if not parts:
            continue
        obj = _join(parts, name)
        _palettize(obj, name in untextured)
        objs.append(obj)
    allv = [v.co for o in objs for v in o.data.vertices]
    lo = Vector(tuple(min(c[i] for c in allv) for i in range(3)))
    hi = Vector(tuple(max(c[i] for c in allv) for i in range(3)))
    offset = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    dims = hi - lo
    want = Vector((size[0], size[2], size[1]))
    factors = [
        want[i] / dims[i] if dims[i] > 0 and abs(dims[i] - want[i]) / want[i] <= FIT_TOLERANCE else 1 for i in range(3)
    ]
    tris = 0
    per = {}
    for o in objs:
        for v in o.data.vertices:
            c = v.co - offset
            v.co = Vector((c.x * factors[0], c.y * factors[1], c.z * factors[2]))
        o.data.update()
        o.location = (0, 0, 0)
        t = sum(len(p.vertices) - 2 for p in o.data.polygons)
        per[o.name] = t
        tris += t
    allv = [v.co for o in objs for v in o.data.vertices]
    dims = Vector(tuple(max(c[i] for c in allv) - min(c[i] for c in allv) for i in range(3)))
    errors = [abs(dims[i] - want[i]) / max(want[i], 0.01) for i in range(3)]
    print(
        {
            "id": asset_id,
            "tris": tris,
            "per_mesh": per,
            "size_studs": (round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)),
            "target": tuple(size),
            "size_ok": max(errors) <= 0.02,
        }
    )
    bpy.context.scene["wt_group_id"] = asset_id
    return objs


def export_group(objs, folder, asset_id, scale=1.0):
    path = os.path.join(PROJECT, "assets", "models", folder, asset_id + ".fbx")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    _active(objs[0])
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"MESH"},
        global_scale=scale,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="STRIP",
        embed_textures=False,
    )
    return path


def gable(width, depth, height, location=(0, 0, 0), overhang=0.0, thickness=0.4, color=None, name="roof"):
    """A pitched roof: two slabs meeting at a ridge along Y. `width` is the wall span (X), `depth` the
    length (Y), `height` the ridge rise above `location` (the eave line on the walls)."""
    import math

    slope = math.atan2(height, width / 2)
    run = width / 2 + overhang
    rise = run * math.tan(slope)
    length = math.hypot(run, rise)
    parts = []
    for side in (-1, 1):
        slab = box(
            (length, depth + overhang * 2, thickness),
            location=(location[0] + side * run / 2, location[1], location[2] + height - rise / 2 + thickness / 2),
            rotation=(0, side * slope, 0),
            color=color,
            name=name,
        )
        parts.append(slab)
    return parts


def prism(width, depth, height, location=(0, 0, 0), color=None, name="gable"):
    """A solid triangular prism (gable end / attic fill): base `width` along X, ridge along Y."""
    bm = bmesh.new()
    hw, hd = width / 2, depth / 2
    v = [
        bm.verts.new((-hw, -hd, 0)), bm.verts.new((hw, -hd, 0)), bm.verts.new((0, -hd, height)),
        bm.verts.new((-hw, hd, 0)), bm.verts.new((hw, hd, 0)), bm.verts.new((0, hd, height)),
    ]
    bm.faces.new((v[0], v[2], v[1]))
    bm.faces.new((v[3], v[4], v[5]))
    bm.faces.new((v[0], v[1], v[4], v[3]))
    bm.faces.new((v[1], v[2], v[5], v[4]))
    bm.faces.new((v[2], v[0], v[3], v[5]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.location = location
    _active(o)
    bpy.ops.object.transform_apply(location=True)
    if color:
        paint(o, color)
    return o


def build_any(folder, asset_id):
    """Runs a build script; returns a list of objects (single-mesh scripts return one object)."""
    result = build_asset(folder, asset_id)
    return result if isinstance(result, list) else [result]


def export_any(objs, folder, asset_id):
    if len(objs) == 1 and objs[0].name == asset_id:
        return export_fbx(objs[0], folder)
    return export_group(objs, folder, asset_id)


def house(asset_id, size, roof_rise, stories=1, chimney=True, seed=1):
    """A walk-in house (§7) as named meshes: Wall + Roof (untextured — game code paints body/trim colors),
    Trim (corner boards, door + window frames; untextured trim color), Floor (+ door step), Detail
    (window glass, door, chimney). Door on the front (Blender -Y = Roblox -Z). `size` is Roblox (X, Y, Z).
    The roof overhangs the walls by 1 stud, so the walls stand 1 stud inside the footprint."""
    W, H, D = size[0], size[1], size[2]
    over = 1.0
    t = 1.0
    w, d = W - 2 * over, D - 2 * over  # wall footprint
    wall_h = H - roof_rise
    door_w, door_h = 6.0, 8.0
    walls, roof, trim, floor, detail = [], [], [], [], []

    floor.append(box((w, d, t), location=(0, 0, t / 2), color="WoodMid", name="Floor"))
    floor.append(box((door_w + 2, 1.0, 0.5), location=(0, -d / 2 - 0.5, 0.25), color="WoodDark", name="Floor"))

    zc = t + (wall_h - t) / 2
    hh = wall_h - t
    walls.append(box((w, t, hh), location=(0, d / 2 - t / 2, zc), name="Wall"))
    walls.append(box((t, d - 2 * t, hh), location=(-w / 2 + t / 2, 0, zc), name="Wall"))
    walls.append(box((t, d - 2 * t, hh), location=(w / 2 - t / 2, 0, zc), name="Wall"))
    side = (w - door_w) / 2
    fy = -d / 2 + t / 2
    walls.append(box((side, t, hh), location=(-w / 2 + side / 2, fy, zc), name="Wall"))
    walls.append(box((side, t, hh), location=(w / 2 - side / 2, fy, zc), name="Wall"))
    lintel = hh - door_h
    walls.append(box((door_w, t, lintel), location=(0, fy, t + door_h + lintel / 2), name="Wall"))
    for y in (fy, d / 2 - t / 2):
        walls.append(prism(w, t, roof_rise - 0.3, location=(0, y, wall_h), name="Wall"))

    roof.extend(gable(w, d, roof_rise, location=(0, 0, wall_h), overhang=over, thickness=0.5, name="Roof"))

    for x in (-w / 2, w / 2):
        for y in (-d / 2, d / 2):
            trim.append(box((0.5, 0.5, hh), location=(x, y, zc), name="Trim"))
    trim.append(box((door_w + 1, 0.3, 0.6), location=(0, -d / 2 - 0.1, t + door_h + 0.3), name="Trim"))
    for x in (-door_w / 2 - 0.25, door_w / 2 + 0.25):
        trim.append(box((0.5, 0.3, door_h), location=(x, -d / 2 - 0.1, t + door_h / 2), name="Trim"))

    def window(x, y, z, facing_x=False):
        if facing_x:
            trim.append(box((0.3, 3.4, 3.4), location=(x, y, z), name="Trim"))
            detail.append(box((0.32, 2.6, 2.6), location=(x, y, z), color="Glass", name="Detail"))
            detail.append(box((0.36, 0.2, 2.6), location=(x, y, z), color="WoodDark", name="Detail"))
        else:
            trim.append(box((3.4, 0.3, 3.4), location=(x, y, z), name="Trim"))
            detail.append(box((2.6, 0.32, 2.6), location=(x, y, z), color="Glass", name="Detail"))
            detail.append(box((0.2, 0.36, 2.6), location=(x, y, z), color="WoodDark", name="Detail"))

    levels = [t + 5.0 + k * (hh / stories) for k in range(stories)]
    for z in levels:
        for x in (-w / 4 - 1, w / 4 + 1):
            if stories > 1 or abs(x) > door_w / 2 + 2:
                window(x, -d / 2 - 0.05, z)
            window(x, d / 2 + 0.05, z)
        for y in (-d / 4, d / 4):
            window(-w / 2 - 0.05, y, z, True)
            window(w / 2 + 0.05, y, z, True)
    if stories > 1:
        window(0, -d / 2 - 0.05, levels[-1])

    if chimney:
        cx = w / 4
        detail.append(box((2, 2, roof_rise), location=(cx, d / 4, wall_h + roof_rise / 2), color="Rust", name="Detail"))
        detail.append(box((2.4, 2.4, 0.5), location=(cx, d / 4, wall_h + roof_rise - 0.25), color="MetalDark", name="Detail"))
    return finalize_group(
        {"Floor": floor, "Wall": walls, "Roof": roof, "Trim": trim, "Detail": detail},
        asset_id, size, untextured=("Wall", "Roof", "Trim"),
    )
