class_name Gore
extends Node2D
## Blood and remains on the floor. They stay for the rest of the level.

var marks: Array = []   # [position, size, colour, shape]
var rng := RandomNumberGenerator.new()


func clear_all() -> void:
	marks.clear()
	queue_redraw()


## Spatter flung away from a blow. `amount` grows with damage.
func splash(at: Vector2, dir: Vector2, amount: float) -> void:
	var n := int(2 + amount * 1.5)
	for i in n:
		var p := at + dir * rng.randf_range(2.0, 6.0 + amount * 3.0) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-3, 7))
		var s := rng.randf_range(1.0, 2.0 + amount * 0.4)
		marks.append([p, s, Color(0.36 + rng.randf() * 0.08, 0.02, 0.04, 0.9), 0])
	queue_redraw()


## A spreading pool under a body.
func pool(at: Vector2, size: float) -> void:
	marks.append([at + Vector2(0, 8), size, Color(0.25, 0.01, 0.03, 0.92), 1])
	queue_redraw()


## Bits of a head that's no longer there.
func chunks(at: Vector2) -> void:
	for i in 7:
		var p := at + Vector2(rng.randf_range(-12, 12), rng.randf_range(-6, 12))
		var bone := rng.randf() < 0.3
		marks.append([p, rng.randf_range(1.5, 3.0), Color(0.85, 0.82, 0.75) if bone else Color(0.4, 0.04, 0.06), 2])
	splash(at, Vector2.ZERO, 6.0)


## A drag smear, when something is shoved across the floor.
func smear(from: Vector2, to: Vector2) -> void:
	marks.append([from + Vector2(0, 8), to + Vector2(0, 8), Color(0.3, 0.02, 0.04, 0.6), 3])
	queue_redraw()


func _draw() -> void:
	for m in marks:
		match m[3]:
			0:
				var s: float = m[1]
				draw_rect(Rect2(m[0] - Vector2(s, s) * 0.5, Vector2(s, s)), m[2])
			1:
				draw_set_transform(m[0], 0, Vector2(1.0, 0.5))
				draw_circle(Vector2.ZERO, m[1], m[2])
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			2:
				var s: float = m[1]
				draw_rect(Rect2(m[0], Vector2(s, s * 0.7)), m[2])
			3:
				draw_line(m[0], m[1], m[2], 3.0)
