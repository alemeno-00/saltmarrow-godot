class_name RigMotion
extends RefCounted
## What makes the skeleton move like a body and not a paper cut-out (design/art-briefs/animation/BRIEF.md, "The
## skeleton"), kept from frame to frame for one character:
## - the walk is driven by distance, not time: one cycle per RigPose.cycle_length() px walked, so a planted foot stays
##   put whatever his speed (walking, sneaking, wading, hurried in a fight);
## - standing, walking and sneaking ease into each other instead of snapping;
## - he leans into starting off and rocks back when he stops;
## - the coat skirt, hands and elbows hang on springs: they trail behind when he sets off, swing on when he stops, and
##   settle (follow-through and overlapping action, as in The Animator's Survival Kit and Overgrowth's procedural walk).

const VEL_EASE := 10.0        # how quickly the felt velocity catches up with the real one
const BLEND_TIME := 0.15      # s to ease between standing and walking
const LEAN_PER_ACCEL := 0.012 # px of lean per px/s² he speeds up (forward) or slows (back)
const LEAN_MAX := 3.0
const LEAN_EASE := 8.0        # how fast the lean follows
const STIFF := 140.0          # spring stiffness for the parts that trail
const DAMP := 11.0            # and how quickly they settle
const INERTIA := 0.02         # how far they are thrown, px per px/s² of his speeding up or slowing
const SWING_MAX := 4.0        # px: never further than this from where they hang
## the parts that trail, and how loosely: the coat most, the hands, the elbows half as much
const LOOSE := {"hem": 1.0, "l_hand": 0.8, "r_hand": 0.8, "l_elbow": 0.4, "r_elbow": 0.4}

var phase := 0.0       # 0-1 through the walk cycle
var idle_t := 0.0      # 0-1 through a breath
var walking := 0.0     # 0 standing, 1 walking: the mix between the two
var lean := 0.0        # px forward (+) or back (-)
var _vel := Vector2.ZERO
var _off := {}         # part -> Vector3 offset from where it hangs
var _off_v := {}       # and how fast that offset is changing


## The pose for this frame. `vel`: his velocity on the floor (px/s, screen x right, y down); `look`: the way he
## faces; `kind`: "walk", "sneak" or "limp"; `crouched`: standing still in a crouch.
func step(delta: float, vel: Vector2, look: Vector2, kind := "walk", crouched := false) -> Dictionary:
	if delta <= 0.0:
		delta = 1.0 / 60.0
	var speed := vel.length()
	var moving := speed > 4.0
	phase = fposmod(phase + speed * delta / RigPose.cycle_length(kind), 1.0)
	idle_t = fposmod(idle_t + delta / RigPose.IDLE_TIME, 1.0)
	walking = move_toward(walking, 1.0 if moving else 0.0, delta / BLEND_TIME)
	var still := RigPose.idle(idle_t, crouched or kind == "sneak")
	var pose := RigPose.mix(still, RigPose.walk(phase, kind), _ease(walking))
	# speeding up or slowing, in his own terms: forward along `look`, and to his right
	# (from his velocity smoothed a little: a glide that starts at full speed is still felt as a push, not a jolt)
	var smooth := _vel.lerp(vel, 1.0 - exp(-delta * VEL_EASE))
	var accel := (smooth - _vel) / delta
	_vel = smooth
	var f := look.normalized() if look.length() > 0.01 else Vector2.RIGHT
	var fwd := accel.dot(f)
	var side := accel.dot(Vector2(-f.y, f.x))
	lean = lerpf(lean, clampf(fwd * LEAN_PER_ACCEL, -LEAN_MAX, LEAN_MAX), 1.0 - exp(-delta * LEAN_EASE))
	for k in ["neck", "head", "l_shoulder", "r_shoulder", "l_elbow", "r_elbow", "l_hand", "r_hand"]:
		pose[k] += Vector3(0, 0, lean * (1.2 if k == "head" else 1.0))
	# the loose parts: a spring pulls each back to where it hangs; his speeding up throws them the other way
	var throw := Vector3(-side, 0, -fwd) * INERTIA
	for k in LOOSE:
		var o: Vector3 = _off.get(k, Vector3.ZERO)
		var v: Vector3 = _off_v.get(k, Vector3.ZERO)
		v += (-STIFF * o - DAMP * v) * delta + throw * LOOSE[k] * STIFF * delta
		o += v * delta
		o = o.limit_length(SWING_MAX * LOOSE[k])
		_off[k] = o
		_off_v[k] = v
		pose[k] += o
	return pose


## Ease in and out, so the change from standing to walking has no corner.
static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
