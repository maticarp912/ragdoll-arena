"""Piloto de Vigilia Violeta (Relic10). Ejecutar Blender en segundo plano.

blender --background --python tools/blender/vigilia_violeta_v03.py -- referencia.jpg destino
"""
from pathlib import Path
from shutil import copyfile
from math import cos, sin, tau
import json
import sys
import traceback

import bpy
from bpy_extras.io_utils import axis_conversion
from mathutils import Vector

CENTER_X = 395
GRIP_Y = 1300
PIXEL_SCALE = 5.3 / (GRIP_Y - 29)
SIDES = 24
BLADE_DEPTH = 0.055

# La geometría se mide en la vista frontal de la referencia.
BLADE_EDGE = [
    (29, 395), (47, 403), (66, 410), (83, 416), (105, 420),
    (180, 421), (395, 423), (635, 426), (778, 430), (980, 432), (1115, 434),
]
GUARD_EDGE = [
    (1018, 395), (1048, 405), (1073, 421), (1101, 449), (1136, 457),
    (1128, 490), (1117, 517), (1105, 550), (1122, 538), (1140, 521),
    (1164, 487), (1182, 451), (1200, 435), (1217, 415), (1221, 395),
]
POMMEL_EDGE = [
    (1373, 395), (1373, 414), (1390, 418), (1404, 432), (1427, 431),
    (1443, 414), (1452, 405), (1450, 395),
]


def point(x, y, depth=0):
    return (depth, (x - CENTER_X) * PIXEL_SCALE, (GRIP_Y - y) * PIXEL_SCALE)


def material_for(image, metallic, roughness):
    material = bpy.data.materials.new("Vigilia Violeta · referencia")
    material.use_nodes = True
    tree = material.node_tree
    shader = tree.nodes.get("Principled BSDF")
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    return material


def mesh_object(name, vertices, faces, material):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(material)
    return obj


def project(obj, image, coordinates=None):
    mesh = obj.data
    uv = mesh.uv_layers.new(name="Proyección frontal")
    width, height = image.size
    for loop in mesh.loops:
        v = mesh.vertices[loop.vertex_index].co
        x, y = coordinates[loop.vertex_index] if coordinates else (
            CENTER_X + v.y / PIXEL_SCALE, GRIP_Y - v.z / PIXEL_SCALE,
        )
        uv.data[loop.index].uv = ((x + 0.5) / width, 1 - (y + 0.5) / height)


def mirrored_solid(obj, image, depth, bevel):
    mirror = obj.modifiers.new("Simetría de la silueta", "MIRROR")
    mirror.use_axis[0] = False
    mirror.use_axis[1] = True
    mirror.use_mirror_merge = True
    mirror.merge_threshold = 0.00005
    mirror.use_mirror_u = True
    mirror.mirror_offset_u = 2 * (CENTER_X + 0.5) / image.size[0] - 1
    solid = obj.modifiers.new("Espesor", "SOLIDIFY")
    solid.thickness = depth
    solid.offset = 0
    solid.use_even_offset = True
    edge = obj.modifiers.new("Bisel", "BEVEL")
    edge.width = bevel
    edge.segments = 1
    edge.angle_limit = 0.45


def blade(image, metal):
    vertices = [point(CENTER_X, BLADE_EDGE[0][0])]
    for y, x in BLADE_EDGE[1:]:
        vertices.extend((point(CENTER_X, y), point(x - 1, y)))
    faces = [(0, 2, 1)]
    for i in range(1, len(vertices) - 2, 2):
        faces.append((i, i + 1, i + 3, i + 2))
    obj = mesh_object("Hoja", vertices, faces, metal)
    project(obj, image)
    mirrored_solid(obj, image, BLADE_DEPTH, 0.008)
    return obj


def ornament(name, silhouette, image, metal, depth):
    obj = mesh_object(name, [point(x, y) for y, x in silhouette], [tuple(range(len(silhouette)))], metal)
    project(obj, image)
    mirrored_solid(obj, image, depth, 0.012)
    return obj


def grip(image, leather):
    # Anillos de 24 lados. La sección oval y los diámetros siguen la empuñadura de cuero de la imagen.
    rings = [
        (1208, 0.082), (1222, 0.081), (1230, 0.074), (1248, 0.076), (1261, 0.071),
        (1280, 0.074), (1293, 0.069), (1312, 0.073), (1327, 0.069), (1345, 0.074),
        (1361, 0.077), (1378, 0.083), (1390, 0.082),
    ]
    vertices, uv_pixels, faces = [], [], []
    for y, radius in rings:
        z = (GRIP_Y - y) * PIXEL_SCALE
        for i in range(SIDES):
            angle = tau * i / SIDES
            vertices.append((0.88 * radius * cos(angle), radius * sin(angle), z))
            uv_pixels.append((CENTER_X + sin(angle) * 14, y))
    faces.append(tuple(range(SIDES)))
    for ring in range(len(rings) - 1):
        offset = ring * SIDES
        for i in range(SIDES):
            j = (i + 1) % SIDES
            faces.append((offset + j, offset + i, offset + i + SIDES, offset + j + SIDES))
    faces.append(tuple(reversed(range(len(vertices) - SIDES, len(vertices)))))
    obj = mesh_object("Mango · 24 lados", vertices, faces, leather)
    for polygon in obj.data.polygons:
        polygon.use_smooth = len(polygon.vertices) == 4
    project(obj, image, uv_pixels)
    return obj


def raised_detail(name, pixel_y, radii, image, metal):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=1)
    obj = bpy.context.object
    obj.name = name
    for vertex in obj.data.vertices:
        vertex.co.x *= radii[0]
        vertex.co.y *= radii[1]
        vertex.co.z = vertex.co.z * radii[2] + (GRIP_Y - pixel_y) * PIXEL_SCALE
    obj.data.materials.append(metal)
    for face in obj.data.polygons:
        face.use_smooth = True
    project(obj, image)
    return obj


def select_only(objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


def export_mesh(parts, output, texture):
    deps = bpy.context.evaluated_depsgraph_get()
    copies = []
    for part in parts:
        mesh = bpy.data.meshes.new_from_object(part.evaluated_get(deps), preserve_all_data_layers=True, depsgraph=deps)
        obj = bpy.data.objects.new(part.name + " · export", mesh)
        bpy.context.collection.objects.link(obj)
        copies.append(obj)
    select_only(copies)
    bpy.ops.object.join()
    merged = bpy.context.object
    merged.name = "VigiliaVioleta"
    merged.data.calc_loop_triangles()
    triangles = len(merged.data.loop_triangles)
    if not 0 < triangles < 2000:
        raise RuntimeError(f"Presupuesto de la malla: {triangles} triángulos")
    # El origen queda en el mango y la punta sale sobre +Z en los ejes del FBX.
    merged.data.transform(axis_conversion(to_forward="Z", to_up="Y").to_4x4().inverted())
    bpy.ops.export_scene.fbx(
        filepath=str(output / "VigiliaVioleta.fbx"), use_selection=True,
        axis_forward="Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=True,
        path_mode="COPY", embed_textures=True, add_leaf_bones=False,
    )
    bpy.data.objects.remove(merged, do_unlink=True)
    return {"triangles": triangles, "gripSides": SIDES, "bladeDepth": BLADE_DEPTH,
            "bladeBase": [0, 0, round((GRIP_Y - 1115) * PIXEL_SCALE, 4)],
            "bladeTip": [0, 0, 5.3], "texture": texture.name}


def preview(output, parts):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "AgX"
    scene.world = bpy.data.worlds.new("Pizarra")
    scene.world.use_nodes = True
    ambient = scene.world.node_tree.nodes["Background"]
    ambient.inputs["Color"].default_value = (0.075, 0.085, 0.11, 1)
    ambient.inputs["Strength"].default_value = 0.55
    target = Vector((0, 0, 2.28))
    bpy.ops.object.camera_add(location=(9, -1.25, 2.7))
    camera = bpy.context.object
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 7.0
    scene.camera = camera
    for position, energy, size in (((4, -3, 5), 510, 4), ((3, 4, 3), 260, 3), ((-4, 2, 5), 420, 3)):
        bpy.ops.object.light_add(type="AREA", location=position)
        lamp = bpy.context.object
        lamp.rotation_euler = (target - lamp.location).to_track_quat("-Z", "Y").to_euler()
        lamp.data.energy = energy
        lamp.data.size = size
    scene.render.resolution_x = 480
    scene.render.resolution_y = 850
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = "//VigiliaVioleta_preview.png"
    select_only(parts)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "VigiliaVioleta.blend"), compress=True)
    bpy.ops.render.render(write_still=True)


def main(reference, output):
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    texture = output / "VigiliaVioleta_tex.jpg"
    copyfile(reference, texture)
    image = bpy.data.images.load(str(texture))
    if tuple(image.size) != (878, 1500):
        raise RuntimeError("La proyección requiere la referencia original de 878 × 1500")
    metal, leather = material_for(image, 0.66, 0.34), material_for(image, 0.03, 0.68)
    leather.name = "Cuero oscuro · referencia"
    parts = [
        blade(image, metal),
        ornament("Guarda en V", GUARD_EDGE, image, metal, 0.12),
        grip(image, leather),
        ornament("Pomo", POMMEL_EDGE, image, metal, 0.12),
        raised_detail("Centro de guarda", 1165, (0.098, 0.17, 0.15), image, metal),
        raised_detail("Órbita del pomo", 1427, (0.078, 0.075, 0.082), image, metal),
    ]
    metadata = export_mesh(parts, output, texture)
    (output / "VigiliaVioleta_modelo.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    preview(output, parts)


if __name__ == "__main__":
    reference, output = map(Path, sys.argv[sys.argv.index("--") + 1:])
    try:
        main(reference, output)
    except Exception:
        (output / "VigiliaVioleta_error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        raise

