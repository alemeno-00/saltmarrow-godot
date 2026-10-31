class_name RoomEventFx
extends Node2D
## What some room events show (design/quick-specs/room-contents-2026-10-30.md, part 5). Drawn stand-ins until art
## arrives (ART_JOBS job 14b):
## - **watcher**: a pale, thin figure standing just beyond the lantern light. It fades in, stands, and is gone.
## - **star_frost**: salt frost spreading across a room's floor from where Thomas stands, glinting, then melting.

const WATCHER_IN := 0.35
const WATCHER_HOLD := 0.9
const WATCHER_OUT := 0.25
const FROST_SPREAD := 1.6     # s to cover the room
const FROST_HOLD := 1.4
const FROST_MELT := 3.0
const FROST := Color(0.82, 0.88, 0.95)

var kind := ""
var room := Rect2()           # star frost: the room's floor, in px
var _t := 0.0
var _flecks: Array[Vector2] = []


## The pale figure at `at`, facing Thomas.
static func watcher(at: Vector2) -> RoomEventFx:
	var fx := RoomEventFx.new()
	fx.kind = "watcher"
	fx.position = at
	return fx


## Frost spreading from `from` across `room_px`, its crystals placed from `seed`.
static func frost(from: Vector2, room_px: Rect2, seed: int) -> RoomEventFx:
	var fx := RoomEventFx.new()
	fx.kind = "star_frost"
	fx.position = from
	fx.room = Rect2(room_px.position - from, room_px.size)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in int(room_px.get_area() / 55.0):
		fx._flecks.append(fx.room.position + Vector2(rng.randf() * room_px.size.x, rng.randf() * room_px.size.y))
	return fx


func lifetime() -> float:
	return WATCHER_IN + WATCHER_HOLD + WATCHER_OUT if kind == "watcher" else FROST_SPREAD + FROST_HOLD + FROST_MELT


func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime():
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if kind == "watcher":
		var a := minf(_t / WATCHER_IN, 1.0)
		if _t > WATCHER_IN + WATCHER_HOLD:
			a = 1.0 - (_t - WATCHER_IN - WATCHER_HOLD) / WATCHER_OUT
		var c := Color(0.62, 0.64, 0.66, 0.42 * clampf(a, 0.0, 1.0))
		# thin, too tall, arms hanging long: a shape, not a person
		draw_rect(Rect2(-3, -30, 6, 24), c)
		draw_circle(Vector2(0, -34), 3.5, c)
		draw_rect(Rect2(-5, -28, 1, 18), c)
		draw_rect(Rect2(4, -28, 1, 18), c)
		draw_rect(Rect2(-3, -6, 2, 10), c)
		draw_rect(Rect2(1, -6, 2, 10), c)
		draw_rect(Rect2(-2, -35, 1, 1), Color(0.95, 0.97, 1.0, c.a * 1.4))   # the eyes catch the light
		draw_rect(Rect2(1, -35, 1, 1), Color(0.95, 0.97, 1.0, c.a * 1.4))
		return
	var reach := room.size.length() * minf(_t / FROST_SPREAD, 1.0)
	var melt := 1.0
	if _t > FROST_SPREAD + FROST_HOLD:
		melt = 1.0 - (_t - FROST_SPREAD - FROST_HOLD) / FROST_MELT
	for i in _flecks.size():
		var p := _flecks[i]
		if p.length() > reach:
			continue
		var glint := 0.5 + 0.5 * sin(_t * 5.0 + i)
		var c := Color(FROST.r, FROST.g, FROST.b, (0.45 + 0.35 * glint) * melt)
		draw_rect(Rect2(p, Vector2(2, 1)), c)
		draw_rect(Rect2(p + Vector2(1, -1), Vector2(1, 3)), Color(c.r, c.g, c.b, c.a * 0.7))
