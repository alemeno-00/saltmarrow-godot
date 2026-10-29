class_name Gore
extends Node2D
## Blood and remains on the floor. They stay for the rest of the level.
## Uses ChatGPT's gore set (assets/effects/gore/, 32 x 32 decals) where it has a piece, small drawn drops otherwise.

const DIR := "res://assets/effects/gore/"

var marks: Array = []   # [kind, ...]: "drop" [pos, size, colour] · "sprite" [pos, texture, rotation, flip] · "line" [from, to, colour]
var rng := RandomNumberGenerator.new()
var _tex := {}          # name -> Texture2D, for the pieces that exist


func _ready() -> void:
	for n in ["pool_small", "pool_medium", "pool_large", "splatter_1", "splatter_2", "splatter_3", "splatter_4",
			"drag_smear_1", "drag_smear_2", "flesh_chunk_1", "flesh_chunk_2", "flesh_chunk_3", "flesh_chunk_4",
			"severed_arm", "severed_head"]:
		if ResourceLoader.exists(DIR + n + ".png"):
			_tex[n] = load(DIR + n + ".png")


func clear_all() -> void:
	marks.clear()
	queue_redraw()


func _sprite(name: String, at: Vector2, rot := 0.0, flip := false) -> bool:
	if not _tex.has(name):
		return false
	marks.append(["sprite", at, _tex[name], rot, flip])
	return true


func _pick(names: Array) -> String:
	return names[rng.randi_range(0, names.size() - 1)]


## Spatter flung away from a blow. `amount` grows with damage.
func splash(at: Vector2, dir: Vector2, amount: float) -> void:
	if amount >= 2.0:
		var spot := at + dir * rng.randf_range(4.0, 8.0 + amount * 2.0) + Vector2(0, 8)
		_sprite(_pick(["splatter_1", "splatter_2", "splatter_3", "splatter_4"]), spot, dir.angle() if dir != Vector2.ZERO else 0.0, rng.randf() < 0.5)
	var n := int(1 + amount * 0.8)
	for i in n:
		var p := at + dir * rng.randf_range(2.0, 6.0 + amount * 3.0) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-3, 7))
		marks.append(["drop", p, rng.randf_range(1.0, 1.5 + amount * 0.3), Color(0.36 + rng.randf() * 0.08, 0.02, 0.04, 0.9)])
	queue_redraw()


## A spreading pool under a body.
func pool(at: Vector2, size: float) -> void:
	var name := "pool_small" if size < 5.0 else ("pool_medium" if size < 9.0 else "pool_large")
	if not _sprite(name, at + Vector2(0, 8), 0.0, rng.randf() < 0.5):
		marks.append(["oval", at + Vector2(0, 8), size, Color(0.25, 0.01, 0.03, 0.92)])
	queue_redraw()


## Bits of a head that's no longer there.
func chunks(at: Vector2) -> void:
	for i in 3:
		var p := at + Vector2(rng.randf_range(-12, 12), rng.randf_range(-2, 12))
		if not _sprite(_pick(["flesh_chunk_1", "flesh_chunk_2", "flesh_chunk_3", "flesh_chunk_4"]), p, rng.randf_range(-0.4, 0.4), rng.randf() < 0.5):
			marks.append(["drop", p, rng.randf_range(1.5, 3.0), Color(0.4, 0.04, 0.06)])
	for i in 3:
		marks.append(["drop", at + Vector2(rng.randf_range(-12, 12), rng.randf_range(-6, 12)), rng.randf_range(1.5, 2.5), Color(0.85, 0.82, 0.75)])
	splash(at, Vector2.ZERO, 6.0)


## A drag smear, when something is shoved across the floor.
func smear(from: Vector2, to: Vector2) -> void:
	var mid := (from + to) / 2.0 + Vector2(0, 8)
	if not _sprite(_pick(["drag_smear_1", "drag_smear_2"]), mid, (to - from).angle()):
		marks.append(["line", from + Vector2(0, 8), to + Vector2(0, 8), Color(0.3, 0.02, 0.04, 0.6)])
	queue_redraw()


func _draw() -> void:
	for m in marks:
		match m[0]:
			"drop":
				var s: float = m[2]
				draw_rect(Rect2(m[1] - Vector2(s, s) * 0.5, Vector2(s, s)), m[3])
			"oval":
				draw_set_transform(m[1], 0, Vector2(1.0, 0.5))
				draw_circle(Vector2.ZERO, m[2], m[3])
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			"line":
				draw_line(m[1], m[2], m[3], 3.0)
			"sprite":
				draw_set_transform(m[1], m[3], Vector2(-1 if m[4] else 1, 1))
				draw_texture(m[2], Vector2(-16, -16))
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
