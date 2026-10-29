class_name Ripple
extends Node2D
## A ring spreading on the water where someone wades, or a splash (two rings and flung drops) where someone goes down
## in it. Flattened, to sit on the floor in the slightly-from-above view, and gone after a moment.

const LIFE := 0.7          # seconds a wading ring lasts
const SPLASH_LIFE := 1.0
const RADIUS := 13.0       # pixels a wading ring spreads to
const SPLASH_RADIUS := 19.0
const FLATTEN := 0.45      # rings are this tall for their width
const COLOUR := Color(0.7, 0.88, 0.92)

var big := false
var _t := 0.0
var _drops: Array[Vector2] = []


static func spawn(parent: Node, at: Vector2, splash := false) -> void:
	var r := Ripple.new()
	r.big = splash
	r.position = at
	if splash:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(at)
		for i in 6:
			r._drops.append(Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(6.0, 14.0))
	parent.add_child(r)


func _process(delta: float) -> void:
	# real time, so hitstop and slow motion don't freeze the water
	_t += delta / maxf(Engine.time_scale, 0.05)
	if _t >= (SPLASH_LIFE if big else LIFE):
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var life := SPLASH_LIFE if big else LIFE
	var k := _t / life
	var fade := 1.0 - k
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, FLATTEN))
	var radius := (SPLASH_RADIUS if big else RADIUS) * (0.3 + 0.7 * k)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(COLOUR, 0.85 * fade), 2.0)
	if big:
		draw_arc(Vector2.ZERO, radius * 0.55, 0, TAU, 18, Color(COLOUR, 0.4 * fade), 1.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if big:
		# drops flung up and falling back
		for d in _drops:
			var p := d * k + Vector2(0, -16.0 * sin(k * PI))
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(COLOUR, fade))
