class_name Rig
extends RefCounted
## A character drawn as parts on a skeleton (design/art-briefs/animation/BRIEF.md, "The skeleton"), instead of a
## painted frame for every moment: painted once per direction, moved by RigPose, so it never flickers and can do any
## pose the rules can describe.
##
## A **parts sheet** is one row of 24 x 24 cells, one part per cell, in the order of PARTS. Each part is painted in
## its rest pose: limbs hanging straight down from their pivot, the head and torso standing straight up from theirs.
## The pivot is the joint it turns about (the shoulder for an upper arm, the hip for a thigh). Templates showing every
## cell, its pivot and a stand-in shape: design/art-briefs/animation/rig/ (made by tools/rig/rig_template.gd).
## **Cutting a parts sheet from a whole model** (house style rule 10): `bind_anchors()` gives, for each part, where its
## pivot falls on the 80 x 80 model in the bind pose (RigPose.bind, facing south, feet at (40, 72)), and `cut_rect()`
## the 24 x 24 square of the model its cell holds. Copy each part's pixels from that square into its cell unmoved;
## `compose()` with the bind pose then rebuilds the model exactly (tools/rig/rig_template.gd writes these as
## design/art-briefs/animation/rig/bind_s.json and checks a cut with `-- check <model> <parts>`).
## Sheets go in a character's `rig/` folder, one per drawn direction: s.png, se.png, e.png, ne.png, n.png (and a
## normal map beside each, `s_n.png`). The game mirrors SE, E and NE for the west side.

const CELL := Vector2(24, 24)
const DIRS := {"s": Vector2(0, -1), "se": Vector2(0.7071, -0.7071), "e": Vector2(1, 0), "ne": Vector2(0.7071, 0.7071), "n": Vector2(0, 1)}
const DIR_ANGLE := {"e": 0.0, "se": 45.0, "s": 90.0, "ne": -45.0, "n": -90.0}
## part -> [cell, pivot in the cell, from joint, to joint, which way it points at rest (1 down, -1 up)]
const PARTS := {
	"head": [0, Vector2(12, 22), "neck", "head", -1],
	"torso": [1, Vector2(12, 21), "hip", "neck", -1],   # row 21, not 22: room below the hip for the scarf's end and the hip kit (job 15-R)
	"skirt": [2, Vector2(12, 2), "hip", "hem", 1],
	"upper_arm_l": [3, Vector2(12, 2), "l_shoulder", "l_elbow", 1],
	"forearm_l": [4, Vector2(12, 2), "l_elbow", "l_hand", 1],
	"upper_arm_r": [5, Vector2(12, 2), "r_shoulder", "r_elbow", 1],
	"forearm_r": [6, Vector2(12, 2), "r_elbow", "r_hand", 1],
	"thigh_l": [7, Vector2(12, 2), "l_hip", "l_knee", 1],
	"shin_l": [8, Vector2(12, 2), "l_knee", "l_ankle", 1],
	"thigh_r": [9, Vector2(12, 2), "r_hip", "r_knee", 1],
	"shin_r": [10, Vector2(12, 2), "r_knee", "r_ankle", 1],
}
const COVER_ANGLE := 22.5   # degrees: half the gap between two drawn directions
const LEGS := ["thigh_l", "shin_l", "thigh_r", "shin_r"]
const ARMS := ["upper_arm_l", "forearm_l", "upper_arm_r", "forearm_r"]

var sheets := {}   # direction -> Texture2D


## A character's rig from its folder (e.g. "res://assets/characters/thomas/rig/"), or null if no sheet is there yet.
static func load_from(folder: String) -> Rig:
	var r := Rig.new()
	for d in DIRS:
		var path: String = folder + d + ".png"
		if ResourceLoader.exists(path):
			r.sheets[d] = load(path)
	return r if not r.sheets.is_empty() else null


## The drawn direction for a way of facing, and whether to mirror it, from the directions this rig has: the nearest
## one, the west side being the east side mirrored.
func pick(look: Vector2) -> Array:
	return _nearest(look).slice(0, 2)


## Is there a drawing for this way of facing (itself, or mirrored)? While only some directions are painted, the
## others keep the old painted art rather than showing the wrong side of him.
func covers(look: Vector2) -> bool:
	return _nearest(look)[2] <= COVER_ANGLE


## [direction, mirror, degrees off] for the nearest drawn direction.
func _nearest(look: Vector2) -> Array:
	var want := rad_to_deg(look.angle())
	var best := ""
	var mirror := false
	var best_d := INF
	for d in sheets:
		var a: float = DIR_ANGLE[d]
		for m in ([false, true] if d != "s" and d != "n" else [false]):
			var diff := absf(wrapf(want - (180.0 - a if m else a), -180.0, 180.0))
			if diff < best_d - 0.01:
				best_d = diff
				best = d
				mirror = m
	return [best, mirror, best_d]


## Where each part goes for a pose, seen facing `f`, with the feet at `root`: [{part, at (where its pivot goes),
## angle (radians from its rest pose), cell}], in the order to draw them. The legs go first (the coat hangs over
## them), then the far arm, the coat, the body, the near arm, and the head last.
static func placements(pose: Dictionary, f: Vector2, root := Vector2.ZERO) -> Array:
	var body_depth := RigPose.project(pose.hip, f, root).z
	var out: Array = []
	for name in PARTS:
		var d: Array = PARTS[name]
		var a := RigPose.project(pose[d[2]], f, root)
		var b := RigPose.project(pose[d[3]], f, root)
		var v := Vector2(b.x - a.x, b.y - a.y)
		var rest := Vector2(0, d[4])
		var depth := (a.z + b.z) / 2.0
		var layer := 0.0
		if name in LEGS:
			layer = 0.0
		elif name in ARMS:
			layer = 1.0 if depth > body_depth else 5.0
		else:
			layer = {"skirt": 2.0, "torso": 3.0, "head": 6.0}[name]
		out.append({"part": name, "at": Vector2(a.x, a.y), "angle": rest.angle_to(v) if v.length() > 0.5 else 0.0,
			"cell": d[0], "pivot": d[1], "order": layer * 1000.0 - depth})
	out.sort_custom(func(x, y): return x.order < y.order)
	return out


## Where each part's pivot falls on a whole model standing in the bind pose, facing `f`, feet at `root`: part ->
## Vector2i. Whole pixels, by design of RigPose's proportions.
static func bind_anchors(f := Vector2(0, -1), root := Vector2(40, 72)) -> Dictionary:
	var out := {}
	for pl in placements(RigPose.bind(), f, root):
		out[pl.part] = Vector2i((pl.at as Vector2).round())
	return out


## The square of the model (80 x 80, feet at (40, 72)) that part `name`'s cell holds in the bind pose.
static func cut_rect(name: String, f := Vector2(0, -1), root := Vector2(40, 72)) -> Rect2i:
	var d: Array = PARTS[name]
	return Rect2i(bind_anchors(f, root)[name] - Vector2i(d[1]), Vector2i(CELL))


## Draw a pose from a parts sheet into an image, pixel by pixel, as the game draws it (nearest pixel, each part
## turned about its pivot, the pivot on a whole pixel): for the template tools and tests. `frame` is the image size.
static func compose(sheet: Image, pose: Dictionary, f: Vector2, root: Vector2, frame := Vector2i(80, 80), hidden: Array = []) -> Image:
	var img := Image.create(frame.x, frame.y, false, Image.FORMAT_RGBA8)
	for pl in placements(pose, f, root):
		if pl.part in hidden:
			continue
		var at: Vector2 = (pl.at as Vector2).round()
		var to_part := Transform2D(pl.angle, at).affine_inverse()
		var pivot: Vector2 = pl.pivot
		var reach := CELL.length()
		for y in range(maxi(0, floori(at.y - reach)), mini(frame.y, ceili(at.y + reach))):
			for x in range(maxi(0, floori(at.x - reach)), mini(frame.x, ceili(at.x + reach))):
				var q: Vector2 = to_part * Vector2(x + 0.5, y + 0.5) + pivot
				if q.x < 0.0 or q.y < 0.0 or q.x >= CELL.x or q.y >= CELL.y:
					continue
				var c := sheet.get_pixel(int(pl.cell * CELL.x + q.x), int(q.y))
				if c.a > 0.5:
					img.set_pixel(x, y, c)
	return img


## The pose for one of the moving animations, `t` seconds in: idle, walk, sneak (crouched; still when not moving),
## wounded_walk (a limp). Empty for animations the rig doesn't do (attacks and the like stay painted).
static func pose_for(anim: String, t: float, moving := true) -> Dictionary:
	match anim:
		"idle":
			return RigPose.idle(fposmod(t / RigPose.IDLE_TIME, 1.0))
		"walk":
			return RigPose.walk(fposmod(t / RigPose.WALK_TIME, 1.0))
		"wounded_walk":
			return RigPose.walk(fposmod(t / (RigPose.WALK_TIME * 1.3), 1.0), "limp")
		"sneak":
			return RigPose.walk(fposmod(t / (RigPose.WALK_TIME * 1.6), 1.0), "sneak") if moving else RigPose.idle(fposmod(t / RigPose.IDLE_TIME, 1.0), true)
	return {}


## Which parts are under the water for someone wading: the shins in shallows, the legs and coat skirt in sewage.
static func under_water(depth: float) -> Array:
	if depth >= 10.0:
		return ["thigh_l", "shin_l", "thigh_r", "shin_r", "skirt"]
	if depth > 0.0:
		return ["shin_l", "shin_r"]
	return []
