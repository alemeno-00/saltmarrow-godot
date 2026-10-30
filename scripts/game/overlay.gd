extends Node2D
## Drawn above the level and the creatures.
## Exploring: while Thomas walks a clicked route, the rest of it as a dotted line to where it ends; the view cones of
## enemies near him on the floor (as in Baldur's Gate 3), and over each one how close it is to spotting him: a
## filling ring, "?" when it is suspicious.
## Fighting (like Baldur's Gate 3): the route Thomas would walk with its cost in metres, who he can reach, who would
## get a free strike, and the band on the floor a big blow is about to land on.

const TILE := 32
const TAG_ART := "res://assets/tiles/sewers/outflow/tally_tag_floor.png"
var _tag_tex: Texture2D = null
var game: Game   # set by Game: this node is moved to an undimmed layer so fight markers stay bright


func _rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * TILE, c.y * TILE, TILE, TILE)


func _draw() -> void:
	if game.level == null:
		return
	if game.tag_cell.x >= 0:
		_draw_tag(game.tag_cell)
	if game.battle != null and not game.battle.over:
		_draw_fight()
		return
	# exploring: what nearby enemies can see, and how close they are to spotting him
	for e in game.enemies:
		if e.alive() and not e.fled and game.views[e].visible:
			var v: ActorView = game.views[e]
			if MovementRules.metres(v.position.distance_to(game.hero.position)) <= StealthRules.CONE_SHOW:
				_draw_cone(e, v)
				_draw_alert(e, v)
	# what the mouse is over that can be used: picked out, with its name (as in Baldur's Gate 3)
	var thing := game.thing_at(get_global_mouse_position())
	if not thing.is_empty():
		var at := MovementRules.centre(thing.cell)
		draw_rect(Rect2(at - Vector2(15, 15), Vector2(30, 30)), Color(1.0, 0.85, 0.5, 0.8), false, 1.0)
		draw_string(ThemeDB.fallback_font, at + Vector2(-80, -22), thing.name, HORIZONTAL_ALIGNMENT_CENTER, 160, 10, Color(1.0, 0.88, 0.6))
	# getting ready to throw a dagger: how far it reaches, and where it would land
	if game.aiming_throw:
		var reach := Game.throw_reach()
		_ring(game.hero.position, reach, Color(0.6, 0.85, 1.0, 0.5))
		var m := get_global_mouse_position()
		var ok := game.hero.position.distance_to(m) <= reach
		var line: Array[Vector2] = [m]
		_dotted_path(game.hero.position, line, Color(0.6, 0.85, 1.0, 0.7) if ok else Color(0.9, 0.3, 0.25, 0.7))
		draw_circle(m, 3.0, Color(0.6, 0.85, 1.0, 0.9) if ok else Color(0.9, 0.3, 0.25, 0.9))
	# only while he walks a clicked route, what is left of it
	if not game.path.is_empty():
		_dotted_path(game.hero.position, game.path, Color(1, 0.85, 0.5, 0.6))
		_ring(game.path[-1], 5.0, Color(1, 0.85, 0.5, 0.75))


## Garrick's brass tally tag, glinting beside his body. Drawn above the creatures so his body doesn't hide it.
func _draw_tag(c: Vector2i) -> void:
	if _tag_tex == null and ResourceLoader.exists(TAG_ART):
		_tag_tex = load(TAG_ART)
	if _tag_tex != null:
		# ChatGPT's tag, centred on the square, beside Garrick's body
		draw_texture(_tag_tex, Vector2(c.x * TILE, c.y * TILE) + Vector2(8, 6))
		return
	var p := Vector2(c.x * TILE + TILE / 2.0 + 8, c.y * TILE + TILE / 2.0 + 9)
	var glint := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
	draw_circle(p, 7.0, Color(1.0, 0.8, 0.4, 0.12 + 0.1 * glint))
	draw_line(p + Vector2(-7, -5), p + Vector2(-2, -1), Color(0.3, 0.22, 0.15), 1.0)
	draw_rect(Rect2(p + Vector2(-3, -2), Vector2(7, 5)), Color(0.72, 0.55, 0.25))
	draw_rect(Rect2(p + Vector2(-2, -1), Vector2(2, 1)), Color(1.0, 0.9, 0.6, glint))


func _draw_fight() -> void:
	var b := game.battle
	var t := Time.get_ticks_msec() / 1000.0
	var amber := Color(1, 0.8, 0.45)
	var red := Color(0.9, 0.3, 0.25)
	# big blows being raised: the band on the floor they will land on, pulsing
	for e in game.enemies:
		if not e.telegraph.is_empty():
			_draw_band(e.telegraph, t)
	if not (b.is_hero_turn() and not game.busy and not game.dead):
		return
	var h := game.hero_unit
	var mouse := get_global_mouse_position()
	var foe := b.unit_at(mouse)
	if foe != null and foe.team == h.team:
		foe = null
	if game.stepping:
		# a careful step: anywhere within 1.5 m
		_ring(h.pos, MovementRules.px(MovementRules.SHIFT), Color(0.6, 0.85, 1.0, 0.7))
		var to := h.pos + (mouse - h.pos).limit_length(MovementRules.px(MovementRules.SHIFT))
		draw_line(h.pos, to, Color(0.6, 0.85, 1.0, 0.8), 1.5)
		draw_circle(to, 3.0, Color(0.6, 0.85, 1.0, 0.9))
		return
	var ab: Dictionary = h.abilities[game.selected] if game.selected >= 0 else h.basic
	# who can be hit from here, and how far the weapon reaches
	_ring(h.pos, h.radius() + MovementRules.px(Battle.reach_of(ab) * Battle.SQ), Color(amber, 0.35 if game.selected < 0 else 0.7))
	for e in b.valid_targets(h, ab):
		_ring(e.pos, e.radius() + 2.0, Color(amber, 0.9 if game.selected >= 0 else 0.5))
	if foe != null:
		_ring(foe.pos, foe.radius() + 3.0, red)
		if not Battle.in_reach(h, foe, Battle.reach_of(ab)):
			# out of reach: show the walk up to it
			var spot := b._spot_beside(h, foe, b.budget.move)
			_draw_route(h.pos, spot, spot, amber, red)
		return
	if game.selected >= 0:
		return
	# the route to wherever the mouse is: amber as far as his movement goes, red beyond, with what it costs
	var pv := b.move_preview(mouse)
	var pts: Array[Vector2] = pv.points
	if pts.is_empty():
		return
	_draw_route(h.pos, pts, pv.reach, amber, red)
	var end: Vector2 = pts[-1]
	var label := "%.1f m" % pv.cost
	if pv.cost > b.budget.move + 0.05:
		label += "  (%.1f m left)" % b.budget.move
	draw_string(ThemeDB.fallback_font, end + Vector2(8, -6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, amber if pv.cost <= b.budget.move + 0.05 else red)
	# enemies who would get a free strike as he leaves their reach
	for e in pv.strikes:
		var c: Vector2 = e.pos + Vector2(0, -26)
		draw_string(ThemeDB.fallback_font, c + Vector2(-3, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, red)
		_ring(e.pos, e.radius() + 3.0, Color(red, 0.8))


## A route as a dotted line: the part his movement pays for in `good`, the rest in `bad`.
func _draw_route(from: Vector2, all: Array[Vector2], paid: Array[Vector2], good: Color, bad: Color) -> void:
	_dotted_path(from, paid, good)
	if all.is_empty():
		return
	var ok := not paid.is_empty() and all[-1].distance_to(paid[-1]) < 0.5
	if not ok:
		# the rest of the route, past where his movement runs out
		var start := paid[-1] if not paid.is_empty() else from
		var rest: Array[Vector2] = []
		var past := paid.is_empty()
		var at := from
		for p in all:
			if not past and _between(start, at, p):
				past = true
			if past:
				rest.append(p)
			at = p
		_dotted_path(start, rest, Color(bad, 0.75))
	draw_circle(all[-1], 2.5, Color(good if ok else bad, 0.9))


static func _between(q: Vector2, a: Vector2, b: Vector2) -> bool:
	var ab := b - a
	if ab.length() < 0.001:
		return q.distance_to(a) < 0.5
	var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return q.distance_to(a + ab * t) < 0.5


## Dots every few pixels along a line through `points`, starting at `from`.
func _dotted_path(from: Vector2, points: Array[Vector2], col: Color) -> void:
	const GAP := 6.0
	var at := from
	var carry := GAP / 2.0
	for p in points:
		var length := at.distance_to(p)
		var d := carry
		while d < length:
			draw_circle(at.lerp(p, d / length), 1.1, col)
			d += GAP
		carry = d - length
		at = p


## An enemy's view on the floor: a cone the way it faces, cut short by walls, and the small circle all round it
## where it notices anything. Pale while it is calm, amber when suspicious; none for those already after him.
func _draw_cone(e: Combatant, v: ActorView) -> void:
	if game._after_him(e):
		return
	var warm := e.state == "suspicious" or e.state == "investigating"
	var col := Color(1.0, 0.75, 0.35) if warm else Color(0.85, 0.85, 0.8)
	var eye := v.position + Vector2(0, 4)
	var reach := MovementRules.px(MovementRules.SIGHT)
	var half := deg_to_rad(StealthRules.CONE_ANGLE / 2.0)
	var pts := PackedVector2Array([eye])
	const RAYS := 18
	for i in RAYS + 1:
		var dir := v.look.rotated(-half + 2.0 * half * i / RAYS)
		var d := 0.0
		while d < reach and not game.level.blocks_sight(MovementRules.cell_of(eye + dir * (d + 4.0))):
			d += 4.0
		pts.append(eye + dir * d)
	draw_colored_polygon(pts, Color(col, 0.10 if warm else 0.06))
	draw_polyline(pts, Color(col, 0.22 if warm else 0.12), 1.0)
	_ring(v.position, MovementRules.px(StealthRules.AROUND), Color(col, 0.10))


## How close an enemy is to spotting Thomas: a ring over its head that fills, and "?" once it is suspicious.
func _draw_alert(e: Combatant, v: ActorView) -> void:
	var head := v.position + Vector2(0, -34)
	if e.alert > 0.02:
		var col := Color(1.0, 0.75, 0.35).lerp(Color(0.95, 0.25, 0.2), e.alert)
		draw_arc(head, 5.0, -PI / 2.0, -PI / 2.0 + TAU * e.alert, 24, col, 2.0)
	if e.state == "suspicious" or e.state == "investigating":
		draw_string(ThemeDB.fallback_font, head + Vector2(-3, 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.8, 0.4))


func _ring(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.6))   # flattened onto the floor
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, col, 1.5)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## A telegraphed blow's band on the floor (Battle.band), dark red and pulsing.
func _draw_band(band: Dictionary, t: float) -> void:
	var dir: Vector2 = band.dir
	draw_set_transform(band.centre, dir.angle(), Vector2.ONE)
	var r := Rect2(Vector2(-band.half_d, -band.half_w), Vector2(band.half_d * 2.0, band.half_w * 2.0))
	draw_rect(r, Color(0.35, 0.0, 0.02, 0.35 + 0.15 * sin(t * 7.0)))
	draw_rect(r.grow(-1), Color(0.7, 0.1, 0.08, 0.8), false, 1.5)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
