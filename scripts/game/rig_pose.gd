class_name RigPose
extends RefCounted
## How a body moves (design/art-briefs/animation/BRIEF.md, "The skeleton"): a walk cycle worked out in 3D, plus
## standing, sneaking and limping, and the rooms' camera that turns those 3D points into pixels. Shared by the game
## (Rig moves the painted parts) and by tools/pose_guides (the colour-coded guides), so the two never disagree.
##
## Body space: x the body's right, y up, z forward, in pixels at the game's scale (about 1.5 squares tall on screen).

const PITCH := 30.0        # degrees the rooms' camera looks down from level

const HIP_Y := 30.0
const HIP_W := 5.0
const SHOULDER_Y := 47.0
const SHOULDER_W := 7.0
const HEAD_Y := 55.0
const THIGH := 14.5
const SHIN := 14.5
const ANKLE_Y := 2.0
const FOOT := 6.0
const UPPER_ARM := 9.0
const FOREARM := 8.5
const STRIDE := 9.0        # how far a foot reaches ahead of the hip and behind it
const LIFT := 5.0          # how high a swinging foot lifts
const BOB := 1.5           # how far the body dips at each step and rises between
const ARM_SWING := 0.6     # how far an arm swings, as a share of the opposite leg's
const LEAN := 2.0          # the body leans this far forward walking

const WALK_TIME := 0.8     # s for a whole walk cycle (two steps) at full walking speed
const IDLE_TIME := 2.4     # s for one breath

# sneaking: crouched, short steps, leaning in
const SNEAK_DROP := 5.0
const SNEAK_STRIDE := 0.6
const SNEAK_LEAN := 5.0


## Where one foot is, `q` of the way through its own stride: (forward, up). 0: heel down ahead; 0-0.5 planted and
## moving back under the body; 0.5-1 lifted and swinging forward.
static func foot(q: float, stride := STRIDE, lift := LIFT) -> Vector2:
	q = fposmod(q, 1.0)
	if q < 0.5:
		return Vector2(stride * (1.0 - 4.0 * q), 0.0)
	var u := (q - 0.5) / 0.5
	return Vector2(-stride + 2.0 * stride * smoothstep(0.0, 1.0, u), lift * sin(PI * u))


## A walk, `t` (0-1) of the way through its cycle. `kind`: "walk", "sneak" (crouched) or "limp" (the left leg hurt:
## a short step on it and a dip).
static func walk(t: float, kind := "walk") -> Dictionary:
	var stride := STRIDE * (SNEAK_STRIDE if kind == "sneak" else 1.0)
	var lift := LIFT * (0.6 if kind == "sneak" else 1.0)
	var left := foot(t, stride * (0.55 if kind == "limp" else 1.0), lift)
	var right := foot(t + 0.5, stride, lift)
	var hip_y := HIP_Y - BOB * cos(4.0 * PI * (t - 0.125))
	if kind == "sneak":
		hip_y -= SNEAK_DROP
	if kind == "limp" and fposmod(t, 1.0) < 0.5:
		hip_y -= 1.5 * sin(TAU * t)   # sags onto the bad leg
	return body(hip_y, left, right, SNEAK_LEAN if kind == "sneak" else LEAN)


## Standing still, `t` (0-1) through a breath.
static func idle(t: float, crouched := false) -> Dictionary:
	var breathe := 0.6 * sin(TAU * t)
	var p := body(HIP_Y - 0.3 - (SNEAK_DROP if crouched else 0.0), Vector2(2.5, 0), Vector2(-2.5, 0), SNEAK_LEAN if crouched else 0.5)
	for k in ["neck", "head", "l_shoulder", "r_shoulder", "l_elbow", "r_elbow", "l_hand", "r_hand"]:
		p[k] += Vector3(0, breathe, 0)
	p.planted = [p.l_ankle, p.r_ankle]
	return p


## A whole body from where its hips are and where each foot is (forward, up).
static func body(hip_y: float, left: Vector2, right: Vector2, lean := LEAN) -> Dictionary:
	var p := {}
	p.hip = Vector3(0, hip_y, 0)
	p.l_hip = Vector3(-HIP_W, hip_y, 0)
	p.r_hip = Vector3(HIP_W, hip_y, 0)
	p.l_ankle = Vector3(-HIP_W + 1, ANKLE_Y + left.y, left.x)
	p.r_ankle = Vector3(HIP_W - 1, ANKLE_Y + right.y, right.x)
	p.l_knee = knee(p.l_hip, p.l_ankle)
	p.r_knee = knee(p.r_hip, p.r_ankle)
	p.l_toe = p.l_ankle + Vector3(0, -1, FOOT)
	p.r_toe = p.r_ankle + Vector3(0, -1, FOOT)
	var dy := hip_y - HIP_Y
	p.neck = Vector3(0, SHOULDER_Y + 3 + dy, lean)
	p.head = Vector3(0, HEAD_Y + dy, lean + 0.5)
	p.l_shoulder = Vector3(-SHOULDER_W, SHOULDER_Y + dy, lean)
	p.r_shoulder = Vector3(SHOULDER_W, SHOULDER_Y + dy, lean)
	# each arm swings with the opposite leg
	var l_swing := ARM_SWING * right.x
	var r_swing := ARM_SWING * left.x
	p.l_elbow = p.l_shoulder + Vector3(-1, -UPPER_ARM, l_swing * 0.45 - 0.5)
	p.r_elbow = p.r_shoulder + Vector3(1, -UPPER_ARM, r_swing * 0.45 - 0.5)
	p.l_hand = p.l_elbow + Vector3(0, -FOREARM, l_swing * 0.55 + 1.5)
	p.r_hand = p.r_elbow + Vector3(0, -FOREARM, r_swing * 0.55 + 1.5)
	# the coat skirt hangs from the hips and swings a little behind the legs
	p.hem = Vector3(0, hip_y - 16.0, lean * 0.5 - (left.x + right.x) * 0.15)
	p.planted = []
	if left.y == 0.0:
		p.planted.append(p.l_ankle)
	if right.y == 0.0:
		p.planted.append(p.r_ankle)
	return p


## The knee between a hip and an ankle, bending forward.
static func knee(hip: Vector3, ankle: Vector3) -> Vector3:
	var to := Vector2(ankle.z - hip.z, ankle.y - hip.y)   # (forward, up) from the hip
	var d := clampf(to.length(), 0.01, THIGH + SHIN - 0.01)
	var a := acos(clampf((THIGH * THIGH + d * d - SHIN * SHIN) / (2.0 * THIGH * d), -1.0, 1.0))
	var base := to.angle()
	var k := Vector2.from_angle(base - a) * THIGH   # bend so the knee comes forward
	if k.x < (to.x * THIGH / d):
		k = Vector2.from_angle(base + a) * THIGH
	return Vector3(lerpf(hip.x, ankle.x, THIGH / (THIGH + SHIN)), hip.y + k.y, hip.z + k.x)


## A point in body space as seen through the rooms' camera, for a body facing `f` (east, north on the ground), with
## the feet at `root`: (screen x, screen y, depth). Further from the camera is a larger depth.
static func project(p: Vector3, f: Vector2, root := Vector2.ZERO) -> Vector3:
	var r := Vector2(f.y, -f.x)          # the body's right, on the ground
	var east := r.x * p.x + f.x * p.z
	var north := r.y * p.x + f.y * p.z
	var c := cos(deg_to_rad(PITCH))
	var s := sin(deg_to_rad(PITCH))
	return Vector3(root.x + east, root.y - p.y * c - north * s, north)
