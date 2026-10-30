class_name Dust
extends Node2D
## A puff of grit at someone's feet: kicked up by a sharp turn, or thrown off a wall by a body slammed into it.
## Drawn under the lighting like the floor, and gone after a moment.

const LIFE := 0.45
const BIG_LIFE := 0.7
const COLOUR := Color(0.55, 0.52, 0.47)
const BITS := 5
const BIG_BITS := 9

var big := false
var _t := 0.0
var _bits: Array[Vector2] = []


## `away`: the way the dust is thrown (it spreads behind a turn, or off a wall).
static func spawn(parent: Node, at: Vector2, away: Vector2, burst := false) -> void:
	var d := Dust.new()
	d.big = burst
	d.position = at
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([at, away])
	var base := away.normalized() if away.length() > 0.01 else Vector2.UP
	for i in (BIG_BITS if burst else BITS):
		var spread := rng.randf_range(-1.1, 1.1)
		d._bits.append(base.rotated(spread) * rng.randf_range(5.0, 14.0 if burst else 9.0))
	parent.add_child(d)


func _process(delta: float) -> void:
	# real time, so a hit-stop doesn't freeze it
	_t += delta / maxf(Engine.time_scale, 0.05)
	if _t >= (BIG_LIFE if big else LIFE):
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var k := _t / (BIG_LIFE if big else LIFE)
	var out := 1.0 - pow(1.0 - k, 2.0)
	for b in _bits:
		var p := Vector2(b.x, b.y * 0.5) * out
		var size := (2.0 if big else 1.5) + 2.5 * k
		draw_circle(p, size, Color(COLOUR, 0.5 * (1.0 - k)))
