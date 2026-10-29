class_name ActorView
extends Node2D
## A creature on the map: lives on a grid square, glides between squares, flinches, falls and dies.
## With a sprite sheet (`sheet`), it plays the row that fits what the creature is doing.
## Without one, subclasses draw a placeholder body in _draw_body().

signal stepped(from: Vector2i, to: Vector2i)

const TILE := 32
const STEP_TIME := 0.11

var grid_pos: Vector2i = Vector2i.ZERO
var facing := 1
var flash := 0.0
var prone := false
var dead := false
var crushed := false
var dying := false
var dazed := false
var raised := false     # winding up a big blow
var bleeding := false
var hurt := 0.0         # 0 unhurt .. 1 nearly dead
var sheet: Sheet = null # the art, when there is some

const DAZED_STRIP := "res://assets/effects/mace/dazed.png"
static var _dazed_tex: Texture2D = null
var _anim := "idle"
var _anim_t := 0.0
var _once := ""         # a one-shot animation playing over everything else (hurt, attack, pushed back)
var _queue: Array[String] = []   # one-shots to play after it, in order
var _walk_linger := 0.0 # keep the walk going briefly between steps

var _from_px := Vector2.ZERO
var _to_px := Vector2.ZERO
var _t := 1.0
var _bob := 0.0
var _step_time := STEP_TIME
var _lunge := Vector2.ZERO
var _time := 0.0


func place(c: Vector2i) -> void:
	grid_pos = c
	_to_px = cell_to_px(c)
	_from_px = _to_px
	_t = 1.0
	position = _to_px
	queue_redraw()


static func cell_to_px(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)


func move_to(c: Vector2i, time := STEP_TIME) -> void:
	var from := grid_pos
	if c.x != from.x:
		facing = 1 if c.x > from.x else -1
	_from_px = position
	_to_px = cell_to_px(c)
	_t = 0.0
	_step_time = time
	_walk_linger = 0.3
	grid_pos = c
	stepped.emit(from, c)
	queue_redraw()


func is_gliding() -> bool:
	return _t < 1.0


func face_toward(c: Vector2i) -> void:
	if c.x != grid_pos.x:
		facing = 1 if c.x > grid_pos.x else -1
		queue_redraw()


## A short jab of the whole body toward a square, for attacks.
func lunge_at(c: Vector2i, strength := 8.0) -> void:
	face_toward(c)
	_lunge = (cell_to_px(c) - cell_to_px(grid_pos)).normalized() * strength
	play_once("attack")
	queue_redraw()


func hit_flash() -> void:
	flash = 1.0
	play_once("hurt")


## Play one row of the sheet through once, over whatever else it is doing (if the sheet has that row).
func play_once(name: String) -> void:
	if sheet == null or not sheet.has(name) or dead:
		return
	_queue.clear()
	_once = name
	_anim = name
	_anim_t = 0.0
	queue_redraw()


## Play several one-shots back to back (wind-up, strike, recovery). Rows the sheet lacks are skipped.
func play_sequence(names: Array[String]) -> void:
	var have: Array[String] = []
	if sheet != null:
		for n in names:
			if sheet.has(n):
				have.append(n)
	if have.is_empty() or dead:
		return
	play_once(have[0])
	_queue = have.slice(1)


## Copy the look of a combatant: prone, dazed, dying, how hurt.
func sync(u: Combatant) -> void:
	prone = u.prone
	dazed = u.dazed > 0
	dying = u.dying
	dead = u.dead
	crushed = u.crushed
	bleeding = u.bleeding
	raised = not u.telegraph.is_empty()
	hurt = clampf(1.0 - u.health_ratio(), 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var redraw := false
	if sheet != null:
		_anim_t += delta
		_walk_linger = maxf(0.0, _walk_linger - delta)
		if _once != "" and _anim_t >= sheet.duration(_once):
			_once = _queue.pop_front() if not _queue.is_empty() else ""
			if _once != "":
				_anim = _once
				_anim_t = 0.0
		redraw = true
	if _t < 1.0:
		_t = minf(1.0, _t + delta / _step_time)
		var e := 1.0 - pow(1.0 - _t, 2.0)
		position = _from_px.lerp(_to_px, e)
		_bob = sin(_t * PI)
		redraw = true
	elif _bob != 0.0:
		_bob = 0.0
		redraw = true
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 7.0)
		modulate = Color(1, 1, 1).lerp(Color(3.0, 2.6, 2.4), flash)
	elif dead:
		modulate = Color(0.62, 0.58, 0.58)
	else:
		modulate = Color.WHITE
	if _lunge.length() > 0.05:
		_lunge = _lunge.lerp(Vector2.ZERO, 1.0 - exp(-delta * 12.0))
		redraw = true
	if dazed or raised or dying:
		redraw = true
	if redraw:
		queue_redraw()


func _draw() -> void:
	if sheet != null:
		_draw_sheet()
		return
	if dead:
		draw_set_transform(Vector2(0, 8), PI / 2.0 * facing, Vector2.ONE)
		_draw_body()
		_draw_wounds()
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	draw_circle(Vector2(0, 12), 7.0, Color(0, 0, 0, 0.35))
	var off := _lunge + Vector2(0, -_bob * 2.0)
	if prone:
		draw_set_transform(off + Vector2(0, 7), PI / 2.0 * facing, Vector2.ONE)
	elif dying:
		draw_set_transform(off + Vector2(0, 4), 0.35 * facing, Vector2(1, 0.85))
	else:
		draw_set_transform(off, 0, Vector2.ONE)
	_draw_body()
	_draw_wounds()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if dazed:
		for i in 3:
			var a := _time * 4.0 + i * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(a) * 7.0 - 1, -21 + sin(a) * 2.0), Vector2(2, 2)), Color(0.8, 0.85, 1.0, 0.75))
	if bleeding:
		var drip := fmod(_time * 1.5, 1.0)
		draw_rect(Rect2(Vector2(2, 2 + drip * 9.0), Vector2(1, 2)), Color(0.45, 0.03, 0.05, 1.0 - drip))


## Which row of the sheet fits what it is doing now.
func _pick_anim() -> String:
	if dead:
		return "skull_crushed" if crushed and sheet.has("skull_crushed") else "death"
	if _once != "":
		return _once
	if dying and sheet.has("dying_crawl"):
		return "dying_crawl"
	if prone:
		for n in ["lying_prone", "knocked_prone", "prone"]:
			if sheet.has(n):
				return n
		return "idle"
	if raised and sheet.has("windup"):
		return "windup"
	if dazed and sheet.has("dazed"):
		return "dazed"
	if is_gliding() or _walk_linger > 0.0:
		return "wounded_walk" if hurt >= 0.5 and sheet.has("wounded_walk") else "walk"
	return "idle"


func _draw_sheet() -> void:
	var name := _pick_anim()
	if name != _anim:
		_anim = name
		_anim_t = 0.0
	if not dead:
		draw_circle(Vector2(0, 12), 7.0, Color(0, 0, 0, 0.35))
	var off := _lunge + Vector2(0, -_bob * 2.0)
	# the art faces right; a mirrored transform turns it to face left
	var mirror := Vector2(1 if facing >= 0 else -1, 1)
	if prone and not dead and name == "idle":
		# no lying-down row in this sheet: tip the standing frame over
		draw_set_transform(off + Vector2(0, 7), PI / 2.0 * facing, mirror)
	else:
		draw_set_transform(off, 0, mirror)
	var src := sheet.frame_rect(_anim, _anim_t)
	var at := Vector2(-Sheet.ROOT.x, 12 - Sheet.ROOT.y)
	draw_texture_rect_region(sheet.texture_of(_anim), Rect2(at, Sheet.FRAME), src, _sheet_tint())
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if dazed and not dead:
		_draw_dazed()
	if bleeding and not dead:
		var drip := fmod(_time * 1.5, 1.0)
		draw_rect(Rect2(Vector2(2, 2 + drip * 9.0), Vector2(1, 2)), Color(0.45, 0.03, 0.05, 1.0 - drip))


## The ringing shimmer over a dazed head (assets/effects/mace/dazed.png, 6 frames, looped).
func _draw_dazed() -> void:
	if _dazed_tex == null and ResourceLoader.exists(DAZED_STRIP):
		_dazed_tex = load(DAZED_STRIP)
	if _dazed_tex == null:
		return
	var i := int(_time * 6.0) % 6
	draw_texture_rect_region(_dazed_tex, Rect2(Vector2(-16, -46), Vector2(32, 32)), Rect2(i * 32, 0, 32, 32))


func _sheet_tint() -> Color:
	return Color.WHITE


## Blood on the body, more as it gets hurt.
func _draw_wounds() -> void:
	var spots := [Vector2(-3, -2), Vector2(2, 1), Vector2(-1, -9), Vector2(3, -4), Vector2(-4, 3), Vector2(0, 5)]
	var n := int(hurt * spots.size())
	for i in n:
		draw_rect(Rect2(spots[i], Vector2(2, 2)), Color(0.42, 0.03, 0.05))


func _draw_body() -> void:
	pass
