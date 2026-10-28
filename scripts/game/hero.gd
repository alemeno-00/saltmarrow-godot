class_name Hero
extends Node2D
## Thomas on the map. Lives on a grid square; his drawing glides between squares.
## Placeholder art (a figure in a dark greatcoat and Ellen's red scarf) until the real sprites arrive.

signal stepped(from: Vector2i, to: Vector2i)

const TILE := 32
const STEP_TIME := 0.11

var grid_pos: Vector2i = Vector2i.ZERO
var facing := 1
var _from_px := Vector2.ZERO
var _to_px := Vector2.ZERO
var _t := 1.0
var _bob := 0.0


func place(c: Vector2i) -> void:
	grid_pos = c
	_to_px = cell_to_px(c)
	_from_px = _to_px
	_t = 1.0
	position = _to_px


static func cell_to_px(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)


func move_to(c: Vector2i) -> void:
	var from := grid_pos
	if c.x != from.x:
		facing = 1 if c.x > from.x else -1
	_from_px = position
	_to_px = cell_to_px(c)
	_t = 0.0
	grid_pos = c
	stepped.emit(from, c)
	queue_redraw()


func is_gliding() -> bool:
	return _t < 1.0


func _process(delta: float) -> void:
	if _t < 1.0:
		_t = minf(1.0, _t + delta / STEP_TIME)
		var e := 1.0 - pow(1.0 - _t, 2.0)
		position = _from_px.lerp(_to_px, e)
		_bob = sin(_t * PI)
		queue_redraw()
	elif _bob != 0.0:
		_bob = 0.0
		queue_redraw()


func _draw() -> void:
	var lift := -_bob * 2.0
	var f := float(facing)
	# shadow
	draw_circle(Vector2(0, 12), 7.0, Color(0, 0, 0, 0.35))
	# legs
	draw_rect(Rect2(-4, 4 + lift, 3, 8), Color("2a2622"))
	draw_rect(Rect2(1, 4 + lift, 3, 8), Color("2a2622"))
	# greatcoat
	draw_rect(Rect2(-6, -6 + lift, 12, 13), Color("3a3f3a"))
	draw_rect(Rect2(-6, -6 + lift, 2, 13), Color("2c302c"))
	# Ellen's scarf
	draw_rect(Rect2(-5, -7 + lift, 10, 3), Color("a8322a"))
	draw_rect(Rect2(-5 - 2 * f if f < 0 else 3, -5 + lift, 2, 5), Color("8a2a22"))
	# head
	draw_rect(Rect2(-4, -14 + lift, 8, 7), Color("c89a7a"))
	draw_rect(Rect2(-4, -15 + lift, 8, 2), Color("3a2a1e"))
	draw_rect(Rect2(1 * f if f > 0 else -3, -11 + lift, 2, 1), Color("1a1410"))
	# lantern at the hip
	draw_rect(Rect2(-8 * f - (2 if f > 0 else 0), 0 + lift, 3, 4), Color("ffcf6a"))
