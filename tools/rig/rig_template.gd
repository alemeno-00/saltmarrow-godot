extends SceneTree
## Templates for a character's parts sheet (scripts/game/rig.gd), how to cut one from an approved whole model, and a
## check that a cut is right:
##   godot --headless --path . -s tools/rig/rig_template.gd
##   godot --headless --path . -s tools/rig/rig_template.gd -- guide <model.png> [out.png]
##   godot --headless --path . -s tools/rig/rig_template.gd -- check <model.png> <parts.png>
##
## With no arguments, writes to design/art-briefs/animation/rig/:
## - bind_s.json: for each of the 11 parts, its cell, the pivot in the cell, where that pivot falls on the 80 x 80
##   south model in the bind pose (RigPose.bind, feet at (40, 72)), and the 24 x 24 square of the model to copy into
##   the cell. This is how a parts sheet is cut from an approved model (house style rule 10): copy, don't repaint.
## - template_s.png: the 11 cells (24 x 24 each, in Rig.PARTS order) with a stand-in shape of each part and its pivot
##   (white cross). Colours: left limbs red and orange, right limbs blue and cyan, the body grey, the head pale.
## - assembled_s.png: the stand-ins put together in the bind pose; walk_s.png: walking (8 frames). Both drawn by
##   Rig.compose, the placements the game uses. Each also at 4 x.
## - standin_parts.png: the stand-ins alone, a sheet the game can load to try the rig.
## - If Thomas's approved model is in the project, cut_guide_s.png: the model at 8 x with each cell's square and pivot.
##
## `guide <model>` writes that cut guide for any model; `check <model> <parts>` puts the parts back together in the
## bind pose and reports every pixel that differs from the model (none means the cut is right).

const OUT := "res://design/art-briefs/animation/rig/"
const MODEL := "res://assets/characters/thomas/rig/production/model-s.png"
const FRAME := Vector2i(80, 80)
const ROOT := Vector2(40, 72)
const SOUTH := Vector2(0, -1)

const COLOURS := {
	"head": Color8(225, 212, 190), "torso": Color8(150, 150, 150), "skirt": Color8(120, 120, 120),
	"upper_arm_l": Color8(235, 150, 55), "forearm_l": Color8(235, 150, 55),
	"upper_arm_r": Color8(55, 195, 215), "forearm_r": Color8(55, 195, 215),
	"thigh_l": Color8(210, 60, 60), "shin_l": Color8(210, 60, 60),
	"thigh_r": Color8(60, 105, 215), "shin_r": Color8(60, 105, 215),
}
## part -> [length from the pivot along the bone (px on screen), width], matching the model's measured proportions
## (RigPose): the boot is painted on the shin, the hand on the forearm.
const SHAPE := {
	"head": [9.0, 8.0], "torso": [19.0, 14.0], "skirt": [12.0, 15.0],
	"upper_arm_l": [8.0, 4.0], "forearm_l": [9.0, 4.0], "upper_arm_r": [8.0, 4.0], "forearm_r": [9.0, 4.0],
	"thigh_l": [9.0, 5.0], "shin_l": [12.0, 4.5], "thigh_r": [9.0, 5.0], "shin_r": [12.0, 4.5],
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "guide":
		_cut_guide(_load(args[1])).save_png(args[2] if args.size() > 2 else "cut_guide.png")
		print("cut guide written")
		quit()
		return
	if args.size() >= 3 and args[0] == "check":
		var bad := check(_load(args[1]), _load(args[2]))
		print("%d pixels differ from the model" % bad.size())
		for b in bad.slice(0, 40):
			print("  ", b)
		quit(1 if not bad.is_empty() else 0)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var f := FileAccess.open(OUT + "bind_s.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(bind_table(), "\t"))
	f.close()
	var sheet := _standins()
	sheet.save_png(ProjectSettings.globalize_path(OUT + "standin_parts.png"))
	_save(_template(sheet), "template_s")
	_save(Rig.compose(sheet, RigPose.bind(), SOUTH, ROOT, FRAME), "assembled_s")
	var walk := Image.create(FRAME.x * 8, FRAME.y, false, Image.FORMAT_RGBA8)
	for i in 8:
		walk.blit_rect(Rig.compose(sheet, RigPose.walk(i / 8.0), SOUTH, ROOT, FRAME), Rect2i(Vector2i.ZERO, FRAME), Vector2i(i * FRAME.x, 0))
	_save(walk, "walk_s")
	if FileAccess.file_exists(MODEL):
		_cut_guide(_load(MODEL)).save_png(ProjectSettings.globalize_path(OUT + "cut_guide_s.png"))
	print("rig templates written to ", OUT)
	quit()


## For each part: its cell, its pivot in the cell, its pivot on the model, and the model's square that goes in the cell.
static func bind_table() -> Dictionary:
	var anchors := Rig.bind_anchors(SOUTH, ROOT)
	var parts := {}
	for name in Rig.PARTS:
		var d: Array = Rig.PARTS[name]
		var r := Rig.cut_rect(name, SOUTH, ROOT)
		parts[name] = {"cell": d[0], "cell_x": int(d[0] * Rig.CELL.x), "pivot_in_cell": [int(d[1].x), int(d[1].y)],
			"pivot_on_model": [anchors[name].x, anchors[name].y], "model_square": [r.position.x, r.position.y, r.size.x, r.size.y]}
	return {"model": "80 x 80, south, feet at (40, 72)", "pose": "RigPose.bind(): standing as painted, every part at angle 0",
		"rule": "copy model pixel (x, y) into the part's cell at (x - model_square.x + cell_x, y - model_square.y); each model pixel goes to exactly one part",
		"parts": parts}


## Every pixel where the parts, put back together in the bind pose, differ from the model: [x, y, model, rebuilt].
static func check(model: Image, parts: Image) -> Array:
	var rebuilt := Rig.compose(parts, RigPose.bind(), SOUTH, ROOT, FRAME)
	var bad := []
	for y in FRAME.y:
		for x in FRAME.x:
			var a := model.get_pixel(x, y)
			var b := rebuilt.get_pixel(x, y)
			var same := (a.a < 0.5 and b.a < 0.5) or (a.a >= 0.5 and b.a >= 0.5 and a.to_rgba32() == b.to_rgba32())
			if not same:
				bad.append([x, y, a.to_html(), b.to_html()])
	return bad


func _load(path: String) -> Image:
	var real := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var img := Image.load_from_file(real)
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	var big := img.duplicate()
	big.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(OUT + name + "_4x.png"))


## The model at 8 x, each part's square outlined in its colour and its pivot marked.
func _cut_guide(model: Image) -> Image:
	var k := 8
	var img := model.duplicate()
	img.resize(FRAME.x * k, FRAME.y * k, Image.INTERPOLATE_NEAREST)
	var bg := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	bg.fill(Color8(232, 228, 220))
	bg.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
	var anchors := Rig.bind_anchors(SOUTH, ROOT)
	for name in Rig.PARTS:
		var r := Rig.cut_rect(name, SOUTH, ROOT)
		var c: Color = COLOURS[name]
		for i in r.size.x * k:
			_px(bg, Vector2i(r.position.x * k + i, r.position.y * k), c)
			_px(bg, Vector2i(r.position.x * k + i, r.end.y * k - 1), c)
		for i in r.size.y * k:
			_px(bg, Vector2i(r.position.x * k, r.position.y * k + i), c)
			_px(bg, Vector2i(r.end.x * k - 1, r.position.y * k + i), c)
		var p: Vector2i = anchors[name] * k
		for j in range(-6, 7):
			_px(bg, p + Vector2i(j, 0), Color.WHITE)
			_px(bg, p + Vector2i(0, j), Color.WHITE)
		_px(bg, p, Color.BLACK)
	return bg


## A parts sheet of stand-in shapes: each part a rounded bar from its pivot along its rest direction.
func _standins() -> Image:
	var img := Image.create(int(Rig.CELL.x) * Rig.PARTS.size(), int(Rig.CELL.y), false, Image.FORMAT_RGBA8)
	for name in Rig.PARTS:
		var d: Array = Rig.PARTS[name]
		var x0 := int(d[0] * Rig.CELL.x)
		var origin := Vector2(x0, 0) + (d[1] as Vector2) + Vector2(0.5, 0.5)
		var length: float = SHAPE[name][0]
		var half: float = SHAPE[name][1] / 2.0
		var dir := Vector2(0, d[4])
		for i in int(length) + 1:
			var c := origin + dir * i
			for y in range(floori(c.y - half), ceili(c.y + half) + 1):
				for x in range(floori(c.x - half), ceili(c.x + half) + 1):
					if Vector2(x + 0.5, y + 0.5).distance_to(c) <= half and x >= x0 and x < x0 + int(Rig.CELL.x) and y >= 0 and y < Rig.CELL.y:
						img.set_pixel(x, y, COLOURS[name])
	return img


## The template: the stand-ins on a light ground, each cell outlined, its pivot marked.
func _template(sheet: Image) -> Image:
	var img := Image.create(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
	img.fill(Color8(232, 228, 220))
	for name in Rig.PARTS:
		var x0 := int(Rig.PARTS[name][0] * Rig.CELL.x)
		for i in int(Rig.CELL.x):
			img.set_pixel(x0 + i, 0, Color8(160, 155, 145))
		for i in int(Rig.CELL.y):
			img.set_pixel(x0, i, Color8(160, 155, 145))
	img.blend_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i.ZERO)
	for name in Rig.PARTS:
		var d: Array = Rig.PARTS[name]
		var p := Vector2i(Vector2(d[0] * Rig.CELL.x, 0) + (d[1] as Vector2))
		for k in range(-2, 3):
			_px(img, p + Vector2i(k, 0), Color.WHITE)
			_px(img, p + Vector2i(0, k), Color.WHITE)
		_px(img, p, Color.BLACK)
	return img


static func _px(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixel(p.x, p.y, c)
