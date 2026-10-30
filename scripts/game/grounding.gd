class_name Grounding
extends RefCounted
## What makes a creature look like it stands *in* the room rather than pasted on top of it (playtest 2026-10-30):
## - a soft contact shadow under the feet, and a longer one cast away from the nearest lantern or brazier;
## - feet sunk into water, with a ring of ripples round them, when it wades;
## - a normal map, so the room's lights light the side of the body that faces them. Generated here from the sprite's
##   shape (a rounded bevel) until ChatGPT's painted normal maps arrive (art job 17: `<sheet>_n.png` beside the
##   sheet, used instead when present).

const SHADOW_REACH := 150.0      # px: lights further than this cast no long shadow
const SHADOW_LENGTH := 18.0      # px: the longest a cast shadow gets, right beside a light
const SHADOW_ALPHA := 0.32
const CONTACT_ALPHA := 0.42
const WADE_DEPTH := 5            # px of the body hidden under the water
const BEVEL := 2.2               # how rounded the generated normal maps make the body
const LIGHT_HEIGHT := 28.0       # px: how high the lights hang above the floor, for normal mapping

static var level: Level = null
static var lights: Array[Vector2] = []   # the room's lantern and brazier positions
static var hero_light := Vector2.INF      # Thomas's own lantern, which throws everyone else's shadows
static var _lit := {}                     # texture -> CanvasTexture with a normal map


## The light that throws this creature's shadow: the nearest within reach (Thomas's lantern doesn't count for him).
static func shadow_light(at: Vector2, is_hero: bool) -> Vector2:
	var best := Vector2.INF
	var best_d := SHADOW_REACH
	for l in lights:
		var d := at.distance_to(l)
		if d < best_d:
			best_d = d
			best = l
	if not is_hero and hero_light != Vector2.INF and at.distance_to(hero_light) < best_d:
		best = hero_light
	return best


static func wading(at: Vector2) -> bool:
	return level != null and level.get_tile(MovementRules.cell_of(at)) == Level.Tile.WATER


## Draw the shadows on `item` (an ActorView), with the feet at `feet` in its own space.
static func draw_shadows(item: CanvasItem, at: Vector2, feet: Vector2, is_hero: bool, wet: bool) -> void:
	item.draw_set_transform(feet, 0, Vector2(1, 0.45))
	item.draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, CONTACT_ALPHA * (0.5 if wet else 1.0)))
	item.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if wet:
		return
	var l := shadow_light(at, is_hero)
	if l == Vector2.INF:
		return
	var d := at.distance_to(l)
	var s := clampf(1.0 - d / SHADOW_REACH, 0.0, 1.0)
	var dir := (at - l).normalized() if d > 0.5 else Vector2.DOWN
	var length := 5.0 + SHADOW_LENGTH * s
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		var q := Vector2(cos(a) * length * 0.5, sin(a) * 4.5).rotated(dir.angle()) + dir * length * 0.5
		pts.append(feet + Vector2(q.x, q.y * 0.55))   # laid flat on the floor
	item.draw_colored_polygon(pts, Color(0, 0, 0, SHADOW_ALPHA * (0.35 + 0.65 * s)))


## The water round a wading creature's legs: a dark film and a ring of ripples at the waterline.
static func draw_waterline(item: CanvasItem, feet: Vector2, t: float) -> void:
	var line := feet - Vector2(0, WADE_DEPTH)
	item.draw_set_transform(line, 0, Vector2(1, 0.38))
	item.draw_circle(Vector2.ZERO, 10.0, Color(0.06, 0.12, 0.13, 0.35))
	var r := 9.0 + sin(t * 3.0) * 0.8
	item.draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(Ripple.COLOUR, 0.55), 1.5)
	item.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## The sheet as a lit texture: its painted normal map (`<name>_n.png`) if ChatGPT has delivered one, otherwise one
## made from the sprite's shape.
static func lit(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key := tex.get_instance_id()
	if _lit.has(key):
		return _lit[key]
	var ct := CanvasTexture.new()
	ct.diffuse_texture = tex
	var painted := tex.resource_path.get_basename() + "_n.png"
	ct.normal_texture = load(painted) if tex.resource_path != "" and ResourceLoader.exists(painted) else normal_map(tex)
	_lit[key] = ct
	return ct


## A normal map from a sprite's shape: the body bevelled round at its edges, flat in the middle (OpenGL style:
## red is right, green is up).
static func normal_map(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var src := img.get_data()
	# height: the body's silhouette, blurred so its edges slope
	var mask := Image.create(w, h, false, Image.FORMAT_L8)
	var md := PackedByteArray()
	md.resize(w * h)
	for i in w * h:
		md[i] = src[i * 4 + 3]
	mask.set_data(w, h, false, Image.FORMAT_L8, md)
	mask.resize(maxi(1, w / 3), maxi(1, h / 3), Image.INTERPOLATE_BILINEAR)
	mask.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var hd := mask.get_data()
	var out := PackedByteArray()
	out.resize(w * h * 4)
	for y in h:
		for x in w:
			var i := y * w + x
			if src[i * 4 + 3] < 128:
				out[i * 4] = 128
				out[i * 4 + 1] = 128
				out[i * 4 + 2] = 255
				out[i * 4 + 3] = 0
				continue
			var dx := (float(hd[y * w + mini(x + 1, w - 1)]) - float(hd[y * w + maxi(x - 1, 0)])) / 255.0
			var dy := (float(hd[mini(y + 1, h - 1) * w + x]) - float(hd[maxi(y - 1, 0) * w + x])) / 255.0
			var n := Vector3(-dx * BEVEL, dy * BEVEL, 1.0).normalized()   # green up: an upper edge faces up
			out[i * 4] = int((n.x * 0.5 + 0.5) * 255.0)
			out[i * 4 + 1] = int((n.y * 0.5 + 0.5) * 255.0)
			out[i * 4 + 2] = int((n.z * 0.5 + 0.5) * 255.0)
			out[i * 4 + 3] = 255
	return ImageTexture.create_from_image(Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out))
