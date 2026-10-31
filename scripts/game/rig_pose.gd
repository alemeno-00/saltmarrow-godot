class_name RigPose
extends RefCounted
## How a body moves (design/art-briefs/animation/BRIEF.md, "The skeleton"): a walk cycle worked out in 3D, plus
## standing, sneaking and limping, and the rooms' camera that turns those 3D points into pixels. Shared by the game
## (Rig moves the painted parts) and by tools/pose_guides (the colour-coded guides), so the two never disagree.
##
## Body space: x the body's right, y up, z forward, in pixels at the game's scale (about 1.5 squares tall on screen).
##
## **The proportions are measured from the approved model** (job 15-R, Julian 2026-10-31:
## `assets/characters/thomas/rig/production/model-s.png`, 80 x 80, feet at (40, 72)). Standing as painted (`bind()`),
## seen from the south, every joint lands on a whole pixel of that model: the neck at row 30, the shoulders at row
## 32, x 33 and 47, the elbows at row 40, the hands at row 48, the hips at row 50, x 36 and 44, the knees at row 59,
## the ankles at row 68, the coat's hem at row 62. Heights are those rows' distance above the feet divided by the
## camera's cos(30°), so they project back onto the model exactly.

const PITCH := 30.0        # degrees the rooms' camera looks down from level
const COS := 0.8660254     # cos(PITCH): how much shorter a height looks from the rooms' camera

const HIP_Y := 22.0 / COS        # row 50
const HIP_W := 4.0               # x 36 and 44
const NECK_Y := 42.0 / COS       # row 30
const SHOULDER_Y := 40.0 / COS   # row 32
const SHOULDER_W := 7.0          # x 33 and 47
const HEAD_Y := NECK_Y + 6.0     # which way the head points (straight up from the neck, standing)
const THIGH := 9.0 / COS         # rows 50-59
const SHIN := 9.0 / COS          # rows 59-68
const ANKLE_Y := 4.0 / COS       # row 68: the ankle; the boot below it is painted on the shin
const FOOT := 6.0
const UPPER_ARM := 8.0 / COS     # rows 32-40
const FOREARM := 8.0 / COS       # rows 40-48
const HEM := 12.0 / COS          # the coat skirt, rows 50-62
const STRIDE := 9.0        # how far a foot reaches ahead of the hip and behind it (the legs are short: no further)
const LIFT := 4.0          # how high a swinging foot lifts
const BOB := 1.2           # how far the body dips at each step and rises between
const ARM_SWING := 0.6     # how far an arm swings, as a share of the opposite leg's
const LEAN := 2.0          # the body leans this far forward walking
const WALK_DROP := 3.0     # walking, the knees stay a little bent: the hips ride this much lower than standing
# weight (The Animator's Survival Kit; Overgrowth's procedural walk): the body is carried over the standing leg
const SWAY := 1.2          # px the hips shift sideways over the standing foot
const HIP_TWIST := 1.2     # px a hip swings forward with its leg
const SHOULDER_TWIST := 1.5 # px the shoulders turn the other way, against the hips
const HIP_TILT := 0.8      # px the hip over the swinging leg drops

const WALK_TIME := 0.8     # s for a whole walk cycle (two steps) at full walking speed
const IDLE_TIME := 2.4     # s for one breath

# sneaking: crouched, short steps, leaning in
const SNEAK_DROP := 4.0
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
	var hip_y := HIP_Y - WALK_DROP - BOB * cos(4.0 * PI * (t - 0.125))
	if kind == "sneak":
		hip_y -= SNEAK_DROP
	if kind == "limp" and fposmod(t, 1.0) < 0.5:
		hip_y -= 1.5 * sin(TAU * t)   # sags onto the bad leg
	return body(hip_y, left, right, SNEAK_LEAN if kind == "sneak" else LEAN, t)


## The bind pose: standing exactly as the model is painted, facing south. Legs and arms hang straight down, nothing
## leans or breathes. In it every part sits at angle 0 with its pivot on a whole pixel of the model (Rig.bind_anchors),
## so the parts cut from the model put back together give the model again, pixel for pixel.
static func bind() -> Dictionary:
	var p := {}
	p.hip = Vector3(0, HIP_Y, 0)
	p.l_hip = Vector3(-HIP_W, HIP_Y, 0)
	p.r_hip = Vector3(HIP_W, HIP_Y, 0)
	p.l_knee = Vector3(-HIP_W, HIP_Y - THIGH, 0)
	p.r_knee = Vector3(HIP_W, HIP_Y - THIGH, 0)
	p.l_ankle = Vector3(-HIP_W, ANKLE_Y, 0)
	p.r_ankle = Vector3(HIP_W, ANKLE_Y, 0)
	p.l_toe = p.l_ankle + Vector3(0, -1, FOOT)
	p.r_toe = p.r_ankle + Vector3(0, -1, FOOT)
	p.neck = Vector3(0, NECK_Y, 0)
	p.head = Vector3(0, HEAD_Y, 0)
	p.l_shoulder = Vector3(-SHOULDER_W, SHOULDER_Y, 0)
	p.r_shoulder = Vector3(SHOULDER_W, SHOULDER_Y, 0)
	p.l_elbow = p.l_shoulder + Vector3(0, -UPPER_ARM, 0)
	p.r_elbow = p.r_shoulder + Vector3(0, -UPPER_ARM, 0)
	p.l_hand = p.l_elbow + Vector3(0, -FOREARM, 0)
	p.r_hand = p.r_elbow + Vector3(0, -FOREARM, 0)
	p.hem = Vector3(0, HIP_Y - HEM, 0)
	p.planted = [p.l_ankle, p.r_ankle]
	return p


## Standing still, `t` (0-1) through a breath.
static func idle(t: float, crouched := false) -> Dictionary:
	var breathe := 0.6 * sin(TAU * t)
	var p := body(HIP_Y - 0.3 - (SNEAK_DROP if crouched else 0.0), Vector2(2.5, 0), Vector2(-2.5, 0), SNEAK_LEAN if crouched else 0.5)
	for k in ["neck", "head", "l_shoulder", "r_shoulder", "l_elbow", "r_elbow", "l_hand", "r_hand"]:
		p[k] += Vector3(0, breathe, 0)
	p.planted = [p.l_ankle, p.r_ankle]
	return p


## A whole body from where its hips are and where each foot is (forward, up). `t`, for a walk, is how far through
## its cycle: the weight shifts over the standing leg, the hips turn with the legs and the shoulders against them.
static func body(hip_y: float, left: Vector2, right: Vector2, lean := LEAN, t := -1.0) -> Dictionary:
	var sway := 0.0
	var twist := 0.0
	var tilt := 0.0
	if t >= 0.0:
		sway = -SWAY * sin(TAU * t)        # over the left foot as it takes the weight (t 0.25), the right at 0.75
		twist = cos(TAU * t)               # the left hip forward with the left leg (t 0), back at 0.5
		tilt = HIP_TILT * sin(TAU * t)     # the swinging leg's hip drops
	var p := {}
	p.hip = Vector3(sway, hip_y, 0)
	p.l_hip = Vector3(-HIP_W + sway, hip_y + tilt, HIP_TWIST * twist)
	p.r_hip = Vector3(HIP_W + sway, hip_y - tilt, -HIP_TWIST * twist)
	p.l_ankle = Vector3(-HIP_W + 1, ANKLE_Y + left.y, left.x)
	p.r_ankle = Vector3(HIP_W - 1, ANKLE_Y + right.y, right.x)
	p.l_knee = knee(p.l_hip, p.l_ankle)
	p.r_knee = knee(p.r_hip, p.r_ankle)
	p.l_toe = p.l_ankle + Vector3(0, -1, FOOT)
	p.r_toe = p.r_ankle + Vector3(0, -1, FOOT)
	var dy := hip_y - HIP_Y
	# the upper body follows the hips' sway a little less, the head less again: he keeps his eyes level
	p.neck = Vector3(sway * 0.6, NECK_Y + dy, lean)
	p.head = Vector3(sway * 0.4, HEAD_Y + dy, lean + 0.5)
	p.l_shoulder = Vector3(-SHOULDER_W + sway * 0.6, SHOULDER_Y + dy, lean - SHOULDER_TWIST * twist)
	p.r_shoulder = Vector3(SHOULDER_W + sway * 0.6, SHOULDER_Y + dy, lean + SHOULDER_TWIST * twist)
	# each arm swings with the opposite leg
	var l_swing := ARM_SWING * right.x
	var r_swing := ARM_SWING * left.x
	p.l_elbow = p.l_shoulder + Vector3(-1, -UPPER_ARM, l_swing * 0.45 - 0.5)
	p.r_elbow = p.r_shoulder + Vector3(1, -UPPER_ARM, r_swing * 0.45 - 0.5)
	p.l_hand = p.l_elbow + Vector3(0, -FOREARM, l_swing * 0.55 + 1.5)
	p.r_hand = p.r_elbow + Vector3(0, -FOREARM, r_swing * 0.55 + 1.5)
	# the coat skirt hangs from the hips and swings a little behind the legs
	p.hem = Vector3(0, hip_y - HEM, lean * 0.5 - (left.x + right.x) * 0.15)
	p.planted = []
	if left.y == 0.0:
		p.planted.append(p.l_ankle)
	if right.y == 0.0:
		p.planted.append(p.r_ankle)
	return p


## How far he travels (px on the floor) in one whole walk cycle, two steps, so a planted foot stays where it was
## put: it moves back under him exactly as fast as he moves forward.
static func cycle_length(kind := "walk") -> float:
	return 4.0 * STRIDE * (SNEAK_STRIDE if kind == "sneak" else 1.0)


## Two poses mixed, `w` (0-1) of the way from `a` to `b`.
static func mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	if w <= 0.0:
		return a
	if w >= 1.0:
		return b
	var p := {}
	for k in a:
		if a[k] is Vector3 and b.has(k):
			p[k] = (a[k] as Vector3).lerp(b[k], w)
	p.planted = a.planted if w < 0.5 else b.planted
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
