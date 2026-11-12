"""Exporta y adapta los tres fuertes de Espada al rig R15 medido en Studio."""
from pathlib import Path
import json
import math
import sys
import traceback

from mathutils import Matrix, Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mixamo_to_r15 import convert, euler_xyz

SOURCES = {
    "SwordHeavyUp": "Standing Melee Attack Downward.fbx",
    "SwordHeavyLeft": "Sword And Shield Attack.fbx",
    "SwordHeavyRight": "Standing Melee Attack Backhand.fbx",
}
AXES = ("X", "Y", "Z")
TORSO_MARGIN = 0.065
CORRECTION_MARGIN = 0.13


def cframe(value):
    return Matrix([value[3 + i * 3:6 + i * 3] + [value[i]] for i in range(3)] + [[0, 0, 0, 1]])


def rotation(values):
    result = Matrix.Identity(3)
    for angle, axis in zip(values[:3], AXES):
        result = result @ Matrix.Rotation(math.radians(angle), 3, axis)
    return result


def transform(values):
    result = rotation(values).to_4x4()
    if len(values) == 6:
        result.translation = Vector(values[3:])
    return result


def segment_in_box(a, b, extents):
    """Prueba de losas contra la caja del torso en el espacio de la pieza."""
    lo, hi = 0.0, 1.0
    delta = b - a
    for origin, velocity, limit in zip(a, delta, extents):
        if abs(velocity) < 1e-7:
            if abs(origin) > limit:
                return False
            continue
        near, far = sorted(((-limit - origin) / velocity, (limit - origin) / velocity))
        lo, hi = max(lo, near), min(hi, far)
        if lo > hi:
            return False
    return True


class SwordRig:
    def __init__(self, rig):
        self.joints = {key: (cframe(pair[0]), cframe(pair[1]).inverted()) for key, pair in rig["joints"].items()}
        self.hand_grip = cframe(rig["grip"][0])
        self.handle_grip = cframe(rig["grip"][1])
        self.to_handle = self.hand_grip @ self.handle_grip.inverted()
        self.blade_base = Vector(rig["bladeBase"])
        self.blade_tip = Vector(rig["bladeTip"])
        self.lower_box = Vector(rig["lower"]) / 2
        self.upper_box = Vector(rig["upper"]) / 2

    def link(self, parent, joint, pose):
        c0, inv_c1 = self.joints[joint]
        return parent @ c0 @ transform(pose[joint]) @ inv_c1

    def solve_pose(self, pose):
        lower = self.link(Matrix.Identity(4), "R", pose)
        upper = self.link(lower, "W", pose)
        shoulder = self.link(upper, "RS", pose)
        elbow = self.link(shoulder, "RE", pose)
        wrist = self.link(elbow, "RW", pose)
        return lower, upper, wrist, wrist @ self.to_handle

    def intersects(self, frames, margin=TORSO_MARGIN):
        lower, upper, _, handle = frames
        start, end = handle @ self.blade_base, handle @ self.blade_tip
        for torso, box in ((lower, self.lower_box), (upper, self.upper_box)):
            inv = torso.inverted()
            if segment_in_box(inv @ start, inv @ end, box + Vector((margin,) * 3)):
                return True
        return False


def free_left_arm(pose):
    # En este perfil de una mano el brazo izquierdo conserva el contrapeso.
    # Reducir la pose de origen evita simular un escudo en la mano libre.
    for joint, reference, weight in (
        ("LS", (8, 0, -19), 0.57), ("LE", (19, 0, 0), 0.55), ("LW", (0, 0, 0), 0.45),
    ):
        pose[joint] = [base + (value - base) * weight for base, value in zip(reference, pose[joint])]


def correction_candidates():
    # Primero buscamos cambios chicos en muñeca y hombro. Después abrimos el brazo.
    options = [(0, 0, 0, 0)]
    for spread in (0, 8, 16, 26, 39, 54, 70):
        for yaw in (0, -12, 12, -24, 24, -40, 40, -64, 64, -88, 88):
            for pitch in (0, -12, 12, -24, 24, -40, 40, -64, 64, -88, 88):
                if spread == yaw == pitch == 0:
                    continue
                cost = math.hypot(yaw, pitch) + spread * 1.4
                options.append((cost, spread, pitch, yaw))
    return sorted(options)


CORRECTIONS = correction_candidates()


def correct(rig, pose, last_delta):
    source = rig.solve_pose(pose)
    rw = rotation(pose["RW"])
    rs = rotation(pose["RS"])
    best = None
    # Partimos del último ajuste para favorecer continuidad entre cuadros.
    choices = sorted(CORRECTIONS, key=lambda item: item[0] + 0.55 * math.dist(item[1:], last_delta))
    for _, spread, pitch, yaw in choices:
        fixed = dict(pose)
        if spread:
            fixed["RS"] = euler_xyz(Matrix.Rotation(math.radians(spread), 3, "Z") @ rs)
        if pitch or yaw:
            wrist_adjustment = Matrix.Rotation(math.radians(pitch), 3, "X") @ Matrix.Rotation(math.radians(yaw), 3, "Y")
            fixed["RW"] = euler_xyz(rw @ wrist_adjustment)
        frames = rig.solve_pose(fixed)
        if not rig.intersects(frames, CORRECTION_MARGIN):
            best = (fixed, frames, (spread, pitch, yaw))
            break
    if best is None:
        return pose, source, source, (0, 0, 0)
    return best[0], source, best[1], best[2]


def unwrap(values, previous):
    if previous is not None:
        return [angle + 360 * round((prior - angle) / 360) for angle, prior in zip(values[:3], previous[:3])] + values[3:]
    return values



def interpolate_pose(a, b, alpha):
    return {key: [x + (y - x) * alpha for x, y in zip(a[key], b[key])] for key in a}


def refine_interval(rig, a, b, depth=0):
    for alpha in (0.5, 0.25, 0.75):
        middle = interpolate_pose(a[1], b[1], alpha)
        if not rig.intersects(rig.solve_pose(middle)):
            continue
        if depth >= 6:
            break
        fixed, _, frames, _ = correct(rig, middle, (0, 0, 0))
        if rig.intersects(frames):
            break
        point = [round(a[0] + (b[0] - a[0]) * alpha, 5),
                 {key: unwrap(values, middle[key]) for key, values in fixed.items()}]
        return refine_interval(rig, a, point, depth + 1) + refine_interval(rig, point, b, depth + 1)
    return [b]


def slice_attack(src):
    duration, keys = src["dur"], src["keys"]
    hit, windup = src["hit"], src["windup"]
    start = max(0, windup - 0.38 / duration)
    end = min(1, hit + 0.48 / duration)
    cropped = [(t, pose) for t, pose in keys if start <= t <= end]
    start, end = cropped[0][0], cropped[-1][0]
    return cropped, start, end, hit, windup


def process(rig, source):
    cropped, start, end, hit, windup = slice_attack(source)
    span = end - start
    origin = cropped[0][1]["R"][3:]
    keyframes = []
    corrected_frames = 0
    remaining = []
    max_grip = 0
    max_hand_move = 0
    prior = {}
    last_delta = (0, 0, 0)
    original_intersections = 0

    for time, raw_pose in cropped:
        pose = {key: list(values) for key, values in raw_pose.items()}
        pose["R"][3:] = [min(limit, max(-limit, value - offset))
                          for value, offset, limit in zip(pose["R"][3:], origin, (0.5, 0.32, 0.5))]
        free_left_arm(pose)
        fixed, before, after, last_delta = correct(rig, pose, last_delta)
        original_intersections += int(rig.intersects(before))
        corrected_frames += int(fixed["RS"] != pose["RS"] or fixed["RW"] != pose["RW"])
        if rig.intersects(after):
            remaining.append(round((time - start) / span, 4))
        hand, handle = after[2], after[3]
        max_grip = max(max_grip, ((hand @ rig.hand_grip).translation - (handle @ rig.handle_grip).translation).length)
        max_hand_move = max(max_hand_move, (hand.translation - before[2].translation).length)
        fixed = {name: unwrap(values, prior.get(name)) for name, values in fixed.items()}
        prior = fixed
        keyframes.append([round((time - start) / span, 5), fixed])

    refined = [keyframes[0]]
    for a, b in zip(keyframes, keyframes[1:]):
        refined.extend(refine_interval(rig, a, b))
    inserted = len(refined) - len(keyframes)
    keyframes = refined
    between = sum(
        int(rig.intersects(rig.solve_pose(interpolate_pose(a, b, alpha))))
        for (_, a), (_, b) in zip(keyframes, keyframes[1:]) for alpha in (0.25, 0.5, 0.75)
    )
    report = {
        "frames": len(keyframes), "insertedKeys": inserted, "originalIntersections": original_intersections, "correctedFrames": corrected_frames,
        "intersections": remaining, "intersectionsBetweenKeys": between,
        "maxGripErrorStuds": round(max_grip, 7), "maxHandCorrectionStuds": round(max_hand_move, 5),
    }
    return {
        "dur": round(source["dur"] * span, 4), "hit": round((hit - start) / span, 5),
        "windup": round((windup - start) / span, 5), "keys": keyframes,
    }, report


def main(source_dir, output, rig_file):
    data = json.loads(rig_file.read_text(encoding="utf-8-sig"))
    if data.get("weapon") != "Sword":
        raise RuntimeError("El piloto necesita el R15 con Espada equipado")
    rig = SwordRig(data)
    clips, stats, bones = {}, {}, {}
    for key, name in SOURCES.items():
        source = convert(str(source_dir / name), sample_step=1, export_bones=True)
        if "error" in source:
            raise RuntimeError(f"{name}: {source['error']}")
        bones[name] = source.pop("bones")
        clips[key], stats[key] = process(rig, source)
        clips[key]["source"] = name
        print(key, stats[key], flush=True)
    (output / "FuertesFuente.json").write_text(json.dumps(bones, separators=(",", ":")), encoding="utf-8")
    (output / "FuertesR15.json").write_text(json.dumps(clips, separators=(",", ":")), encoding="utf-8")
    (output / "FuertesValidacion.json").write_text(json.dumps(stats, indent=2), encoding="utf-8")


if __name__ == "__main__":
    source, output, rig_file = map(Path, sys.argv[sys.argv.index("--") + 1:])
    try:
        main(source, output, rig_file)
    except Exception:
        (output / "Fuertes_error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        raise

