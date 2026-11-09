# -*- coding: utf-8 -*-
"""
tools/blender/generate_weapons.py
Generador headless en Blender de mallas 3D (.obj y .fbx) para Ragdoll Arena.

Uso:
  "%LOCALAPPDATA%\\Microsoft\\WindowsApps\\blender-launcher.exe" -b --python tools/blender/generate_weapons.py

Convenciones de exportación para Roblox (WeaponBuilder / WeaponMeshes):
  - Origen (0, 0, 0) en el centro del mango (Handle).
  - La hoja / cabeza apunta hacia +Z.
  - El ancho del filo está en el eje Y.
  - El grosor de la hoja está en el eje X.
  - Escala 1 unidad = 1 stud de Roblox.
  - Presupuesto estricto: <= 5 000 triángulos por arma (todas rondan 400 - 1 200 tris).
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Matrix, Euler

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT_DIR, "modelos_armas")
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


class MeshBuilder:
    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()

    def _transform_verts(self, verts, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)):
        mat_scale = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        mat_rot = Euler(rot, 'XYZ').to_matrix().to_4x4()
        mat_loc = Matrix.Translation(Vector(pos))
        mat = mat_loc @ mat_rot @ mat_scale
        bmesh.ops.transform(self.bm, matrix=mat, verts=verts)

    def box(self, size=(1.0, 1.0, 1.0), pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), bevel=0.0):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        self._transform_verts(verts, pos=pos, rot=rot, scale=size)
        if bevel > 0.0:
            edges = list({e for v in verts for e in v.link_edges})
            bmesh.ops.bevel(self.bm, geom=edges, offset=bevel, segments=1, affect='EDGES')
        return verts

    def cylinder(self, radius=0.15, depth=1.0, segments=12, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)):
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
        self._transform_verts(verts, pos=pos, rot=rot, scale=scale)
        return verts

    def cone(self, radius1=0.2, radius2=0.0, depth=0.6, segments=8, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)):
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
        self._transform_verts(verts, pos=pos, rot=rot, scale=scale)
        return verts

    def sphere(self, radius=0.2, segments=10, ring_count=8, pos=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)):
        res = bmesh.ops.create_uvsphere(
            self.bm,
            u_segments=segments,
            v_segments=ring_count,
            radius=radius,
        )
        verts = res["verts"]
        self._transform_verts(verts, pos=pos, scale=scale)
        return verts

    def diamond_blade(self, z0, z1, width0, width1, thick0, thick1, tip_len, tip_thick=0.02):
        """Crea una hoja de sección romboidal con bisel doble y punta aguda hacia +Z."""
        # Anillos en z0 y z1 (4 vértices: +X centro, +Y filo, -X centro, -Y filo)
        v_b_px = self.bm.verts.new((thick0 * 0.5, 0.0, z0))
        v_b_py = self.bm.verts.new((0.0, width0 * 0.5, z0))
        v_b_nx = self.bm.verts.new((-thick0 * 0.5, 0.0, z0))
        v_b_ny = self.bm.verts.new((0.0, -width0 * 0.5, z0))

        v_m_px = self.bm.verts.new((thick1 * 0.5, 0.0, z1))
        v_m_py = self.bm.verts.new((0.0, width1 * 0.5, z1))
        v_m_nx = self.bm.verts.new((-thick1 * 0.5, 0.0, z1))
        v_m_ny = self.bm.verts.new((0.0, -width1 * 0.5, z1))

        v_tip = self.bm.verts.new((0.0, 0.0, z1 + tip_len))

        # Tapa base
        self.bm.faces.new((v_b_px, v_b_ny, v_b_nx, v_b_py))
        # Caras del cuerpo de la hoja
        self.bm.faces.new((v_b_px, v_b_py, v_m_py, v_m_px))
        self.bm.faces.new((v_b_py, v_b_nx, v_m_nx, v_m_py))
        self.bm.faces.new((v_b_nx, v_b_ny, v_m_ny, v_m_nx))
        self.bm.faces.new((v_b_ny, v_b_px, v_m_px, v_m_ny))
        # Caras de la punta
        self.bm.faces.new((v_m_px, v_m_py, v_tip))
        self.bm.faces.new((v_m_py, v_m_nx, v_tip))
        self.bm.faces.new((v_m_nx, v_m_ny, v_tip))
        self.bm.faces.new((v_m_ny, v_m_px, v_tip))

    def grip_with_wraps(self, z_center=0.0, length=1.1, radius_x=0.13, radius_y=0.16, wraps=5):
        self.cylinder(
            radius=1.0,
            depth=length,
            segments=12,
            pos=(0.0, 0.0, z_center),
            scale=(radius_x, radius_y, 1.0),
        )
        step = (length * 0.78) / max(1, wraps - 1)
        z_start = z_center - (length * 0.39)
        for i in range(wraps):
            z = z_start + i * step
            self.cylinder(
                radius=1.0,
                depth=0.08,
                segments=12,
                pos=(0.0, 0.0, z),
                rot=(0.18, 0.0, 0.0),
                scale=(radius_x * 1.12, radius_y * 1.12, 1.0),
            )

    def finalize_and_export(self):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        bmesh.ops.triangulate(self.bm, faces=self.bm.faces)

        clear_scene()
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()

        tri_count = len(mesh.polygons)
        assert tri_count <= 5000, f"{self.name} excede 5000 triángulos ({tri_count})"

        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)

        obj_path = os.path.join(OUT_DIR, f"{self.name}.obj")
        fbx_path = os.path.join(OUT_DIR, f"{self.name}.fbx")

        # Exportar OBJ (Blender 4.x wm.obj_export)
        bpy.ops.wm.obj_export(
            filepath=obj_path,
            export_selected_objects=True,
            export_triangulated_mesh=True,
            forward_axis='Z',
            up_axis='Y',
        )
        # Exportar FBX
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=True,
            axis_forward='Z',
            axis_up='Y',
            apply_unit_scale=True,
            bake_space_transform=True,
        )
        return tri_count


# ==============================================================================
# 1. ARMAS BASE
# ==============================================================================

def build_dagger():
    b = MeshBuilder("Dagger")
    b.grip_with_wraps(0.0, 0.85, 0.11, 0.13, wraps=4)
    b.cylinder(radius=0.15, depth=0.12, segments=10, pos=(0, 0, -0.48))
    b.cone(radius1=0.12, radius2=0.0, depth=0.38, segments=8, pos=(0, 0, -0.72), rot=(math.pi, 0, 0))
    # Guarda con púas
    b.box((0.22, 0.78, 0.18), pos=(0, 0, 0.52), bevel=0.02)
    for s in (1, -1):
        b.cone(radius1=0.07, radius2=0.0, depth=0.38, segments=6, pos=(0, s * 0.52, 0.62), rot=(-s * 0.6, 0, 0))
    # Hoja dentada (punta en z = 2.87)
    b.diamond_blade(z0=0.60, z1=2.35, width0=0.36, width1=0.32, thick0=0.09, thick1=0.07, tip_len=0.52)
    for i in range(4):
        z = 0.98 + i * 0.30
        for s in (1, -1):
            b.cone(radius1=0.06, radius2=0.0, depth=0.18, segments=4, pos=(0, s * 0.20, z), rot=(s * 0.8, 0, 0))
    return b.finalize_and_export(), 2.87


def build_sword():
    b = MeshBuilder("Sword")
    b.grip_with_wraps(0.0, 1.15, 0.12, 0.15, wraps=5)
    b.cylinder(radius=0.16, depth=0.10, segments=10, pos=(0, 0, -0.62))
    b.sphere(radius=0.20, segments=10, ring_count=8, pos=(0, 0, -0.78), scale=(0.85, 1.0, 0.9))
    b.cone(radius1=0.09, radius2=0.0, depth=0.14, segments=8, pos=(0, 0, -0.96), rot=(math.pi, 0, 0))
    # Guarda cruciforme de caballero
    b.box((0.26, 0.44, 0.24), pos=(0, 0, 0.68), bevel=0.02)
    b.box((0.20, 1.56, 0.16), pos=(0, 0, 0.68), bevel=0.02)
    for s in (1, -1):
        b.box((0.22, 0.20, 0.22), pos=(0, s * 0.84, 0.66), rot=(s * 0.26, 0, 0), bevel=0.02)
        b.sphere(radius=0.11, segments=8, ring_count=6, pos=(0, s * 0.96, 0.64))
    # Recazo, acanaladura y hoja recta de doble filo (punta en z = 5.10)
    b.box((0.13, 0.44, 0.48), pos=(0, 0, 1.02), bevel=0.01)
    b.diamond_blade(z0=0.80, z1=4.22, width0=0.40, width1=0.34, thick0=0.11, thick1=0.08, tip_len=0.88)
    b.box((0.13, 0.12, 2.75), pos=(0, 0, 2.55))
    return b.finalize_and_export(), 5.10


def build_greatsword():
    b = MeshBuilder("Greatsword")
    b.grip_with_wraps(0.0, 2.30, 0.15, 0.19, wraps=7)
    b.cylinder(radius=0.22, depth=0.16, segments=10, pos=(0, 0, -1.24))
    b.sphere(radius=0.28, segments=10, ring_count=8, pos=(0, 0, -1.44), scale=(0.9, 1.05, 1.0))
    b.cone(radius1=0.16, radius2=0.0, depth=0.36, segments=8, pos=(0, 0, -1.78), rot=(math.pi, 0, 0))
    # Guarda colosal (ancho 2.80 studs)
    b.box((0.46, 0.92, 0.38), pos=(0, 0, 1.28), bevel=0.03)
    for s in (1, -1):
        b.box((0.36, 1.25, 0.30), pos=(0, s * 0.80, 1.34), rot=(-s * 0.12, 0, 0), bevel=0.02)
        b.cone(radius1=0.18, radius2=0.0, depth=0.42, segments=6, pos=(0, s * 1.48, 1.42), rot=(-s * 1.35, 0, 0))
    # Losa colosal (ancho 1.56, punta en z = 7.60)
    b.box((0.34, 1.36, 0.95), pos=(0, 0, 1.88), bevel=0.02)
    b.diamond_blade(z0=1.40, z1=6.50, width0=1.56, width1=1.42, thick0=0.30, thick1=0.24, tip_len=1.10)
    b.box((0.33, 0.50, 4.40), pos=(0, 0, 3.85))
    return b.finalize_and_export(), 7.60


def build_rapier():
    b = MeshBuilder("Rapier")
    b.grip_with_wraps(0.0, 1.05, 0.11, 0.12, wraps=4)
    b.sphere(radius=0.17, segments=10, ring_count=8, pos=(0, 0, -0.66))
    b.cone(radius1=0.08, radius2=0.0, depth=0.18, segments=8, pos=(0, 0, -0.86), rot=(math.pi, 0, 0))
    # Cazoleta y gavilanes
    b.sphere(radius=0.48, segments=14, ring_count=10, pos=(0, 0, 0.72), scale=(0.95, 0.95, 0.55))
    b.box((0.12, 1.55, 0.10), pos=(0, 0, 0.58), bevel=0.01)
    b.cylinder(radius=0.05, depth=0.95, segments=8, pos=(0, 0.48, 0.10), rot=(0.25, 0, 0))
    # Hoja fina de estocada (punta en z = 5.56)
    b.diamond_blade(z0=0.75, z1=4.86, width0=0.16, width1=0.11, thick0=0.09, thick1=0.07, tip_len=0.70)
    return b.finalize_and_export(), 5.56


def build_mace():
    b = MeshBuilder("Mace")
    b.grip_with_wraps(0.0, 1.40, 0.16, 0.16, wraps=5)
    b.cylinder(radius=0.20, depth=0.20, segments=10, pos=(0, 0, -0.80))
    b.cone(radius1=0.15, radius2=0.0, depth=0.35, segments=8, pos=(0, 0, -1.06), rot=(math.pi, 0, 0))
    # Vara larga reforzada
    b.cylinder(radius=0.14, depth=2.65, segments=10, pos=(0, 0, 2.02))
    b.cylinder(radius=0.18, depth=0.70, segments=10, pos=(0, 0, 3.00))
    # Cabeza de martillo / maza (punta superior en z = 4.90)
    b.box((1.05, 2.00, 1.10), pos=(0, 0, 3.78), bevel=0.04)
    b.box((1.15, 0.22, 1.18), pos=(0, 0.55, 3.78), bevel=0.02)
    b.box((1.15, 0.22, 1.18), pos=(0, -0.55, 3.78), bevel=0.02)
    b.cone(radius1=0.28, radius2=0.0, depth=0.55, segments=8, pos=(0, -1.28, 3.78), rot=(math.pi * 0.5, 0, 0))
    b.cylinder(radius=0.26, depth=0.20, segments=10, pos=(0, 0, 4.42))
    b.cone(radius1=0.16, radius2=0.0, depth=0.45, segments=8, pos=(0, 0, 4.68))
    return b.finalize_and_export(), 4.90


# ==============================================================================
# 2. SKIN DE ESPADA: REQUIEM (RequiemHorns)
# ==============================================================================

def build_requiem_horns():
    b = MeshBuilder("RequiemHorns")
    b.grip_with_wraps(0.0, 1.15, 0.12, 0.15, wraps=5)
    b.sphere(radius=0.20, segments=10, ring_count=8, pos=(0, 0, -0.72))
    b.cone(radius1=0.12, radius2=0.0, depth=0.36, segments=8, pos=(0, 0, -0.98), rot=(math.pi, 0, 0))
    # Guarda gótica con cuernos hacia adelante y atrás
    b.box((0.28, 0.66, 0.28), pos=(0, 0, 0.68), bevel=0.02)
    for s in (1, -1):
        b.cone(radius1=0.12, radius2=0.02, depth=0.92, segments=8, pos=(0, s * 0.58, 1.02), rot=(-s * 0.62, 0, 0))
        b.cone(radius1=0.09, radius2=0.02, depth=0.68, segments=8, pos=(0, s * 0.52, 0.40), rot=(-s * 2.35, 0, 0))
        b.cone(radius1=0.08, radius2=0.0, depth=0.42, segments=6, pos=(0, s * 0.34, 1.24), rot=(-s * 0.45, 0, 0))
    # Hoja gótica con muescas (punta en z = 5.14)
    b.diamond_blade(z0=0.80, z1=4.24, width0=0.44, width1=0.38, thick0=0.12, thick1=0.09, tip_len=0.90)
    b.box((0.15, 0.14, 2.85), pos=(0, 0, 2.50))
    return b.finalize_and_export(), 5.14


# ==============================================================================
# 3. SKINS DE ESPADÓN (Relic14 - Relic19)
# ==============================================================================

def build_greatsword_variant(name, tip_z, guard_wing_angle, spine_ribs=0, bindings=0, cross_halos=False):
    b = MeshBuilder(name)
    b.grip_with_wraps(0.0, 2.30, 0.15, 0.19, wraps=7)
    b.sphere(radius=0.28, segments=10, ring_count=8, pos=(0, 0, -1.44))
    b.cone(radius1=0.16, radius2=0.0, depth=0.38, segments=8, pos=(0, 0, -1.78), rot=(math.pi, 0, 0))
    # Guarda monumental
    b.box((0.46, 1.00, 0.42), pos=(0, 0, 1.28), bevel=0.03)
    for s in (1, -1):
        b.box((0.36, 1.30, 0.32), pos=(0, s * 0.84, 1.36), rot=(-s * guard_wing_angle, 0, 0), bevel=0.02)
        b.cone(radius1=0.18, radius2=0.0, depth=0.48, segments=6, pos=(0, s * 1.48, 1.48), rot=(-s * 1.2, 0, 0))
    if cross_halos:
        b.cylinder(radius=0.68, depth=0.12, segments=16, pos=(0, 0, 1.36), rot=(0, math.pi * 0.5, 0))
    # Hoja colosal
    b.diamond_blade(z0=1.40, z1=tip_z - 1.15, width0=1.56, width1=1.42, thick0=0.30, thick1=0.24, tip_len=1.15)
    for i in range(spine_ribs):
        z = 1.95 + i * 0.56
        for s in (1, -1):
            b.cone(radius1=0.12, radius2=0.0, depth=0.36, segments=6, pos=(0, s * 0.78, z), rot=(-s * 0.9, 0, 0))
    for i in range(bindings):
        z = 1.85 + i * 0.42
        b.box((0.34, 1.54, 0.16), pos=(0, 0, z), rot=(0.14 if i % 2 == 0 else -0.14, 0, 0))
    return b.finalize_and_export(), tip_z


# ==============================================================================
# 4. MAZAS ÓSEAS / MONSTRUOSAS (AncientMaw + Maw02, Maw03, Maw04)
# ==============================================================================

def build_bone_mace(name, tip_z, variant):
    b = MeshBuilder(name)
    b.grip_with_wraps(0.0, 1.40, 0.16, 0.16, wraps=5)
    b.sphere(radius=0.22, segments=10, ring_count=8, pos=(0, 0, -0.82))
    b.cone(radius1=0.14, radius2=0.0, depth=0.36, segments=8, pos=(0, 0, -1.10), rot=(math.pi, 0, 0))
    # Vara ósea / columna vertebral
    b.cylinder(radius=0.15, depth=2.60, segments=10, pos=(0, 0, 2.00))
    for i in range(5):
        z = 1.05 + i * 0.45
        b.cylinder(radius=0.21, depth=0.14, segments=8, pos=(0, 0, z))
    # Cabeza monstruosa en z = 3.15 .. 4.45
    b.sphere(radius=0.58, segments=12, ring_count=10, pos=(0, 0, 3.80), scale=(0.95, 1.25, 1.15))
    if variant == "maw":
        # Mandíbulas con colmillos laterales
        for s in (1, -1):
            b.box((0.48, 0.55, 1.05), pos=(0, s * 0.52, 3.82), rot=(s * 0.18, 0, 0), bevel=0.03)
            for k in range(4):
                zk = 3.40 + k * 0.26
                b.cone(radius1=0.09, radius2=0.0, depth=0.32, segments=6, pos=(0, s * 0.82, zk), rot=(-s * 1.45, 0, 0))
    elif variant == "vertebra":
        # Discos vertebrales gigantes con costillas y púas dorsales
        for k in range(4):
            zk = 3.32 + k * 0.34
            b.cylinder(radius=0.62, depth=0.18, segments=10, pos=(0, 0, zk), scale=(0.88, 1.15, 1.0))
            for s in (1, -1):
                b.cone(radius1=0.12, radius2=0.0, depth=0.52, segments=6, pos=(0, s * 0.76, zk), rot=(-s * 1.40, 0, 0))
    elif variant == "jaws":
        # Doble fauces abisales abrazando núcleo de ámbar
        b.sphere(radius=0.42, segments=10, ring_count=8, pos=(0, 0, 3.82))
        for s in (1, -1):
            b.cone(radius1=0.26, radius2=0.04, depth=1.15, segments=8, pos=(0, s * 0.64, 3.88), rot=(-s * 0.35, 0, 0))
            for k in range(3):
                zk = 3.48 + k * 0.32
                b.cone(radius1=0.10, radius2=0.0, depth=0.36, segments=6, pos=(0, s * 0.46, zk), rot=(s * 1.35, 0, 0))
    elif variant == "crown":
        # Tres caras de cráneo y corona de astas óseas
        for s in (1, -1):
            b.sphere(radius=0.38, segments=10, ring_count=8, pos=(0, s * 0.48, 3.76), scale=(0.9, 1.0, 1.1))
        for i in range(8):
            ang = i * (2.0 * math.pi / 8.0)
            px = math.cos(ang) * 0.44
            py = math.sin(ang) * 0.44
            b.cone(radius1=0.08, radius2=0.0, depth=0.38, segments=6, pos=(px, py, 4.36))
    # Espolón apical hasta tip_z
    spike_len = max(0.32, tip_z - 4.42)
    b.cone(radius1=0.18, radius2=0.0, depth=spike_len, segments=8, pos=(0, 0, tip_z - spike_len * 0.5))
    return b.finalize_and_export(), tip_z


def main():
    builders = [
        ("Dagger", build_dagger),
        ("Sword", build_sword),
        ("Greatsword", build_greatsword),
        ("Rapier", build_rapier),
        ("Mace", build_mace),
        ("RequiemHorns", build_requiem_horns),
        ("EmeraldTomb", lambda: build_greatsword_variant("EmeraldTomb", 7.60, 0.18, spine_ribs=3)),
        ("Devourer", lambda: build_greatsword_variant("Devourer", 7.60, -0.22, spine_ribs=5)),
        ("RoyalMourning", lambda: build_greatsword_variant("RoyalMourning", 7.60, 0.10, cross_halos=True)),
        ("DuskCross", lambda: build_greatsword_variant("DuskCross", 7.60, 0.05, cross_halos=True)),
        ("Shroud", lambda: build_greatsword_variant("Shroud", 7.58, 0.12, bindings=8)),
        ("AbyssWings", lambda: build_greatsword_variant("AbyssWings", 7.60, 0.35, spine_ribs=4)),
        ("AncientMaw", lambda: build_bone_mace("AncientMaw", 4.85, "maw")),
        ("AbyssVertebra", lambda: build_bone_mace("AbyssVertebra", 4.90, "vertebra")),
        ("SepulcherJaws", lambda: build_bone_mace("SepulcherJaws", 4.88, "jaws")),
        ("OssuaryCrown", lambda: build_bone_mace("OssuaryCrown", 4.90, "crown")),
    ]
    print("=== Generando mallas en modelos_armas/ ===")
    for name, fn in builders:
        tris, tip_z = fn()
        print(f"  [OK] {name:<16} -> {tris:4d} tris | TipZ = {tip_z:.2f} studs (.obj + .fbx)")
    print("=== Exportación completada ===")


if __name__ == "__main__":
    import traceback
    log_path = os.path.join(OUT_DIR, "build_log.txt")
    with open(log_path, "w", encoding="utf-8") as log_file:
        try:
            builders = [
                ("Dagger", build_dagger),
                ("Sword", build_sword),
                ("Greatsword", build_greatsword),
                ("Rapier", build_rapier),
                ("Mace", build_mace),
                ("RequiemHorns", build_requiem_horns),
                ("EmeraldTomb", lambda: build_greatsword_variant("EmeraldTomb", 7.60, 0.18, spine_ribs=3)),
                ("Devourer", lambda: build_greatsword_variant("Devourer", 7.60, -0.22, spine_ribs=5)),
                ("RoyalMourning", lambda: build_greatsword_variant("RoyalMourning", 7.60, 0.10, cross_halos=True)),
                ("DuskCross", lambda: build_greatsword_variant("DuskCross", 7.60, 0.05, cross_halos=True)),
                ("Shroud", lambda: build_greatsword_variant("Shroud", 7.58, 0.12, bindings=8)),
                ("AbyssWings", lambda: build_greatsword_variant("AbyssWings", 7.60, 0.35, spine_ribs=4)),
                ("AncientMaw", lambda: build_bone_mace("AncientMaw", 4.85, "maw")),
                ("AbyssVertebra", lambda: build_bone_mace("AbyssVertebra", 4.90, "vertebra")),
                ("SepulcherJaws", lambda: build_bone_mace("SepulcherJaws", 4.88, "jaws")),
                ("OssuaryCrown", lambda: build_bone_mace("OssuaryCrown", 4.90, "crown")),
            ]
            log_file.write("=== Generando mallas en modelos_armas/ ===\n")
            for name, fn in builders:
                tris, tip_z = fn()
                line = f"  [OK] {name:<16} -> {tris:4d} tris | TipZ = {tip_z:.2f} studs (.obj + .fbx)\n"
                print(line, end="")
                log_file.write(line)
                log_file.flush()
            log_file.write("=== Exportación completada ===\n")
        except Exception:
            log_file.write(traceback.format_exc())

