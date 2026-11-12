"""Modelo piloto 0.3 de Corte de Plata, basado en la referencia de Relic21."""
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import generate_weapons as kit


def assign_blade_uv(builder, face, role, blade_start, blade_tip):
    cell = kit.ROLE_INDEX[role]
    col, row = cell % 2, cell // 2
    for loop in face.loops:
        x, _, z = loop.vert.co
        u = (z - blade_start) / (blade_tip - blade_start)
        v = 0.5 + x * 4.0
        loop[builder.uv_layer].uv = (col * 0.5 + 0.04 + u * 0.42, row * 0.25 + 0.03 + v * 0.19)


def make_blade(builder):
    # Secciones de una sola malla: lomo grueso, caras planas y un filo biselado.
    sections = (
        (0.68, 0.00, 0.24, 0.114), (1.18, 0.00, 0.23, 0.109),
        (1.85, 0.02, 0.225, 0.103), (2.55, 0.05, 0.216, 0.098),
        (3.22, 0.10, 0.205, 0.092), (3.91, 0.18, 0.185, 0.083),
        (4.52, 0.28, 0.158, 0.070), (4.93, 0.35, 0.111, 0.056),
        (5.16, 0.40, 0.059, 0.034),
    )
    outline = ((-0.45, -0.5), (0.45, -0.5), (0.50, 0.18), (0.025, 0.50), (-0.025, 0.50), (-0.50, 0.18))
    bands = ("Trim", "Blade", "Edge", "Edge", "Edge", "Blade")
    rings = [
        [builder.bm.verts.new((x * depth, y + dy * width, z)) for x, dy in outline]
        for z, y, width, depth in sections
    ]
    start = sections[0][0]
    end = 5.30
    tip = builder.bm.verts.new((0, 0.42, end))
    cap = builder.bm.faces.new(tuple(reversed(rings[0])))
    assign_blade_uv(builder, cap, "Blade", start, end)
    for a, b in zip(rings, rings[1:]):
        for i, role in enumerate(bands):
            j = (i + 1) % len(bands)
            face = builder.bm.faces.new((a[i], a[j], b[j], b[i]))
            assign_blade_uv(builder, face, role, start, end)
    for i, role in enumerate(bands):
        j = (i + 1) % len(bands)
        face = builder.bm.faces.new((rings[-1][i], rings[-1][j], tip))
        assign_blade_uv(builder, face, role, start, end)


def rail(builder, points, radius, role):
    # Aro continuo. La sección sigue la tangente del recorrido.
    points = [Vector(v) for v in points]
    rings = []
    for i, center in enumerate(points):
        tangent = (points[min(len(points) - 1, i + 1)] - points[max(0, i - 1)]).normalized()
        across = tangent.cross(Vector((1, 0, 0))).normalized()
        rings.append([
            builder.bm.verts.new(center + Vector((math.cos(a) * radius, 0, 0)) + across * (math.sin(a) * radius * 0.72))
            for a in (j * math.tau / 8 for j in range(8))
        ])
    builder.bm.faces.new(tuple(reversed(rings[0])))
    for a, b in zip(rings, rings[1:]):
        for i in range(8):
            j = (i + 1) % 8
            builder.bm.faces.new((a[i], a[j], b[j], b[i]))
    builder.bm.faces.new(tuple(rings[-1]))
    builder._assign_role_uv([vert for ring in rings for vert in ring], role)


def make_hilt(builder):
    builder.cylinder(0.104, 0.95, segments=18, scale=(0.92, 1.09, 1), role="Grip")
    for z in (-0.38, -0.26, -0.14, -0.02, 0.1, 0.22, 0.34):
        builder.cylinder(0.110, 0.025, segments=16, pos=(0, 0, z), rot=(0.22, 0, 0),
                         scale=(0.91, 1.07, 1), role="Dark")
    for z, radius, depth, role in (
        (-0.68, 0.12, 0.06, "Trim"), (-0.61, 0.155, 0.10, "Accent"),
        (-0.49, 0.121, 0.06, "Trim"), (0.46, 0.126, 0.06, "Trim"),
        (0.55, 0.245, 0.05, "Accent"), (0.61, 0.127, 0.085, "Accent"),
        (0.68, 0.129, 0.04, "Trim"),
    ):
        builder.cylinder(radius, depth, segments=18, pos=(0, 0, z), scale=(0.82, 1.1, 1), role=role)
    rail(builder, [(0, y, z) for y, z in (
        (0.11, 0.54), (0.30, 0.45), (0.43, 0.31), (0.50, 0.10), (0.50, -0.12),
        (0.43, -0.31), (0.31, -0.47), (0.19, -0.60), (0.16, -0.69), (0.20, -0.78),
    )], 0.047, "Accent")
    rail(builder, [(0, y, z) for y, z in (
        (0.10, 0.56), (-0.05, 0.57), (-0.20, 0.61), (-0.34, 0.66), (-0.43, 0.64), (-0.46, 0.58),
    )], 0.042, "Accent")
    rail(builder, [(0, y, z) for y, z in (
        (0.12, 0.58), (0.26, 0.57), (0.30, 0.50), (0.27, 0.43), (0.14, 0.43),
    )], 0.030, "Trim")
    builder.sphere(0.054, segments=10, ring_count=6, pos=(0, 0.50, -0.12), scale=(0.94, 1.25, 1.65), role="Trim")


def preview(output):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.world = bpy.data.worlds.new("Pizarra")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.052, 0.060, 0.073, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.65
    target = Vector((0, 0.02, 2.26))
    bpy.ops.object.camera_add(location=(8.5, -1.15, 2.52))
    camera = bpy.context.object
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 7.15
    scene.camera = camera
    for name, position, energy, size in (
        ("Luz principal", (4, -3, 5), 580, 4),
        ("Relleno", (4, 3, 1.3), 290, 4),
        ("Contraluz", (-3, 0, 4), 400, 3),
    ):
        bpy.ops.object.light_add(type="AREA", location=position)
        light = bpy.context.object
        light.name = name
        light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()
        light.data.energy = energy
        light.data.size = size
    scene.render.resolution_x = 448
    scene.render.resolution_y = 960
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output / "SilverCut_preview.png")
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "SilverCut.blend"))
    bpy.ops.render.render(write_still=True)


def main(output):
    output.mkdir(parents=True, exist_ok=True)
    kit.OUT_DIR = str(output)
    palette = {
        "Blade": (0.24, 0.26, 0.29), "Edge": (0.66, 0.70, 0.75),
        "Accent": (0.20, 0.21, 0.24), "Trim": (0.43, 0.46, 0.49),
        "Grip": (0.085, 0.067, 0.053), "Dark": (0.13, 0.10, 0.075),
    }
    builder = kit.MeshBuilder("SilverCut", palette)
    make_blade(builder)
    make_hilt(builder)
    triangles = builder.finalize_and_export()
    print(f"Corte de Plata: {triangles} triangulos | punta 5.30 studs", flush=True)
    preview(output)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:]
    output = Path(args[0]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    try:
        main(output)
    except Exception:
        (output / "blender_error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        raise
