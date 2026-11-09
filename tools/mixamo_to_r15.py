# Convierte animaciones FBX de Mixamo a poses R15 para ReplicatedStorage/AnimClips (formato de poses).
# Uso (Blender en segundo plano):
#   blender -b --python tools/mixamo_to_r15.py -- <salida.json> <fbx1> <fbx2> ...
# Por cada FBX guarda: duración, momento del golpe (máxima velocidad de la mano derecha),
# preparación (mínimo antes del golpe) y keyframes { t, { Articulación = {rx, ry, rz [, px, py, pz]} } }.
# Método: para cada hueso, rotación de la pose respecto de la pose de descanso (T-pose) en el espacio
# del personaje; se aplica a la parte R15 (brazos corregidos de T-pose a brazos abajo) y se pasa a
# Motor6D.Transform = rot(Part0)^-1 * rot(Part1). Euler en el orden de CFrame.Angles (Rx*Ry*Rz).
import bpy, sys, json, math, os
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT, FILES = argv[0], argv[1:]
STEP = 2  # muestrear cada 2 frames

PARTS = {  # parte R15 -> hueso de Mixamo (sufijo)
    "LowerTorso": "Hips", "UpperTorso": "Spine2", "Head": "Head",
    "RightUpperArm": "RightArm", "RightLowerArm": "RightForeArm", "RightHand": "RightHand",
    "LeftUpperArm": "LeftArm", "LeftLowerArm": "LeftForeArm", "LeftHand": "LeftHand",
    "RightUpperLeg": "RightUpLeg", "RightLowerLeg": "RightLeg", "RightFoot": "RightFoot",
    "LeftUpperLeg": "LeftUpLeg", "LeftLowerLeg": "LeftLeg", "LeftFoot": "LeftFoot",
}
ARMS = {"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand"}
JOINTS = {  # clave AnimClips -> (Part0, Part1)
    "R": (None, "LowerTorso"), "W": ("LowerTorso", "UpperTorso"), "N": ("UpperTorso", "Head"),
    "RS": ("UpperTorso", "RightUpperArm"), "RE": ("RightUpperArm", "RightLowerArm"), "RW": ("RightLowerArm", "RightHand"),
    "LS": ("UpperTorso", "LeftUpperArm"), "LE": ("LeftUpperArm", "LeftLowerArm"), "LW": ("LeftLowerArm", "LeftHand"),
    "RH": ("LowerTorso", "RightUpperLeg"), "RK": ("RightUpperLeg", "RightLowerLeg"), "RA": ("RightLowerLeg", "RightFoot"),
    "LH": ("LowerTorso", "LeftUpperLeg"), "LK": ("LeftUpperLeg", "LeftLowerLeg"), "LA": ("LeftLowerLeg", "LeftFoot"),
}
R15_HIP_TO_ANKLE = 1.9  # studs


def find(arm, suffix):
    for b in arm.pose.bones:
        if b.name.split(":")[-1] == suffix:
            return b
    return None


def euler_xyz(m):
    # m = Rx(a) * Ry(b) * Rz(c)
    b = math.asin(max(-1.0, min(1.0, m[0][2])))
    a = math.atan2(-m[1][2], m[2][2])
    c = math.atan2(-m[0][1], m[0][0])
    return [round(math.degrees(a), 1), round(math.degrees(b), 1), round(math.degrees(c), 1)]


def arc(u, v):
    u, v = u.normalized(), v.normalized()
    axis = u.cross(v)
    if axis.length < 1e-6:
        return Matrix.Identity(3)
    return Matrix.Rotation(math.acos(max(-1, min(1, u.dot(v)))), 3, axis.normalized())


def convert(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=path, automatic_bone_orientation=False)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    act = arm.animation_data.action if arm.animation_data else None
    f0, f1 = (int(act.frame_range[0]), int(act.frame_range[1])) if act else (1, 1)
    fps = bpy.context.scene.render.fps / bpy.context.scene.render.fps_base
    bones = {p: find(arm, s) for p, s in PARTS.items()}
    if any(b is None for b in bones.values()):
        return {"error": "faltan huesos"}
    W = arm.matrix_world
    # Base Blender -> Roblox con el frente del personaje sacado de los pies
    rest = {p: W @ b.bone.matrix_local for p, b in bones.items()}
    toe = find(arm, "RightToeBase")
    up = Vector((0, 0, 1))
    fwd = ((W @ toe.bone.head_local) - rest["RightFoot"].translation) if toe else Vector((0, -1, 0))
    fwd.z = 0
    fwd.normalize()
    right = fwd.cross(up)
    P = Matrix((right, up, -fwd))  # filas: x_r, y_r, z_r
    PT = P.transposed()
    restRot = {p: m.to_3x3().normalized() for p, m in rest.items()}
    # Corrección T-pose -> brazos abajo de R15
    toff = {}
    for p in PARTS:
        if p in ARMS:
            b = bones[p].bone
            d = P @ ((W @ b.tail_local) - (W @ b.head_local))
            toff[p] = arc(Vector((0, -1, 0)), d)
        else:
            toff[p] = Matrix.Identity(3)
    hip0 = rest["LowerTorso"].translation
    scale = R15_HIP_TO_ANKLE / max(0.1, (hip0 - rest["RightFoot"].translation).z)
    frames, speeds, start = [], [], None
    prevHand = None
    for f in range(f0, f1 + 1):
        bpy.context.scene.frame_set(f)
        rot = {}
        for p, b in bones.items():
            m = W @ b.matrix
            D = P @ (m.to_3x3().normalized() @ restRot[p].transposed()) @ PT
            rot[p] = D @ toff[p]
        hand = W @ bones["RightHand"].matrix
        hp = hand.translation.copy()
        speeds.append(0 if prevHand is None else (hp - prevHand).length * fps)
        prevHand = hp
        if (f - f0) % STEP != 0 and f != f1:
            continue
        pose = {}
        for j, (p0, p1) in JOINTS.items():
            r0 = Matrix.Identity(3) if p0 is None else rot[p0]
            pose[j] = euler_xyz(r0.transposed() @ rot[p1])
        hips = W @ bones["LowerTorso"].matrix
        pos = P @ (hips.translation - hip0) * scale
        if start is None:
            start = pos.copy()
        dx = max(-1.5, min(1.5, (pos.x - start.x) * 0.5))
        dz = max(-1.5, min(1.5, (pos.z - start.z) * 0.5))
        pose["R"] += [round(dx, 2), round(pos.y, 2), round(dz, 2)]
        frames.append([round((f - f0) / max(1, f1 - f0), 3), pose])
    hitF = max(range(len(speeds)), key=lambda i: speeds[i])
    windF = hitF
    while windF > 1 and speeds[windF - 1] <= speeds[windF]:
        windF -= 1
    n = max(1, f1 - f0)
    return {"dur": round((f1 - f0) / fps, 3), "hit": round(hitF / n, 3), "windup": round(windF / n, 3),
            "peak": round(max(speeds), 2), "keys": frames}


result = {}
for f in FILES:
    name = os.path.splitext(os.path.basename(f))[0]
    try:
        result[name] = convert(f)
    except Exception as e:
        result[name] = {"error": str(e)}
with open(OUT, "w") as fh:
    json.dump(result, fh)
