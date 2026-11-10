# -*- coding: utf-8 -*-
"""
tools/blender/generate_weapons.py
Generador headless en Blender de mallas 3D de alta resolución (.obj y .fbx) y texturas 1024x1024 (.png)
para Ragdoll Arena (Versión 0.2 — Tanda 1 de Blender: D6, D15).

Uso:
  "%LOCALAPPDATA%\\Microsoft\\WindowsApps\\blender-launcher.exe" -b --python tools/blender/generate_weapons.py

Convenciones de exportación para Roblox (WeaponBuilder / WeaponMeshes):
  - Origen (0, 0, 0) en el centro del mango (Handle).
  - La hoja / cabeza apunta hacia +Z (punta exacta en TipZ).
  - El ancho del filo está en el eje Y.
  - El grosor de la hoja está en el eje X.
  - Escala 1 unidad = 1 stud de Roblox.
  - Presupuesto para móvil: ~1 200 a 3 200 triángulos por arma (estrictamente <= 5 000 tris)
    y textura atlas <= 1024x1024 px con zonas UV separadas por material.
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Matrix, Euler

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT_DIR, "modelos_armas")
os.makedirs(OUT_DIR, exist_ok=True)

# Zonas UV en una grilla de 2 columnas x 4 filas dentro del atlas 1024x1024
ROLE_INDEX = {
    "Edge": 0,    # Bisel de filo de plata espejo
    "Blade": 1,   # Núcleo de obsidiana / acero oscuro
    "Glow": 2,    # Vena de relámpago carmesí / energía
    "Gem": 3,     # Rubíes / gemas engarzadas
    "Accent": 4,  # Acero forjado de guarda y pomo
    "Trim": 5,    # Reborde metálico / filigrana
    "Grip": 6,    # Cuero estriado del mango
    "Dark": 7,    # Acanaladura profunda (Fuller)
}

DEFAULT_PALETTE = {
    "Edge":   (0.91, 0.93, 0.97),
    "Blade":  (0.08, 0.08, 0.11),
    "Glow":   (0.96, 0.10, 0.16),
    "Gem":    (0.98, 0.08, 0.15),
    "Accent": (0.22, 0.23, 0.27),
    "Trim":   (0.76, 0.79, 0.85),
    "Grip":   (0.09, 0.08, 0.10),
    "Dark":   (0.04, 0.04, 0.06),
}


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def generate_texture_atlas(name, palette, size=1024):
    """
    Genera y guarda en modelos_armas/<name>_tex.png un atlas de textura 1024x1024
    con 8 celdas (2x4) sombreadas con gradiente metálico, grano de forja, bisel y brillo.
    """
    tex_path = os.path.join(OUT_DIR, f"{name}_tex.png")
    img_name = f"{name}_tex"
    if img_name in bpy.data.images:
        bpy.data.images.remove(bpy.data.images[img_name])

    img = bpy.data.images.new(img_name, width=size, height=size, alpha=False)
    pixels = [0.0] * (size * size * 4)

    cell_w = size // 2
    cell_h = size // 4

    inv_roles = {v: k for k, v in ROLE_INDEX.items()}
    pal = dict(DEFAULT_PALETTE)
    if palette:
        pal.update(palette)

    for row in range(4):
        for col in range(2):
            idx = row * 2 + col
            role = inv_roles.get(idx, "Blade")
            br, bg, bb = pal.get(role, (0.5, 0.5, 0.5))

            x0 = col * cell_w
            y0 = row * cell_h

            for ly in range(cell_h):
                v = ly / float(max(1, cell_h - 1))
                # Sombreado transversal suave + ribete especular
                center_dist = abs(v - 0.5) * 2.0
                if role in ("Edge", "Trim"):
                    shade = 0.82 + 0.28 * (1.0 - center_dist * center_dist)
                elif role in ("Glow", "Gem"):
                    shade = 0.75 + 0.35 * (1.0 - center_dist)
                elif role == "Grip":
                    # Costillas de cuero
                    rib = 0.5 + 0.5 * math.sin(v * math.pi * 12.0)
                    shade = 0.75 + 0.30 * rib
                else:
                    shade = 0.78 + 0.24 * (1.0 - center_dist)

                for lx in range(cell_w):
                    u = lx / float(max(1, cell_w - 1))
                    grain = 0.97 + 0.03 * math.sin((lx * 0.37) + (ly * 0.23))
                    k = shade * grain
                    r = min(1.0, max(0.0, br * k))
                    g = min(1.0, max(0.0, bg * k))
                    b = min(1.0, max(0.0, bb * k))

                    px = x0 + lx
                    py = y0 + ly
                    p_idx = (py * size + px) * 4
                    pixels[p_idx] = r
                    pixels[p_idx + 1] = g
                    pixels[p_idx + 2] = b
                    pixels[p_idx + 3] = 1.0

    img.pixels.foreach_set(pixels)
    img.filepath_raw = tex_path
    img.file_format = 'PNG'
    img.save()
    return img, tex_path


class MeshBuilder:
    def __init__(self, name, palette=None):
        self.name = name
        self.palette = palette or DEFAULT_PALETTE
        self.bm = bmesh.new()
        self.uv_layer = self.bm.loops.layers.uv.new("UVMap")

    def _assign_role_uv(self, verts, role="Blade"):
        idx = ROLE_INDEX.get(role, 1)
        col = idx % 2
        row = idx // 2
        u0 = col * 0.5 + 0.04
        u1 = (col + 1) * 0.5 - 0.04
        v0 = row * 0.25 + 0.03
        v1 = (row + 1) * 0.25 - 0.03

        vert_set = set(verts)
        faces = {f for v in verts for f in v.link_faces if all(fv in vert_set for fv in f.verts)}
        for f in faces:
            n = len(f.loops)
            for i, loop in enumerate(f.loops):
                ang = (2.0 * math.pi * i) / max(3, n)
                lu = 0.5 + 0.42 * math.cos(ang)
                lv = 0.5 + 0.42 * math.sin(ang)
                loop[self.uv_layer].uv = (u0 + (u1 - u0) * lu, v0 + (v1 - v0) * lv)

    def _transform_verts(self, verts, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0), role="Blade"):
        mat_scale = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        mat_rot = Euler(rot, 'XYZ').to_matrix().to_4x4()
        mat_loc = Matrix.Translation(Vector(pos))
        mat = mat_loc @ mat_rot @ mat_scale
        bmesh.ops.transform(self.bm, matrix=mat, verts=verts)
        self._assign_role_uv(verts, role)

    def box(self, size=(1.0, 1.0, 1.0), pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), bevel=0.0, role="Blade"):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        self._transform_verts(verts, pos=pos, rot=rot, scale=size, role=role)
        if bevel > 0.0:
            edges = list({e for v in verts for e in v.link_edges})
            b_res = bmesh.ops.bevel(self.bm, geom=edges, offset=bevel, segments=1, affect='EDGES')
            self._assign_role_uv(b_res.get("verts", verts), role)
        return verts

    def cylinder(self, radius=0.15, depth=1.0, segments=16, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0), role="Accent"):
        res = bmesh.ops.create_cone(
            self.bm,
            cap_ends=True,
            cap_tris=True,
            segments=segments,
            radius1=radius,
            radius2=radius,
            depth=depth,
        )
        verts = res["verts"]
        self._transform_verts(verts, pos=pos, rot=rot, scale=scale, role=role)
        return verts

    def cone(self, radius1=0.2, radius2=0.0, depth=0.6, segments=12, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0), role="Edge"):
        res = bmesh.ops.create_cone(
            self.bm,
            cap_ends=True,
            cap_tris=True,
            segments=segments,
            radius1=radius1,
            radius2=radius2,
            depth=depth,
        )
        verts = res["verts"]
        self._transform_verts(verts, pos=pos, rot=rot, scale=scale, role=role)
        return verts

    def sphere(self, radius=0.2, segments=14, ring_count=10, pos=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0), role="Gem"):
        res = bmesh.ops.create_uvsphere(
            self.bm,
            u_segments=segments,
            v_segments=ring_count,
            radius=radius,
        )
        verts = res["verts"]
        self._transform_verts(verts, pos=pos, scale=scale, role=role)
        return verts

    def layered_razor_blade(self, z0, z1, width0, width1, thick0, thick1, tip_len, segments=8, y_curve=0.0):
        """
        Construye una hoja de alta resolución con:
          - Bisel de filo exterior de plata espejo (role="Edge")
          - Núcleo interior escalonado de obsidiana (role="Blade")
          - Acanaladura central (role="Dark")
          - Punta aguda en z1 + tip_len
        """
        # 1. Bisel de filo exterior ("Edge")
        rings_edge = []
        for i in range(segments + 1):
            t = i / float(segments)
            z = z0 + (z1 - z0) * t
            yc = math.sin(t * math.pi) * y_curve
            w = width0 + (width1 - width0) * t
            th = (thick0 + (thick1 - thick0) * t) * 0.68
            v_px = self.bm.verts.new((th * 0.5, yc, z))
            v_py = self.bm.verts.new((0.0, yc + w * 0.5, z))
            v_nx = self.bm.verts.new((-th * 0.5, yc, z))
            v_ny = self.bm.verts.new((0.0, yc - w * 0.5, z))
            rings_edge.append((v_px, v_py, v_nx, v_ny))

        edge_verts = [v for r in rings_edge for v in r]
        v_tip = self.bm.verts.new((0.0, y_curve * 0.25, z1 + tip_len))
        edge_verts.append(v_tip)

        self.bm.faces.new((rings_edge[0][0], rings_edge[0][3], rings_edge[0][2], rings_edge[0][1]))
        for i in range(segments):
            a = rings_edge[i]
            b = rings_edge[i + 1]
            self.bm.faces.new((a[0], a[1], b[1], b[0]))
            self.bm.faces.new((a[1], a[2], b[2], b[1]))
            self.bm.faces.new((a[2], a[3], b[3], b[2]))
            self.bm.faces.new((a[3], a[0], b[0], b[3]))

        last = rings_edge[-1]
        self.bm.faces.new((last[0], last[1], v_tip))
        self.bm.faces.new((last[1], last[2], v_tip))
        self.bm.faces.new((last[2], last[3], v_tip))
        self.bm.faces.new((last[3], last[0], v_tip))
        self._assign_role_uv(edge_verts, "Edge")

        # 2. Núcleo de obsidiana escalonado ("Blade")
        rings_core = []
        for i in range(segments + 1):
            t = i / float(segments)
            z = z0 + (z1 - z0) * t
            yc = math.sin(t * math.pi) * y_curve * 0.85
            w = (width0 + (width1 - width0) * t) * 0.64
            th = (thick0 + (thick1 - thick0) * t) * 1.12
            v_px = self.bm.verts.new((th * 0.5, yc, z))
            v_py = self.bm.verts.new((0.0, yc + w * 0.5, z))
            v_nx = self.bm.verts.new((-th * 0.5, yc, z))
            v_ny = self.bm.verts.new((0.0, yc - w * 0.5, z))
            rings_core.append((v_px, v_py, v_nx, v_ny))

        core_verts = [v for r in rings_core for v in r]
        v_core_tip = self.bm.verts.new((0.0, y_curve * 0.2, z1 + tip_len * 0.74))
        core_verts.append(v_core_tip)

        for i in range(segments):
            a = rings_core[i]
            b = rings_core[i + 1]
            self.bm.faces.new((a[0], a[1], b[1], b[0]))
            self.bm.faces.new((a[1], a[2], b[2], b[1]))
            self.bm.faces.new((a[2], a[3], b[3], b[2]))
            self.bm.faces.new((a[3], a[0], b[0], b[3]))

        clast = rings_core[-1]
        self.bm.faces.new((clast[0], clast[1], v_core_tip))
        self.bm.faces.new((clast[1], clast[2], v_core_tip))
        self.bm.faces.new((clast[2], clast[3], v_core_tip))
        self.bm.faces.new((clast[3], clast[0], v_core_tip))
        self._assign_role_uv(core_verts, "Blade")

    def add_lightning_vein(self, z0, z1, segments, amp_y, thick_x, width_y):
        dz = (z1 - z0) / float(segments)
        for i in range(segments):
            zm = z0 + (i + 0.5) * dz
            tilt = (1 if i % 2 == 0 else -1) * 0.18
            yo = (1 if i % 2 == 0 else -1) * amp_y * 0.5
            self.box((thick_x, width_y, dz * 1.08), pos=(0.0, yo, zm), rot=(tilt, 0.0, 0.0), role="Glow")

    def add_dorsal_hooks(self, z_list, y_spine, dir_y, hook_w, hook_l, thick_x):
        for z in z_list:
            self.cone(
                radius1=hook_w * 0.42,
                radius2=0.0,
                depth=hook_l,
                segments=8,
                pos=(0.0, y_spine + dir_y * hook_w * 0.45, z - hook_l * 0.35),
                rot=(dir_y * 0.95, 0.0, 0.0),
                scale=(thick_x / max(0.05, hook_w), 1.0, 1.0),
                role="Edge",
            )

    def grip_with_pommel_and_bolster(self, length=1.15, radius_x=0.12, radius_y=0.15, wraps=5, bolster_z=0.82, bolster_w=0.46):
        # Mango estriado
        self.cylinder(radius=1.0, depth=length, segments=16, pos=(0.0, 0.0, 0.0), scale=(radius_x, radius_y, 1.0), role="Grip")
        step = (length * 0.78) / max(1, wraps - 1)
        z_start = -length * 0.39
        for i in range(wraps):
            z = z_start + i * step
            self.cylinder(
                radius=1.0,
                depth=0.075,
                segments=16,
                pos=(0.0, 0.0, z),
                rot=(0.20, 0.0, 0.0),
                scale=(radius_x * 1.14, radius_y * 1.14, 1.0),
                role="Trim",
            )
        # Pomo de 3 garras con gema engarzada
        zp = -length * 0.5 - 0.16
        self.sphere(radius=radius_y * 1.35, segments=14, ring_count=10, pos=(0.0, 0.0, zp), scale=(0.88, 1.05, 0.95), role="Accent")
        self.sphere(radius=radius_y * 0.72, segments=12, ring_count=8, pos=(0.0, 0.0, zp), scale=(1.18, 0.75, 0.75), role="Gem")
        self.cone(radius1=radius_y * 0.62, radius2=0.0, depth=0.34, segments=10, pos=(0.0, 0.0, zp - 0.24), rot=(math.pi, 0.0, 0.0), role="Edge")
        for s in (1, -1):
            self.cone(radius1=radius_y * 0.46, radius2=0.0, depth=0.28, segments=8, pos=(0.0, s * radius_y * 1.05, zp - 0.16), rot=(math.pi + s * 0.42, 0.0, 0.0), role="Accent")

        # Recazo romboidal con 2 gemas engarzadas
        self.box((radius_x * 1.9, bolster_w, 0.46), pos=(0.0, 0.0, bolster_z), bevel=0.02, role="Accent")
        for gz in (bolster_z - 0.11, bolster_z + 0.12):
            self.box((radius_x * 2.25, 0.12, 0.12), pos=(0.0, 0.0, gz), rot=(math.pi * 0.25, 0.0, 0.0), role="Gem")

    def finalize_and_export(self):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        bmesh.ops.triangulate(self.bm, faces=self.bm.faces)

        clear_scene()
        img, _ = generate_texture_atlas(self.name, self.palette, size=1024)

        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()

        tri_count = len(mesh.polygons)
        assert tri_count <= 5000, f"{self.name} excede 5000 triángulos ({tri_count})"

        # Material con la textura 1024x1024 vinculada para importación directa en Studio
        mat = bpy.data.materials.new(name=f"{self.name}_Mat")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            tex_node = mat.node_tree.nodes.new("ShaderNodeTexImage")
            tex_node.image = img
            mat.node_tree.links.new(bsdf.inputs["Base Color"], tex_node.outputs["Color"])
        mesh.materials.append(mat)

        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)

        obj_path = os.path.join(OUT_DIR, f"{self.name}.obj")
        fbx_path = os.path.join(OUT_DIR, f"{self.name}.fbx")

        bpy.ops.wm.obj_export(
            filepath=obj_path,
            export_selected_objects=True,
            export_triangulated_mesh=True,
            export_materials=True,
            forward_axis='Z',
            up_axis='Y',
        )
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=True,
            axis_forward='Z',
            axis_up='Y',
            apply_unit_scale=True,
            bake_space_transform=True,
            path_mode='COPY',
            embed_textures=True,
        )
        return tri_count


# ==============================================================================
# 1. SKINS DE LA RULETA (D15) — PRIORIDAD TANDA 1
# ==============================================================================

def build_crimson_eclipse():
    """
    La espada de la imagen de referencia (Notas/Referencias/espada-concepto.png):
    Gran premio semanal de la ruleta (Sword, TipZ = 5.10).
    """
    pal = {
        "Edge":   (0.92, 0.94, 0.98),
        "Blade":  (0.07, 0.07, 0.10),
        "Glow":   (0.98, 0.09, 0.16),
        "Gem":    (0.96, 0.07, 0.14),
        "Accent": (0.20, 0.21, 0.25),
        "Trim":   (0.78, 0.81, 0.88),
        "Grip":   (0.08, 0.07, 0.09),
        "Dark":   (0.04, 0.04, 0.06),
    }
    b = MeshBuilder("CrimsonEclipse", pal)
    b.grip_with_pommel_and_bolster(length=1.15, radius_x=0.12, radius_y=0.15, wraps=5, bolster_z=0.88, bolster_w=0.48)

    # Guarda en media luna asimétrica + guardamonte envolvente (-Y) y gavilán delantero (+Y)
    b.cone(radius1=0.11, radius2=0.0, depth=0.68, segments=10, pos=(0.0, 0.62, 0.92), rot=(-0.58, 0.0, 0.0), role="Edge")
    for i in range(6):
        a = -0.2 + i * 0.34
        py = -0.14 - math.sin(a) * 0.56
        pz = 0.16 + math.cos(a) * 0.56
        b.box((0.16, 0.14, 0.24), pos=(0.0, py, pz), rot=(a, 0.0, 0.0), bevel=0.015, role="Accent")

    # Hoja asimétrica con bisel de plata espejo, núcleo de obsidiana, 5 colmillos dorsales y vena de relámpago carmesí
    b.layered_razor_blade(z0=0.85, z1=4.22, width0=0.44, width1=0.36, thick0=0.11, thick1=0.08, tip_len=0.88, segments=10, y_curve=0.05)
    b.add_dorsal_hooks([1.52, 2.08, 2.64, 3.20, 3.76], y_spine=-0.18, dir_y=-1, hook_w=0.22, hook_l=0.28, thick_x=0.09)
    b.add_lightning_vein(z0=1.08, z1=4.68, segments=8, amp_y=0.045, thick_x=0.13, width_y=0.036)
    return b.finalize_and_export(), 5.10


def build_blood_moon_cleaver():
    """
    Espadón de la ruleta (Greatsword, TipZ = 7.60): Mandoble de Sangre Lunar.
    """
    pal = {
        "Edge":   (0.92, 0.94, 0.98),
        "Blade":  (0.06, 0.06, 0.09),
        "Glow":   (0.96, 0.09, 0.17),
        "Gem":    (0.96, 0.07, 0.15),
        "Accent": (0.19, 0.20, 0.24),
        "Trim":   (0.79, 0.82, 0.88),
        "Grip":   (0.08, 0.06, 0.08),
        "Dark":   (0.03, 0.03, 0.05),
    }
    b = MeshBuilder("BloodMoonCleaver", pal)
    b.grip_with_pommel_and_bolster(length=2.30, radius_x=0.15, radius_y=0.19, wraps=7, bolster_z=1.55, bolster_w=0.98)

    for s in (1, -1):
        b.box((0.34, 1.32, 0.30), pos=(0.0, s * 0.84, 1.38), rot=(-s * 0.28, 0.0, 0.0), bevel=0.02, role="Accent")
        b.cone(radius1=0.18, radius2=0.0, depth=0.52, segments=10, pos=(0.0, s * 1.48, 1.54), rot=(-s * 1.15, 0.0, 0.0), role="Edge")

    b.layered_razor_blade(z0=1.45, z1=6.42, width0=1.58, width1=1.44, thick0=0.28, thick1=0.22, tip_len=1.18, segments=10, y_curve=0.06)
    b.add_dorsal_hooks([2.15, 2.90, 3.65, 4.40, 5.15, 5.85], y_spine=-0.68, dir_y=-1, hook_w=0.34, hook_l=0.40, thick_x=0.18)
    b.add_lightning_vein(z0=1.80, z1=6.95, segments=9, amp_y=0.085, thick_x=0.31, width_y=0.055)
    return b.finalize_and_export(), 7.60


def build_cataclysm_maw():
    """
    Maza de la ruleta (Mace, TipZ = 4.90): Quebrantahuesos del Eclipse.
    """
    pal = {
        "Edge":   (0.92, 0.94, 0.98),
        "Blade":  (0.07, 0.07, 0.10),
        "Glow":   (0.96, 0.10, 0.17),
        "Gem":    (0.96, 0.07, 0.15),
        "Accent": (0.20, 0.21, 0.25),
        "Trim":   (0.79, 0.82, 0.88),
        "Grip":   (0.08, 0.06, 0.08),
        "Dark":   (0.04, 0.04, 0.06),
    }
    b = MeshBuilder("CataclysmMaw", pal)
    b.grip_with_pommel_and_bolster(length=1.40, radius_x=0.16, radius_y=0.16, wraps=5, bolster_z=3.08, bolster_w=0.46)
    b.cylinder(radius=0.14, depth=2.50, segments=16, pos=(0.0, 0.0, 1.98), role="Blade")
    for rz in (1.18, 1.78, 2.38, 2.98):
        b.cylinder(radius=0.19, depth=0.14, segments=16, pos=(0.0, 0.0, rz), role="Trim")

    b.sphere(radius=0.52, segments=16, ring_count=12, pos=(0.0, 0.0, 3.82), scale=(0.95, 1.05, 1.12), role="Blade")
    b.sphere(radius=0.34, segments=14, ring_count=10, pos=(0.0, 0.0, 3.82), scale=(1.22, 0.65, 0.65), role="Gem")
    for i in range(6):
        ang = i * (2.0 * math.pi / 6.0)
        px = math.cos(ang) * 0.52
        py = math.sin(ang) * 0.52
        b.box((0.12, 0.56, 1.06), pos=(px, py, 3.82), rot=(0.0, 0.0, ang - math.pi * 0.5), bevel=0.015, role="Edge")

    b.add_dorsal_hooks([2.05, 2.55, 3.48, 4.12], y_spine=-0.24, dir_y=-1, hook_w=0.26, hook_l=0.28, thick_x=0.14)
    b.add_lightning_vein(z0=1.10, z1=4.35, segments=6, amp_y=0.035, thick_x=0.30, width_y=0.032)
    b.cone(radius1=0.18, radius2=0.0, depth=0.48, segments=12, pos=(0.0, 0.0, 4.66), role="Edge")
    return b.finalize_and_export(), 4.90


# ==============================================================================
# 2. SKINS PILOTO POR ARMA (TANDA 1 DE BLENDER) + ARMAS BASE
# ==============================================================================

def build_eclipse_claws():
    """Piloto de Dagas (Relic05: EclipseClaws, TipZ = 2.88)."""
    b = MeshBuilder("EclipseClaws")
    b.grip_with_pommel_and_bolster(length=0.85, radius_x=0.11, radius_y=0.13, wraps=4, bolster_z=0.62, bolster_w=0.32)
    for s in (1, -1):
        b.cone(radius1=0.08, radius2=0.0, depth=0.46, segments=10, pos=(0.0, s * 0.44, 0.64), rot=(-s * 0.65, 0.0, 0.0), role="Edge")
        b.cone(radius1=0.06, radius2=0.0, depth=0.58, segments=8, pos=(0.0, s * 0.28, 1.28), rot=(-s * 0.35, 0.0, 0.0), role="Trim")
    b.layered_razor_blade(z0=0.60, z1=2.42, width0=0.38, width1=0.30, thick0=0.09, thick1=0.07, tip_len=0.46, segments=8, y_curve=0.04)
    b.add_dorsal_hooks([1.05, 1.42, 1.78, 2.14], y_spine=-0.14, dir_y=-1, hook_w=0.16, hook_l=0.18, thick_x=0.07)
    b.add_lightning_vein(z0=0.78, z1=2.48, segments=5, amp_y=0.028, thick_x=0.10, width_y=0.024)
    return b.finalize_and_export(), 2.88


def build_dark_lament():
    """Piloto de Estoque (Relic26: DarkLament, TipZ = 5.56)."""
    b = MeshBuilder("DarkLament")
    b.grip_with_pommel_and_bolster(length=1.05, radius_x=0.11, radius_y=0.12, wraps=5, bolster_z=0.88, bolster_w=0.28)
    b.sphere(radius=0.48, segments=16, ring_count=12, pos=(0.0, 0.0, 0.72), scale=(0.95, 0.95, 0.55), role="Accent")
    for s in (1, -1):
        b.cone(radius1=0.06, radius2=0.0, depth=0.88, segments=10, pos=(0.0, s * 0.52, 0.62), rot=(-s * 1.35, 0.0, 0.0), role="Edge")
    b.layered_razor_blade(z0=0.92, z1=4.78, width0=0.16, width1=0.11, thick0=0.09, thick1=0.07, tip_len=0.78, segments=8, y_curve=0.0)
    b.add_dorsal_hooks([1.38, 1.78, 2.18], y_spine=-0.07, dir_y=-1, hook_w=0.14, hook_l=0.18, thick_x=0.065)
    b.add_lightning_vein(z0=1.18, z1=5.05, segments=6, amp_y=0.02, thick_x=0.095, width_y=0.02)
    return b.finalize_and_export(), 5.56


def build_dagger():
    b = MeshBuilder("Dagger")
    b.grip_with_pommel_and_bolster(length=0.85, radius_x=0.11, radius_y=0.13, wraps=4, bolster_z=0.60, bolster_w=0.30)
    for s in (1, -1):
        b.cone(radius1=0.07, radius2=0.0, depth=0.38, segments=8, pos=(0, s * 0.42, 0.60), rot=(-s * 0.6, 0, 0), role="Accent")
    b.layered_razor_blade(z0=0.60, z1=2.35, width0=0.36, width1=0.32, thick0=0.09, thick1=0.07, tip_len=0.52, segments=6)
    return b.finalize_and_export(), 2.87


def build_sword():
    b = MeshBuilder("Sword")
    b.grip_with_pommel_and_bolster(length=1.15, radius_x=0.12, radius_y=0.15, wraps=5, bolster_z=0.84, bolster_w=0.44)
    b.box((0.20, 1.56, 0.16), pos=(0, 0, 0.68), bevel=0.02, role="Accent")
    b.layered_razor_blade(z0=0.80, z1=4.22, width0=0.40, width1=0.34, thick0=0.11, thick1=0.08, tip_len=0.88, segments=8)
    return b.finalize_and_export(), 5.10


def build_greatsword():
    b = MeshBuilder("Greatsword")
    b.grip_with_pommel_and_bolster(length=2.30, radius_x=0.15, radius_y=0.19, wraps=7, bolster_z=1.52, bolster_w=0.92)
    for s in (1, -1):
        b.box((0.36, 1.25, 0.30), pos=(0, s * 0.80, 1.34), rot=(-s * 0.12, 0, 0), bevel=0.02, role="Accent")
    b.layered_razor_blade(z0=1.40, z1=6.50, width0=1.56, width1=1.42, thick0=0.30, thick1=0.24, tip_len=1.10, segments=8)
    return b.finalize_and_export(), 7.60


def build_rapier():
    b = MeshBuilder("Rapier")
    b.grip_with_pommel_and_bolster(length=1.05, radius_x=0.11, radius_y=0.12, wraps=4, bolster_z=0.82, bolster_w=0.26)
    b.sphere(radius=0.48, segments=14, ring_count=10, pos=(0, 0, 0.72), scale=(0.95, 0.95, 0.55), role="Accent")
    b.layered_razor_blade(z0=0.75, z1=4.86, width0=0.16, width1=0.11, thick0=0.09, thick1=0.07, tip_len=0.70, segments=8)
    return b.finalize_and_export(), 5.56


def build_mace():
    b = MeshBuilder("Mace")
    b.grip_with_pommel_and_bolster(length=1.40, radius_x=0.16, radius_y=0.16, wraps=5, bolster_z=3.05, bolster_w=0.42)
    b.cylinder(radius=0.14, depth=2.65, segments=12, pos=(0, 0, 2.02), role="Blade")
    b.box((1.05, 2.00, 1.10), pos=(0, 0, 3.78), bevel=0.04, role="Edge")
    b.cone(radius1=0.16, radius2=0.0, depth=0.45, segments=10, pos=(0, 0, 4.68), role="Edge")
    return b.finalize_and_export(), 4.90


def build_requiem_horns():
    """Piloto de Espada (Requiem: RequiemHorns, TipZ = 5.10)."""
    pal = dict(DEFAULT_PALETTE)
    pal["Glow"] = (0.68, 0.52, 0.96)
    pal["Gem"] = (0.72, 0.55, 1.00)
    b = MeshBuilder("RequiemHorns", pal)
    b.grip_with_pommel_and_bolster(length=1.15, radius_x=0.12, radius_y=0.15, wraps=5, bolster_z=0.86, bolster_w=0.46)
    for s in (1, -1):
        b.cone(radius1=0.12, radius2=0.02, depth=0.92, segments=10, pos=(0, s * 0.58, 1.02), rot=(-s * 0.62, 0, 0), role="Accent")
        b.cone(radius1=0.09, radius2=0.02, depth=0.68, segments=10, pos=(0, s * 0.52, 0.40), rot=(-s * 2.35, 0, 0), role="Edge")
    b.layered_razor_blade(z0=0.84, z1=4.20, width0=0.44, width1=0.38, thick0=0.12, thick1=0.09, tip_len=0.90, segments=8)
    b.add_dorsal_hooks([1.65, 2.45, 3.25], y_spine=-0.18, dir_y=-1, hook_w=0.18, hook_l=0.22, thick_x=0.085)
    b.add_lightning_vein(z0=1.12, z1=4.62, segments=6, amp_y=0.04, thick_x=0.13, width_y=0.032)
    return b.finalize_and_export(), 5.10


def build_greatsword_variant(name, tip_z, guard_wing_angle, spine_ribs=0, bindings=0, cross_halos=False):
    b = MeshBuilder(name)
    b.grip_with_pommel_and_bolster(length=2.30, radius_x=0.15, radius_y=0.19, wraps=7, bolster_z=1.52, bolster_w=0.94)
    for s in (1, -1):
        b.box((0.36, 1.30, 0.32), pos=(0, s * 0.84, 1.36), rot=(-s * guard_wing_angle, 0, 0), bevel=0.02, role="Accent")
        b.cone(radius1=0.18, radius2=0.0, depth=0.48, segments=8, pos=(0, s * 1.48, 1.48), rot=(-s * 1.2, 0, 0), role="Edge")
    if cross_halos:
        b.cylinder(radius=0.68, depth=0.12, segments=16, pos=(0, 0, 1.36), rot=(0, math.pi * 0.5, 0), role="Trim")
    b.layered_razor_blade(z0=1.40, z1=tip_z - 1.15, width0=1.56, width1=1.42, thick0=0.30, thick1=0.24, tip_len=1.15, segments=8)
    b.add_dorsal_hooks([2.15, 2.95, 3.75, 4.55, 5.35], y_spine=-0.66, dir_y=-1, hook_w=0.30, hook_l=0.36, thick_x=0.18)
    b.add_lightning_vein(z0=1.85, z1=6.95, segments=7, amp_y=0.08, thick_x=0.31, width_y=0.05)
    for i in range(spine_ribs):
        z = 1.95 + i * 0.56
        for s in (1, -1):
            b.cone(radius1=0.12, radius2=0.0, depth=0.36, segments=6, pos=(0, s * 0.78, z), rot=(-s * 0.9, 0, 0), role="Trim")
    for i in range(bindings):
        z = 1.85 + i * 0.42
        b.box((0.34, 1.54, 0.16), pos=(0, 0, z), rot=(0.14 if i % 2 == 0 else -0.14, 0, 0), role="Trim")
    return b.finalize_and_export(), tip_z


def build_bone_mace(name, tip_z, variant):
    b = MeshBuilder(name)
    b.grip_with_pommel_and_bolster(length=1.40, radius_x=0.16, radius_y=0.16, wraps=5, bolster_z=3.05, bolster_w=0.44)
    b.cylinder(radius=0.15, depth=2.60, segments=12, pos=(0, 0, 2.00), role="Blade")
    for i in range(5):
        z = 1.05 + i * 0.45
        b.cylinder(radius=0.21, depth=0.14, segments=10, pos=(0, 0, z), role="Trim")
    b.sphere(radius=0.58, segments=14, ring_count=10, pos=(0, 0, 3.80), scale=(0.95, 1.25, 1.15), role="Blade")
    b.sphere(radius=0.36, segments=12, ring_count=8, pos=(0, 0, 3.80), scale=(1.22, 0.70, 0.70), role="Gem")
    if variant == "maw":
        for s in (1, -1):
            b.box((0.48, 0.55, 1.05), pos=(0, s * 0.52, 3.82), rot=(s * 0.18, 0, 0), bevel=0.03, role="Accent")
            for k in range(4):
                zk = 3.40 + k * 0.26
                b.cone(radius1=0.09, radius2=0.0, depth=0.32, segments=6, pos=(0, s * 0.82, zk), rot=(-s * 1.45, 0, 0), role="Edge")
    elif variant == "vertebra":
        for k in range(4):
            zk = 3.32 + k * 0.34
            b.cylinder(radius=0.62, depth=0.18, segments=10, pos=(0, 0, zk), scale=(0.88, 1.15, 1.0), role="Accent")
            for s in (1, -1):
                b.cone(radius1=0.12, radius2=0.0, depth=0.52, segments=6, pos=(0, s * 0.76, zk), rot=(-s * 1.40, 0, 0), role="Edge")
    elif variant == "jaws":
        for s in (1, -1):
            b.cone(radius1=0.26, radius2=0.04, depth=1.15, segments=8, pos=(0, s * 0.64, 3.88), rot=(-s * 0.35, 0, 0), role="Accent")
            for k in range(3):
                zk = 3.48 + k * 0.32
                b.cone(radius1=0.10, radius2=0.0, depth=0.36, segments=6, pos=(0, s * 0.46, zk), rot=(s * 1.35, 0, 0), role="Edge")
    elif variant == "crown":
        for s in (1, -1):
            b.sphere(radius=0.38, segments=12, ring_count=8, pos=(0, s * 0.48, 3.76), scale=(0.9, 1.0, 1.1), role="Accent")
        for i in range(8):
            ang = i * (2.0 * math.pi / 8.0)
            px = math.cos(ang) * 0.44
            py = math.sin(ang) * 0.44
            b.cone(radius1=0.08, radius2=0.0, depth=0.38, segments=8, pos=(px, py, 4.36), role="Edge")
    spike_len = max(0.32, tip_z - 4.42)
    b.cone(radius1=0.18, radius2=0.0, depth=spike_len, segments=10, pos=(0, 0, tip_z - spike_len * 0.5), role="Edge")
    return b.finalize_and_export(), tip_z


def get_builders():
    return [
        # Tanda 1 (D6 / D15): 3 skins de la Ruleta + 5 skins Piloto (1 por clase de arma)
        ("CrimsonEclipse", build_crimson_eclipse),
        ("BloodMoonCleaver", build_blood_moon_cleaver),
        ("CataclysmMaw", build_cataclysm_maw),
        ("EclipseClaws", build_eclipse_claws),
        ("RequiemHorns", build_requiem_horns),
        ("AbyssWings", lambda: build_greatsword_variant("AbyssWings", 7.60, 0.35, spine_ribs=4)),
        ("DarkLament", build_dark_lament),
        ("OssuaryCrown", lambda: build_bone_mace("OssuaryCrown", 4.90, "crown")),
        # Armas base y variantes adicionales en modelos_armas/
        ("Dagger", build_dagger),
        ("Sword", build_sword),
        ("Greatsword", build_greatsword),
        ("Rapier", build_rapier),
        ("Mace", build_mace),
        ("EmeraldTomb", lambda: build_greatsword_variant("EmeraldTomb", 7.60, 0.18, spine_ribs=3)),
        ("Devourer", lambda: build_greatsword_variant("Devourer", 7.60, -0.22, spine_ribs=5)),
        ("RoyalMourning", lambda: build_greatsword_variant("RoyalMourning", 7.60, 0.10, cross_halos=True)),
        ("DuskCross", lambda: build_greatsword_variant("DuskCross", 7.60, 0.05, cross_halos=True)),
        ("Shroud", lambda: build_greatsword_variant("Shroud", 7.58, 0.12, bindings=8)),
        ("AncientMaw", lambda: build_bone_mace("AncientMaw", 4.85, "maw")),
        ("AbyssVertebra", lambda: build_bone_mace("AbyssVertebra", 4.90, "vertebra")),
        ("SepulcherJaws", lambda: build_bone_mace("SepulcherJaws", 4.88, "jaws")),
    ]


if __name__ == "__main__":
    import traceback
    log_path = os.path.join(OUT_DIR, "build_log.txt")
    with open(log_path, "w", encoding="utf-8") as log_file:
        try:
            builders = get_builders()
            log_file.write("=== Generando mallas y texturas 1024x1024 en modelos_armas/ (Tanda 1) ===\n")
            for name, fn in builders:
                tris, tip_z = fn()
                line = f"  [OK] {name:<18} -> {tris:4d} tris | TipZ = {tip_z:.2f} studs (.fbx + .obj + _tex.png 1024x1024)\n"
                print(line, end="")
                log_file.write(line)
                log_file.flush()
            log_file.write("=== Exportación completada ===\n")
        except Exception:
            log_file.write(traceback.format_exc())
            raise
