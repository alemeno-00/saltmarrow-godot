extends SceneTree
## Draws pose guides for character animation, the way room blockouts guide the room paintings. The poses and the
## camera come from RigPose, the same rules the game's skeleton moves by.
## (design/art-briefs/animation/BRIEF.md, "Pose guides"):
##   godot --headless --path . -s tools/pose_guides/pose_guides.gd
##
## Image generators can't keep track of which leg is which from frame to frame, so walks come out as the same pose
## drawn again and again. These guides settle the poses: a walk cycle worked out in 3D (each foot planted, then
## swinging through; knees from the hip and foot; arms swinging against the legs; the body dipping and rising) and
## projected through the rooms' raised camera, for the five drawn directions. ChatGPT paints the character over each
## frame. Colours: left leg red, right leg blue, left arm orange, right arm cyan, the side away from the camera
## darker; feet marks show where a planted foot stays.
##
## Writes design/art-briefs/animation/guides/walk_<dir>.png (8 frames), idle_<dir>.png (6 frames), each at
## 80 x 80 a frame with the feet at x 40, y 72, plus a 4 x enlargement of each for reading.

const OUT := "res://design/art-briefs/animation/guides/"
const FRAME := Vector2i(80, 80)
const ROOT := Vector2(40, 72)
const PITCH := 30.0        # degrees the rooms' camera looks down from level: bodies a little shorter, the ground receding
const DIRECTIONS := {"s": Vector2(0, -1), "se": Vector2(1, -1), "e": Vector2(1, 0), "ne": Vector2(1, 1), "n": Vector2(0, 1)}

# the body, in pixels (about 1.5 squares tall once seen through the camera)
const HIP_Y := 30.0
const HIP_W := 5.0
const SHOULDER_Y := 47.0
const SHOULDER_W := 7.0
const HEAD_Y := 55.0
const HEAD_R := 5.0
const THIGH := 14.5
const SHIN := 14.5
const ANKLE_Y := 2.0
const FOOT := 6.0
const STRIDE := 9.0        # how far a foot reaches ahead of the hip and behind it
const LIFT := 5.0          # how high a swinging foot lifts
const BOB := 1.5           # how far the body dips at each step and rises between
const ARM_SWING := 0.6     # how far an arm swings, as a share of the opposite leg's

const LEFT_LEG := Color8(210, 60, 60)
const RIGHT_LEG := Color8(60, 105, 215)
const LEFT_ARM := Color8(235, 150, 55)
const RIGHT_ARM := Color8(55, 195, 215)
const BODY := Color8(150, 150, 150)
const HEAD := Color8(225, 212, 190)
const MARK := Color8(255, 255, 255)
const GROUND := Color(0, 0, 0, 0.25)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for d in DIRECTIONS:
		_save(_sheet(d, 8, false), "walk_" + d)
		_save(_sheet(d, 6, true), "idle_" + d)
	print("pose guides written to ", OUT)
	quit()


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	var big := img.duplicate()
	big.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(OUT + name + "_4x.png"))


func _sheet(dir: String, frames: int, idle: bool) -> Image:
	var img := Image.create(FRAME.x * frames, FRAME.y, false, Image.FORMAT_RGBA8)
	for i in frames:
		var pose := _idle_pose(float(i) / frames) if idle else _walk_pose(float(i) / frames)
		_draw_frame(img, Vector2(i * FRAME.x, 0), pose, DIRECTIONS[dir].normalized())
	return img


# ---------------------------------------------------------------- poses (shared with the game: RigPose)

func _walk_pose(t: float) -> Dictionary:
	return RigPose.walk(t)


func _idle_pose(t: float) -> Dictionary:
	return RigPose.idle(t)


# ---------------------------------------------------------------- the camera and drawing

static func _project(p: Vector3, f: Vector2) -> Vector3:
	return RigPose.project(p, f, ROOT)


func _draw_frame(img: Image, at: Vector2, pose: Dictionary, f: Vector2) -> void:
	# the ground under him, and where planted feet stay
	_ellipse(img, at + ROOT, 10.0, 3.5, GROUND)
	for a in pose.planted:
		var s := _project(a, f)
		_dot(img, at + Vector2(s.x, s.y + 1), 1.0, MARK)
	var parts: Array = [
		["l_hip", "l_knee", LEFT_LEG, 1.6], ["l_knee", "l_ankle", LEFT_LEG, 1.4], ["l_ankle", "l_toe", LEFT_LEG.darkened(0.25), 1.3],
		["r_hip", "r_knee", RIGHT_LEG, 1.6], ["r_knee", "r_ankle", RIGHT_LEG, 1.4], ["r_ankle", "r_toe", RIGHT_LEG.darkened(0.25), 1.3],
		["l_shoulder", "l_elbow", LEFT_ARM, 1.3], ["l_elbow", "l_hand", LEFT_ARM, 1.2],
		["r_shoulder", "r_elbow", RIGHT_ARM, 1.3], ["r_elbow", "r_hand", RIGHT_ARM, 1.2],
	]
	var hip_mid: Vector3 = (pose.l_hip + pose.r_hip) / 2.0
	var torso_depth := _project(hip_mid, f).z
	# the far side first, darkened; then the body; then the near side
	parts.sort_custom(func(a, b): return _depth(pose, a, f) > _depth(pose, b, f))
	var body_drawn := false
	for part in parts:
		var d := _depth(pose, part, f)
		if not body_drawn and d <= torso_depth:
			_torso(img, at, pose, f)
			body_drawn = true
		var col: Color = part[2]
		if d > torso_depth + 0.5:
			col = col.darkened(0.4)
		_limb(img, at, _project(pose[part[0]], f), _project(pose[part[1]], f), part[3], col)
	if not body_drawn:
		_torso(img, at, pose, f)


static func _depth(pose: Dictionary, part: Array, f: Vector2) -> float:
	return (_project(pose[part[0]], f).z + _project(pose[part[1]], f).z) / 2.0


func _torso(img: Image, at: Vector2, pose: Dictionary, f: Vector2) -> void:
	var hip_mid: Vector3 = (pose.l_hip + pose.r_hip) / 2.0
	_limb(img, at, _project(pose.l_hip, f), _project(pose.r_hip, f), 2.0, BODY)
	_limb(img, at, _project(pose.l_shoulder, f), _project(pose.r_shoulder, f), 2.2, BODY)
	_limb(img, at, _project(hip_mid, f), _project(pose.neck, f), 3.2, BODY)
	var h := _project(pose.head, f)
	_dot(img, at + Vector2(h.x, h.y), HEAD_R, HEAD)
	# which way the face points: a dark mark on the face side (none when facing away)
	var nose := _project(pose.head + Vector3(0, 0, HEAD_R - 1), f)
	if nose.z <= h.z:
		_dot(img, at + Vector2(nose.x, nose.y), 1.0, Color8(60, 40, 30))


func _limb(img: Image, at: Vector2, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var n := maxi(1, ceili(Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y)) * 2.0))
	for i in n + 1:
		var p := Vector2(a.x, a.y).lerp(Vector2(b.x, b.y), float(i) / n)
		_dot(img, at + p, r, col)


func _dot(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in range(floori(c.y - r), ceili(c.y + r) + 1):
		for x in range(floori(c.x - r), ceili(c.x + r) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r + 0.25 and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, col)


func _ellipse(img: Image, c: Vector2, rx: float, ry: float, col: Color) -> void:
	for y in range(floori(c.y - ry), ceili(c.y + ry) + 1):
		for x in range(floori(c.x - rx), ceili(c.x + rx) + 1):
			var d := Vector2((x + 0.5 - c.x) / rx, (y + 0.5 - c.y) / ry)
			if d.length() <= 1.0 and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, img.get_pixel(x, y).blend(col))
