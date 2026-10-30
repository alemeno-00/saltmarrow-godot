class_name ActorView
extends Node2D
## A creature on the map. While exploring it moves freely (glide_free); in a fight it lives on a square and glides
## between squares. It flinches, falls and dies.
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
var sheet: Sheet = null # the art, when there is some (drawn facing right, mirrored to face left)
var dir_sheets := {}    # direction -> Sheet: art drawn in five directions, used for the rows it has
var rig: Rig = null     # parts on a skeleton: draws idle, walk, sneak and the limp when there is one (Rig)
var look := Vector2.RIGHT  # the way it faces, any direction
var is_hero := false    # Thomas: his own lantern throws no shadow of him
var wading := false     # standing in water: drawn sunk to the shins
var sneaking := false   # crouched: the sneak row, held still when not moving

const DAZED_STRIP := "res://assets/effects/mace/dazed.png"
static var _dazed_tex: Texture2D = null
var _anim := "idle"
var _anim_t := 0.0
var _once := ""         # a one-shot animation playing over everything else (hurt, attack, pushed back)
var _queue: Array[String] = []   # one-shots to play after it, in order
var _walk_linger := 0.0 # keep the walk going briefly between steps
var walk_rate := 1.0    # how fast the walk plays: 1 at full walking speed
var motion := RigMotion.new()   # the rig's walk by distance, easing, lean and trailing parts
var _rig_pose := {}
var _last_px := Vector2.INF
const TELEPORT := 48.0  # px in one frame: placed, not walked

var _from_px := Vector2.ZERO
var _to_px := Vector2.ZERO
var _t := 1.0
var _bob := 0.0
var _step_time := STEP_TIME
var _lunge := Vector2.ZERO
var _hold_lunge := 0.0  # a wind-up holds its pull-back this long
var _time := 0.0
var _route: Array[Vector2] = []   # points still to walk through (a fight move)
var _route_speed := 0.0          # px/s


func place(c: Vector2i) -> void:
	_route.clear()
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
	if c != from:
		look = Vector2(c - from).normalized()
	_from_px = position
	_to_px = cell_to_px(c)
	_t = 0.0
	_step_time = time
	_walk_linger = 0.3
	walk_rate = 1.0
	grid_pos = c
	stepped.emit(from, c)
	queue_redraw()


## Stand at a point in the world (moving freely while exploring). `speed_ratio` is how fast it is going, as a share of
## full walking speed: the walk plays at that pace. Entering a new square emits `stepped`.
func glide_free(p: Vector2, speed_ratio: float) -> void:
	_route.clear()
	var d := p - position
	if absf(d.x) > 0.05:
		facing = 1 if d.x > 0.0 else -1
	if d.length() > 0.05:
		look = d.normalized()
	position = p
	_from_px = p
	_to_px = p
	_t = 1.0
	if speed_ratio > 0.05:
		_walk_linger = 0.08
		walk_rate = clampf(speed_ratio, 0.4, 1.5)
	var c := MovementRules.cell_of(p)
	if c != grid_pos:
		var from := grid_pos
		grid_pos = c
		stepped.emit(from, c)
	queue_redraw()


## Walk through a list of points at `speed` px/s (a move in a fight). Returns how long it will take.
func glide_along(points: Array, speed: float) -> float:
	_route.clear()
	var length := 0.0
	var at := position
	for p in points:
		_route.append(p)
		length += at.distance_to(p)
		at = p
	_route_speed = speed
	_t = 1.0
	return length / maxf(speed, 1.0)


func is_gliding() -> bool:
	return _t < 1.0 or not _route.is_empty()


## Turn to face a point in the world.
func face_point(p: Vector2) -> void:
	if absf(p.x - position.x) > 0.5:
		facing = 1 if p.x > position.x else -1
	if p.distance_to(position) > 0.5:
		look = (p - position).normalized()
	queue_redraw()


## The drawn direction for a way of facing, and whether to mirror it: the eight ways round, SW, W and NW being SE,
## E and NE mirrored.
static func octant(v: Vector2) -> Array:
	var i := posmod(roundi(rad_to_deg(v.angle()) / 45.0), 8)
	return [["e", false], ["se", false], ["s", false], ["se", true], ["e", true], ["ne", true], ["n", false], ["ne", false]][i]


## The art to draw an animation with, facing `look`: [Sheet, mirrored]. A directional sheet with that row if one has
## been delivered (the nearest drawn direction when its own isn't yet), otherwise the right-facing sheet.
func art_for(anim: String) -> Array:
	var best: Sheet = null
	var mirror := false
	var best_d := INF
	var want := rad_to_deg(look.angle())
	for d in dir_sheets:
		var s: Sheet = dir_sheets[d]
		if not s.has(anim):
			continue
		var a: float = {"e": 0.0, "se": 45.0, "s": 90.0, "ne": -45.0, "n": -90.0}[d]
		for m in ([false, true] if d != "s" and d != "n" else [false]):
			var ang := 180.0 - a if m else a
			var diff := absf(wrapf(want - ang, -180.0, 180.0))
			if diff < best_d - 0.01:
				best_d = diff
				best = s
				mirror = m
	if best != null:
		return [best, mirror]
	return [sheet, facing < 0]


func face_toward(c: Vector2i) -> void:
	face_point(cell_to_px(c))


## A short jab of the whole body toward a point, for attacks. `anim`: also play the sheet's attack row.
func lunge_at(p: Vector2, strength := 8.0, anim := true) -> void:
	face_point(p)
	_lunge = (p - position).normalized() * strength
	_hold_lunge = 0.0
	if anim:
		play_once("attack")
	queue_redraw()


## Draw back from a point before striking it.
func wind_up(p: Vector2, strength := 4.0) -> void:
	face_point(p)
	_lunge = -(p - position).normalized() * strength
	_hold_lunge = 1.2
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
		var walking := _once == "" and (_anim == "walk" or _anim == "wounded_walk" or _anim == "sneak")
		var moving := is_gliding() or _walk_linger > 0.0
		# a crouch held still doesn't step on the spot
		_anim_t += delta * ((walk_rate if moving else 0.0) if _anim == "sneak" else (walk_rate if walking else 1.0))
		_walk_linger = maxf(0.0, _walk_linger - delta)
		if _once != "" and _anim_t >= sheet.duration(_once):
			_once = _queue.pop_front() if not _queue.is_empty() else ""
			if _once != "":
				_anim = _once
				_anim_t = 0.0
		redraw = true
	if not _route.is_empty():
		var step := _route_speed * delta
		while step > 0.0 and not _route.is_empty():
			var to: Vector2 = _route[0]
			var d := position.distance_to(to)
			face_point(to)
			if d <= step:
				position = to
				step -= d
				_route.pop_front()
			else:
				position = position.move_toward(to, step)
				step = 0.0
		_walk_linger = 0.12
		walk_rate = 1.0
		var c := MovementRules.cell_of(position)
		if c != grid_pos:
			var from := grid_pos
			grid_pos = c
			stepped.emit(from, c)
		redraw = true
	elif _t < 1.0:
		_t = minf(1.0, _t + delta / _step_time)
		var e := 1.0 - pow(1.0 - _t, 2.0)
		position = _from_px.lerp(_to_px, e)
		_bob = sin(_t * PI)
		redraw = true
	elif _bob != 0.0:
		_bob = 0.0
		redraw = true
	var wet := Grounding.wading(position) and not prone and not dead
	if wet != wading:
		wading = wet
		redraw = true
	if not dead:
		redraw = true   # the shadow follows the lights as it moves
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 7.0)
		modulate = Color(1, 1, 1).lerp(Color(3.0, 2.6, 2.4), flash)
	elif dead:
		modulate = Color(0.62, 0.58, 0.58)
	else:
		modulate = Color.WHITE
	if _hold_lunge > 0.0:
		_hold_lunge = maxf(0.0, _hold_lunge - delta)
	elif _lunge.length() > 0.05:
		_lunge = _lunge.lerp(Vector2.ZERO, 1.0 - exp(-delta * 12.0))
		redraw = true
	if dazed or raised or dying:
		redraw = true
	if rig != null:
		_step_rig(delta)
	if redraw:
		queue_redraw()


## Move the skeleton on a frame: how fast he really went (not counting being placed somewhere), and which walk.
func _step_rig(delta: float) -> void:
	var vel := Vector2.ZERO
	if _last_px != Vector2.INF and delta > 0.0 and position.distance_to(_last_px) < TELEPORT:
		vel = (position - _last_px) / delta
	_last_px = position
	var kind := "sneak" if sneaking else ("limp" if hurt >= 0.5 else "walk")
	_rig_pose = motion.step(delta, vel, look, kind, sneaking)


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
	Grounding.draw_shadows(self, position, Vector2(0, 12), is_hero, wading)
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
	if sneaking and sheet.has("sneak"):
		return "sneak"
	if is_gliding() or _walk_linger > 0.0:
		return "wounded_walk" if hurt >= 0.5 and sheet.has("wounded_walk") else "walk"
	return "idle"


func _draw_sheet() -> void:
	var name := _pick_anim()
	if name != _anim:
		_anim = name
		_anim_t = 0.0
	if not dead:
		Grounding.draw_shadows(self, position, Vector2(0, 12), is_hero, wading)
	var off := _lunge + Vector2(0, -_bob * 2.0)
	if rig != null and not dead and not prone and _once == "" and _draw_rig(off):
		return
	# the art faces right; a mirrored transform turns it to face left
	var pick := art_for(_anim)
	var s: Sheet = pick[0]
	var mirror := Vector2(-1 if pick[1] else 1, 1)
	if prone and not dead and name == "idle":
		# no lying-down row in this sheet: tip the standing frame over
		draw_set_transform(off + Vector2(0, 7), PI / 2.0 * facing, mirror)
	else:
		draw_set_transform(off, 0, mirror)
	var src := s.frame_rect(_anim, _anim_t)
	var at := Vector2(-s.root.x, 12 - s.root.y)
	var size := s.frame
	if wading:
		# sunk into the water: the shins and feet are under it
		var keep := s.root.y - Grounding.wade_depth(position)
		src.size.y = keep
		size.y = keep
	draw_texture_rect_region(Grounding.lit(s.texture_of(_anim)), Rect2(at, size), src, _sheet_tint())
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if wading:
		Grounding.draw_waterline(self, Vector2(0, 12), _time, Grounding.wade_depth(position))
	if dazed and not dead:
		_draw_dazed()
	if bleeding and not dead:
		var drip := fmod(_time * 1.5, 1.0)
		draw_rect(Rect2(Vector2(2, 2 + drip * 9.0), Vector2(1, 2)), Color(0.45, 0.03, 0.05, 1.0 - drip))


## Draw the body as parts on its skeleton, posed for the current animation. False if the rig doesn't do this
## animation (attacks and the like stay painted).
func _draw_rig(off: Vector2) -> bool:
	var moving := is_gliding() or _walk_linger > 0.0
	var pose := Rig.pose_for(_anim, _anim_t, moving)
	if pose.is_empty() or not rig.covers(look):
		return false
	if not _rig_pose.is_empty():
		pose = _rig_pose
	var pick := rig.pick(look)
	var tex: Texture2D = rig.sheets[pick[0]]
	var mirror := -1.0 if pick[1] else 1.0
	var face: Vector2 = Rig.DIRS[pick[0]]
	var hidden := Rig.under_water(Grounding.wade_depth(position)) if wading else []
	var lit := Grounding.lit(tex)
	for pl in Rig.placements(pose, face, Vector2(0, 12)):
		if pl.part in hidden:
			continue
		var place := Transform2D(0.0, Vector2(mirror, 1.0), 0.0, off) * Transform2D(pl.angle, pl.at)
		draw_set_transform_matrix(place)
		var pivot: Vector2 = pl.pivot
		draw_texture_rect_region(lit, Rect2(-pivot, Rig.CELL), Rect2(Vector2(pl.cell * Rig.CELL.x, 0), Rig.CELL), _sheet_tint())
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if wading:
		Grounding.draw_waterline(self, Vector2(0, 12), _time, Grounding.wade_depth(position))
	if dazed:
		_draw_dazed()
	if bleeding:
		var drip := fmod(_time * 1.5, 1.0)
		draw_rect(Rect2(Vector2(2, 2 + drip * 9.0), Vector2(1, 2)), Color(0.45, 0.03, 0.05, 1.0 - drip))
	return true


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
