extends Node2D
## Drawn above the level and the creatures.
## Exploring: the square under the mouse and the route Thomas would take to it.
## Fighting: where Thomas can move, who he can hit, and the squares a big blow is about to land on.

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
	var c := game.hover_cell()
	if not game.level.in_bounds(c):
		return
	var p := game.hover_path()
	for s in p:
		draw_circle(Vector2(s.x * TILE + TILE / 2.0, s.y * TILE + TILE / 2.0), 2.0, Color(1, 0.85, 0.5, 0.5))
	var ok := not p.is_empty()
	draw_rect(_rect(c), Color(1, 0.85, 0.5, 0.65) if ok else Color(1, 0.4, 0.3, 0.35), false, 1.5)


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
	# telegraphed blows: darkened squares, pulsing
	for e in game.enemies:
		for c in e.telegraph:
			draw_rect(_rect(c), Color(0.35, 0.0, 0.02, 0.35 + 0.15 * sin(t * 7.0)))
			draw_rect(_rect(c).grow(-1), Color(0.7, 0.1, 0.08, 0.8), false, 1.5)
	if not (b.is_hero_turn() and not game.busy and not game.dead):
		return
	var amber := Color(1, 0.8, 0.45)
	if game.stepping:
		for c in b.shift_cells():
			draw_rect(_rect(c).grow(-2), Color(0.6, 0.85, 1.0, 0.18))
			draw_rect(_rect(c).grow(-2), Color(0.6, 0.85, 1.0, 0.6), false, 1.0)
	elif game.selected >= 0:
		var ab: Dictionary = game.hero_unit.abilities[game.selected]
		for e in b.valid_targets(game.hero_unit, ab):
			draw_rect(_rect(e.cell).grow(-1), amber, false, 2.0)
	else:
		for c in game.reach:
			draw_rect(_rect(c).grow(-2), Color(0.95, 0.85, 0.6, 0.06))
		for e in b.valid_targets(game.hero_unit, game.hero_unit.basic):
			draw_rect(_rect(e.cell).grow(-1), Color(amber, 0.5), false, 1.0)
	var h := game.hover_cell()
	var foe := game._enemy_at(h)
	if foe != null:
		draw_rect(_rect(h), Color(0.9, 0.3, 0.25, 0.8), false, 1.5)
	elif game.reach.has(h) and game.selected < 0 and not game.stepping:
		var route := Battle.path_to(game.battle.reachable(game.hero_unit, b.budget.move), game.hero_unit.cell, h)
		for s in route:
			draw_circle(Vector2(s.x * TILE + TILE / 2.0, s.y * TILE + TILE / 2.0), 2.0, Color(amber, 0.6))
		draw_rect(_rect(h), Color(amber, 0.7), false, 1.5)
