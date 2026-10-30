extends SceneTree
## Templates for painting a character's parts sheet (scripts/game/rig.gd), and a proof that the rig moves them:
##   godot --headless --path . -s tools/rig/rig_template.gd
##
## For each drawn direction, writes to design/art-briefs/animation/rig/:
## - template_<dir>.png: the parts sheet's 11 cells (24 x 24 each, in Rig.PARTS order), each with a stand-in shape of
##   that part at its rest pose and its pivot marked (white cross). ChatGPT paints the real part over the stand-in, in
##   the same cell, with the joint on the cross. Colours as the pose guides: left limbs red and orange, right limbs
##   blue and cyan, the body grey, the head pale.
## - assembled_<dir>.png: the stand-ins put together standing, as the game puts the painted parts together.
## - walk_<dir>.png: the stand-ins walking through Rig and RigPose (8 frames), the same code the game draws with.
## Each also at 4 x (`*_4x.png`). Plus standin_parts.png: the stand-ins alone on a clear ground, a sheet the game can
## load to try the rig before the painted parts arrive.

const OUT := "res://design/art-briefs/animation/rig/"
const FRAME := Vector2i(80, 80)
const ROOT := Vector2(40, 72)

const COLOURS := {
	"head": Color8(225, 212, 190), "torso": Color8(150, 150, 150), "skirt": Color8(120, 120, 120),
	"upper_arm_l": Color8(235, 150, 55), "forearm_l": Color8(235, 150, 55),
	"upper_arm_r": Color8(55, 195, 215), "forearm_r": Color8(55, 195, 215),
	"thigh_l": Color8(210, 60, 60), "shin_l": Color8(210, 60, 60),
	"thigh_r": Color8(60, 105, 215), "shin_r": Color8(60, 105, 215),
}
## part -> [length along the bone (px on screen), width]
const SHAPE := {
	"head": [10.0, 9.0], "torso": [17.0, 13.0], "skirt": [16.0, 15.0],
	"upper_arm_l": [8.0, 4.0], "forearm_l": [8.0, 4.0], "upper_arm_r": [8.0, 4.0], "forearm_r": [8.0, 4.0],
	"thigh_l": [12.5, 5.0], "shin_l": [12.5, 4.5], "thigh_r": [12.5, 5.0], "shin_r": [12.5, 4.5],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_standins().save_png(ProjectSettings.globalize_path(OUT + "standin_parts.png"))
	for d in Rig.DIRS:
		var sheet := _standins()
		_save(_template(sheet), "template_" + d)
		_save(_frames([RigPose.idle(0.0)], sheet, Rig.DIRS[d]), "assembled_" + d)
		var poses: Array = []
		for i in 8:
			poses.append(RigPose.walk(i / 8.0))
		_save(_frames(poses, sheet, Rig.DIRS[d]), "walk_" + d)
	print("rig templates written to ", OUT)
	quit()


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	var big := img.duplicate()
	big.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(OUT + name + "_4x.png"))


## A parts sheet of stand-in shapes: each part a rounded bar from its pivot along its rest direction.
func _standins() -> Image:
	var img := Image.create(int(Rig.CELL.x) * Rig.PARTS.size(), int(Rig.CELL.y), false, Image.FORMAT_RGBA8)
	for name in Rig.PARTS:
		var d: Array = Rig.PARTS[name]
		var origin := Vector2(d[0] * Rig.CELL.x, 0) + (d[1] as Vector2)
		var length: float = SHAPE[name][0]
		var half: float = SHAPE[name][1] / 2.0
		var dir := Vector2(0, d[3] if false else d[4])
		for i in int(length) + 1:
			var c := origin + dir * i
			for y in range(floori(c.y - half), ceili(c.y + half) + 1):
				for x in range(floori(c.x - half), ceili(c.x + half) + 1):
					if Vector2(x + 0.5, y + 0.5).distance_to(c) <= half and x >= d[0] * Rig.CELL.x and x < (d[0] + 1) * Rig.CELL.x and y >= 0 and y < Rig.CELL.y:
						img.set_pixel(x, y, COLOURS[name])
	return img


## The template: the stand-ins on a light ground, each cell outlined, its pivot marked.
func _template(sheet: Image) -> Image:
	var img := Image.create(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
	img.fill(Color8(232, 228, 220))
	for name in Rig.PARTS:
		var d: Array = Rig.PARTS[name]
		var x0 := int(d[0] * Rig.CELL.x)
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


## Poses drawn from a parts sheet through the rig, one 80 x 80 frame each: the same placements the game uses,
## drawn here pixel by pixel.
func _frames(poses: Array, sheet: Image, f: Vector2) -> Image:
	var img := Image.create(FRAME.x * poses.size(), FRAME.y, false, Image.FORMAT_RGBA8)
	for i in poses.size():
		var at := Vector2(i * FRAME.x, 0)
		for pl in Rig.placements(poses[i], f, ROOT):
			_blit_part(img, sheet, pl, at)
	return img


## Draw one part rotated about its pivot, nearest pixel (as the game draws pixel art).
func _blit_part(img: Image, sheet: Image, pl: Dictionary, at: Vector2) -> void:
	var cell := Rect2(Vector2(pl.cell * Rig.CELL.x, 0), Rig.CELL)
	var pivot: Vector2 = pl.pivot
	var to_part := Transform2D(pl.angle, at + (pl.at as Vector2)).affine_inverse()
	var reach := Rig.CELL.length()
	var centre: Vector2 = at + pl.at
	for y in range(floori(centre.y - reach), ceili(centre.y + reach)):
		for x in range(floori(centre.x - reach), ceili(centre.x + reach)):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var local: Vector2 = to_part * Vector2(x + 0.5, y + 0.5) + pivot
			if local.x < 0 or local.y < 0 or local.x >= Rig.CELL.x or local.y >= Rig.CELL.y:
				continue
			var c := sheet.get_pixel(int(cell.position.x + local.x), int(local.y))
			if c.a > 0.5:
				img.set_pixel(x, y, c)


func _px(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixel(p.x, p.y, c)
