extends SceneTree
## Guides for ChatGPT to paint Thomas's south walk frame by frame, at 4 ×, in the look of the first painted sprites
## (ART_JOBS job 15-W):
##   godot --headless --path . -s tools/pose_guides/walk_guides.gd
##   godot --headless --path . -s tools/pose_guides/walk_guides.gd -- shrink <painted 4x row> <out 1x row> [normal]
##   godot --headless --path . -s tools/pose_guides/walk_guides.gd -- check <delivered s.png>
##
## Painting each frame from nothing (the first batch, #47) lost track of Thomas and of which leg was which; turning
## the painted parts on a skeleton (#61) kept him but broke his pixels. So: the skeleton sets the pose, a painter
## paints the frame, and a tool keeps the pixels honest.
##
## Writes to design/art-briefs/animation/walk-s/:
## - **guide_walk_s_4x.png** (2560 × 320; 8 frames of 320 × 320): Thomas in each pose of the walk, his whole body
##   moving: legs stepping, arms swinging against them, the body rising and falling, the coat swaying. It is the
##   approved model's own parts moved by the skeleton (RigPose.walk "painted"), shown at 4 × so it can be painted over.
##   Rough where parts turned; right in every position. Also at 1 × (guide_walk_s.png).
## - **key_walk_s_4x.png**: the same frames colour-coded: his LEFT leg red and LEFT arm orange, his RIGHT leg blue and
##   RIGHT arm cyan (facing south, his left is on the picture's right), the body grey, the head pale; a white dot under
##   a planted foot, a yellow dot under a lifted one.
## - **guide_walk_s_n_4x.png**: the normal map moved the same way.
## - **frames.json**, **PROMPT.md**: each frame's numbers and its prompt, word for word.
##
## `shrink` turns a painted 4 × row back into 80 × 80 frames: each 4 × 4 block becomes the colour most of it is, snapped
## to the approved model's own colours (or, with `normal`, to the model's normal-map colours), so the pixel size and
## palette never drift. `check` reads a delivered sheet (row 1 idle: 6 frames; row 2 walk: 8) and reports, per walk
## frame, how closely it follows the guide's outline, whether each foot is on the right side and height, and whether
## the head is still the approved head.

const OUT := "res://design/art-briefs/animation/walk-s/"
const MODEL := "res://assets/characters/thomas/rig/production/model-s.png"
const MODEL_N := "res://assets/characters/thomas/rig/production/model-s_n.png"
const PARTS := "res://assets/characters/thomas/rig/s.png"
const PARTS_N := "res://assets/characters/thomas/rig/s_n.png"
const FRAMES := 8
const KEYS := [1, 3, 5, 7]   # the frames that define the walk: each foot down, each passing; painted and approved first
const FRAME := Vector2i(80, 80)
const SCALE := 4
const ROOT := Vector2(40, 72)
const SOUTH := Vector2(0, -1)
const KIND := "painted"      # RigPose.walk: short steps, the body near its standing height (no easing between frames)
const COLOURS := {
	"thigh_l": Color8(210, 60, 60), "shin_l": Color8(210, 60, 60), "thigh_r": Color8(60, 105, 215), "shin_r": Color8(60, 105, 215),
	"upper_arm_l": Color8(235, 150, 55), "forearm_l": Color8(235, 150, 55), "upper_arm_r": Color8(55, 195, 215), "forearm_r": Color8(55, 195, 215),
	"torso": Color8(140, 140, 140), "skirt": Color8(115, 115, 115), "head": Color8(225, 212, 190),
}
# the checker's limits
const MIN_OVERLAP := 0.8      # of the guide's outline and the painted one, shared / combined
const FOOT_TOLERANCE := 1     # px between a painted sole and the guide's (4 px when painting at 4 ×)
const MIN_HEAD_SAME := 0.6    # of the head's pixels within a small colour distance of the approved head
const HEAD_COLOUR_NEAR := 0.12


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 3 and args[0] == "shrink":
		var normal := args.size() > 3 and args[3] == "normal"
		shrink(_img(args[1]), _img(MODEL_N if normal else MODEL)).save_png(args[2])
		print("shrunk to ", args[2])
		quit()
		return
	if args.size() >= 2 and args[0] == "check":
		var report := check(_img(args[1]))
		for line in report.lines:
			print(line)
		quit(0 if report.ok else 1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var data := frame_data()
	_save(guide(_img(PARTS)), "guide_walk_s")
	_save(guide(_img(PARTS_N)), "guide_walk_s_n")
	_save(key(_img(PARTS), data), "key_walk_s")
	var f := FileAccess.open(OUT + "frames.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	f = FileAccess.open(OUT + "PROMPT.md", FileAccess.WRITE)
	f.store_string(prompt(data))
	f.close()
	print("walk guides written to ", OUT)
	quit()


static func pose(i: int) -> Dictionary:
	return RigPose.walk(float(i) / FRAMES, KIND)


## Each frame's numbers: the body's rise or fall, each foot (planted or lifted, ahead or behind), each arm's swing.
static func frame_data() -> Array:
	var bind := RigPose.bind()
	var bind_hip := RigPose.project(bind.hip, SOUTH, ROOT)
	var parts := _img(PARTS)
	var out := []
	for i in FRAMES:
		var p := pose(i)
		var hip := RigPose.project(p.hip, SOUTH, ROOT)
		var d := {"frame": i + 1, "key": (i + 1) in KEYS, "body_shift": [roundi(hip.x - bind_hip.x), roundi(hip.y - bind_hip.y)]}
		for side in ["l", "r"]:
			var a: Vector3 = p[side + "_ankle"]
			var s := RigPose.project(a, SOUTH, ROOT)
			var hand: Vector3 = p[side + "_hand"] - p[side + "_shoulder"]
			var cols := _own_columns(parts, i, side, "r" if side == "l" else "l")
			d["left" if side == "l" else "right"] = {"sole_row": _lowest(_only(parts, i, ["shin_" + side]), 0, 0, cols), "x": roundi(s.x),
				"planted": absf(a.y - RigPose.ANKLE_Y) < 0.01, "lift_px": roundi((a.y - RigPose.ANKLE_Y) * RigPose.COS),
				"forward_px": roundi(a.z), "hand_forward_px": roundi(hand.z)}
		out.append(d)
	return out


## The guide row at 4 ×: every part of the approved model moved by the skeleton.
static func guide(parts: Image) -> Image:
	var row := Image.create(FRAME.x * FRAMES, FRAME.y, false, Image.FORMAT_RGBA8)
	for i in FRAMES:
		row.blit_rect(Rig.compose(parts, pose(i), SOUTH, ROOT, FRAME), Rect2i(Vector2i.ZERO, FRAME), Vector2i(i * FRAME.x, 0))
	return row


## The key row: each part in its colour (left limbs warm, right limbs cool), dots under the feet.
static func key(parts: Image, data: Array) -> Image:
	var row := Image.create(FRAME.x * FRAMES, FRAME.y, false, Image.FORMAT_RGBA8)
	row.fill(Color8(232, 228, 220))
	for i in FRAMES:
		for pl in Rig.placements(pose(i), SOUTH, ROOT):
			var hide: Array = Rig.PARTS.keys().filter(func(n): return n != pl.part)
			var one := Rig.compose(parts, pose(i), SOUTH, ROOT, FRAME, hide)
			for y in FRAME.y:
				for x in FRAME.x:
					if one.get_pixel(x, y).a > 0.5:
						row.set_pixel(i * FRAME.x + x, y, COLOURS[pl.part])
		for side in ["left", "right"]:
			var foot: Dictionary = data[i][side]
			var at := Vector2i(i * FRAME.x + int(foot.x), mini(FRAME.y - 2, int(foot.sole_row) + 1))
			var dot := Color.WHITE if foot.planted else Color8(240, 200, 40)
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					row.set_pixel(clampi(at.x + dx, 0, row.get_width() - 1), clampi(at.y + dy, 0, FRAME.y - 1), dot)
	return row


## A painted 4 × image back to 1 ×: each 4 × 4 block becomes the colour most of it is (transparent if most of it is),
## snapped to the nearest colour of `palette_from` (the approved model or its normal map).
static func shrink(painted: Image, palette_from: Image) -> Image:
	var palette := _palette(palette_from)
	var w := painted.get_width() / SCALE
	var h := painted.get_height() / SCALE
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var counts := {}
			var clear := 0
			for dy in SCALE:
				for dx in SCALE:
					var c := painted.get_pixel(x * SCALE + dx, y * SCALE + dy)
					if c.a < 0.5:
						clear += 1
						continue
					var k := _nearest(c, palette)
					counts[k] = counts.get(k, 0) + 1
			if clear * 2 >= SCALE * SCALE or counts.is_empty():
				continue
			var best := -1
			var most := 0
			for k in counts:
				if counts[k] > most:
					most = counts[k]
					best = k
			out.set_pixel(x, y, palette[best])
	return out


static func _palette(img: Image) -> Array:
	var seen := {}
	var out := []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and not seen.has(c.to_rgba32()):
				seen[c.to_rgba32()] = true
				out.append(Color(c.r, c.g, c.b, 1.0))
	return out


static func _nearest(c: Color, palette: Array) -> int:
	var best := 0
	var best_d := INF
	for i in palette.size():
		var p: Color = palette[i]
		var d := Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length_squared()
		if d < best_d:
			best_d = d
			best = i
	return best


## Check a delivered sheet (row 2: the walk) against the guide: the outline close to the guide's, each foot's sole
## on its own side at the guide's height, the head still the approved head.
static func check(sheet: Image) -> Dictionary:
	var lines: Array[String] = []
	var ok := true
	if sheet == null or sheet.get_width() < FRAME.x * FRAMES or sheet.get_height() < FRAME.y * 2:
		return {"ok": false, "lines": ["the sheet must be %d × %d or more: row 1 idle, row 2 the walk" % [FRAME.x * FRAMES, FRAME.y * 2]]}
	var g := guide(_img(PARTS))
	var data := frame_data()
	var parts := _img(PARTS)
	for i in FRAMES:
		var both := 0
		var either := 0
		for y in FRAME.y:
			for x in FRAME.x:
				var a := g.get_pixel(i * FRAME.x + x, y).a > 0.5
				var b := sheet.get_pixel(i * FRAME.x + x, FRAME.y + y).a > 0.5
				both += 1 if a and b else 0
				either += 1 if a or b else 0
		var overlap := float(both) / float(maxi(1, either))
		var line := "frame %d: outline %d%%" % [i + 1, roundi(overlap * 100.0)]
		if overlap < MIN_OVERLAP:
			ok = false
			line += " ✗"
		for side in [["left", "l", "r"], ["right", "r", "l"]]:
			var cols := _own_columns(parts, i, side[1], side[2])
			var want := _lowest(_only(parts, i, ["shin_" + side[1]]), 0, 0, cols)
			var got := _lowest(sheet, i * FRAME.x, FRAME.y, cols)
			var good: bool = want >= 0 and absi(got - want) <= FOOT_TOLERANCE
			line += "  ·  %s sole row %d (guide %d)%s" % [side[0], got, want, "" if good else " ✗"]
			ok = ok and good
		var same := _head_same(sheet, i, _only(parts, i, ["head"]))
		line += "  ·  head %d%% his own%s" % [roundi(same * 100.0), "" if same >= MIN_HEAD_SAME else " ✗"]
		ok = ok and same >= MIN_HEAD_SAME
		lines.append(line)
	lines.append("PASS" if ok else "FAIL: see the ✗ marks")
	return {"ok": ok, "lines": lines}


## Walk frame `i` with only the parts named.
static func _only(parts: Image, i: int, names: Array) -> Image:
	return Rig.compose(parts, pose(i), SOUTH, ROOT, FRAME, Rig.PARTS.keys().filter(func(n): return not n in names))


## The columns of walk frame `i` where only this leg's shin and boot are (side `s`, the other leg `o`): there a
## sole can't be mistaken for the other foot.
static func _own_columns(parts: Image, i: int, s: String, o: String) -> Array:
	var mine := _only(parts, i, ["shin_" + s])
	var other := _only(parts, i, ["shin_" + o])
	var out := []
	for x in FRAME.x:
		var has_mine := false
		var has_other := false
		for y in FRAME.y:
			has_mine = has_mine or mine.get_pixel(x, y).a > 0.5
			has_other = has_other or other.get_pixel(x, y).a > 0.5
		if has_mine and not has_other:
			out.append(x)
	return out


## The lowest opaque row among columns `cols` of the 80 × 80 frame at (`ox`, `oy`) in `img`, or -1.
static func _lowest(img: Image, ox: int, oy: int, cols: Array) -> int:
	for y in range(FRAME.y - 1, -1, -1):
		for x in cols:
			if img.get_pixel(ox + int(x), oy + y).a > 0.5:
				return y
	return -1


## How much of the head in walk frame `i` is the head the guide has there, colour for colour.
static func _head_same(sheet: Image, i: int, head: Image) -> float:
	var total := 0
	var same := 0
	for y in FRAME.y:
		for x in FRAME.x:
			var m := head.get_pixel(x, y)
			if m.a < 0.5:
				continue
			total += 1
			var c := sheet.get_pixel(i * FRAME.x + x, FRAME.y + y)
			if c.a > 0.5 and Vector3(c.r - m.r, c.g - m.g, c.b - m.b).length() <= HEAD_COLOUR_NEAR:
				same += 1
	return float(same) / float(maxi(1, total))


## The prompt, frame by frame, with the skeleton's numbers.
static func prompt(data: Array) -> String:
	var t := """# Thomas, south walk: the prompt (ART_JOBS 15-W)

Thomas walks towards the camera. Paint his walk in the look of the **first painted sprites**: hand-painted pixel art,
the approved model's colours and detail (`assets/characters/thomas/rig/production/model-s.png`), the house style. His
**whole body moves**: legs stepping, arms swinging against the legs, the body rising and falling, the coat swaying.

**How, for every frame:**

1. Open that frame of `guide_walk_s_4x.png` (320 × 320 a frame, 4 × the game's size). It is Thomas already in the
   pose, made from the approved model's own pieces: every limb is where it must be, but rough where pieces turned.
2. **Paint the frame over it at 4 ×,** as a clean painting of Thomas in exactly that pose: same outline, same
   positions of the feet, hands, head and coat hem (within a pixel of the game's size, so 4 px at this size). Fix
   every rough edge, doubled pixel and gap; make the folds of the coat follow the step.
3. **Keep him the approved Thomas:** the same face and hair, the red scarf, the strap, satchel and lantern, the long
   warm dark-brown coat. Paint **the head as in the model**: it barely changes between frames.
4. **Left and right never swap.** In `key_walk_s_4x.png` his LEFT leg is red and LEFT arm orange, his RIGHT leg blue
   and RIGHT arm cyan. Facing us, his left is on the picture's **right**. Each arm swings with the opposite leg.
5. Paint each frame as **its own edit**, starting from its guide, never from the frame before (that is how the walk
   drifted last time).
6. Paint on a transparent background, 4 × 4 screen pixels for every game pixel, colours from the model. Then the
   normal map the same way, over `guide_walk_s_n_4x.png`.

**In two steps:**

- **Step A, the key frames: %s.** Each foot down, and each passing. Deliver them for Julian to approve before
  anything else.
- **Step B, the in-between frames** (the others), each between two approved key frames.

**Then:** put the eight 4 × frames in one row (2560 × 320) as `assets/characters/thomas/dir/production/walk_s_4x.png`
(and `walk_s_n_4x.png`), and shrink them to the game's size with the tool, which snaps every pixel to the model's colours:
`godot --headless --path . -s tools/pose_guides/walk_guides.gd -- shrink <walk_s_4x.png> <walk_s.png>` (add `normal`
for the normal map). Make `assets/characters/thomas/dir/s.png` (640 × 160): row 1, six copies of the approved model
(standing), row 2, the eight shrunk walk frames; `s_n.png` the same. Then
`godot --headless --path . -s tools/pose_guides/walk_guides.gd -- check res://assets/characters/thomas/dir/s.png`
must print PASS: the outline within reach of the guide's, each foot on its own side and height, the head his own.

## The frames

""" % ", ".join(KEYS.map(func(k): return str(k)))
	for d in data:
		t += "**Frame %d%s.** %s %s %s\n\n" % [d.frame, " (key frame)" if d.key else "", _body_words(d.body_shift),
			_side_words("LEFT", "red leg, orange arm, on the picture's right", d.left),
			_side_words("RIGHT", "blue leg, cyan arm, on the picture's left", d.right)]
	return t


static func _body_words(s: Array) -> String:
	var parts: Array[String] = []
	if int(s[1]) != 0:
		parts.append("%d px %s" % [absi(int(s[1])), "lower" if int(s[1]) > 0 else "higher"])
	if int(s[0]) != 0:
		parts.append("%d px further to the picture's %s" % [absi(int(s[0])), "right" if int(s[0]) > 0 else "left"])
	return "Compared with standing, his body is %s." % " and ".join(parts) if not parts.is_empty() else "His body is where it is standing."


static func _side_words(name: String, where: String, f: Dictionary) -> String:
	var fwd := int(f.forward_px)
	var pos := "under him" if absi(fwd) <= 1 else ("%d px ahead" % fwd if fwd > 0 else "%d px behind" % -fwd)
	var foot := ("planted %s, sole flat on the floor at row %d" % [pos, int(f.sole_row)]) if f.planted else ("lifted %d px and swinging forward, %s, sole at row %d" % [int(f.lift_px), pos, int(f.sole_row)])
	var hand := int(f.hand_forward_px)
	var arm := "hanging straight" if absi(hand) <= 1 else ("swung forward" if hand > 0 else "swung back")
	return "His %s side (%s): foot %s; arm %s." % [name, where, foot, arm]


static func _img(path: String) -> Image:
	var p := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var img := Image.load_from_file(p)
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
	return img


## Saves `<name>.png` at 1 × and `<name>_4x.png` at 4 × (the one to paint over).
func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	var big := img.duplicate()
	big.resize(img.get_width() * SCALE, img.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(OUT + name + "_4x.png"))
