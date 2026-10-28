extends Node2D
## Drawn above the level and the creatures.
## Exploring: the square under the mouse and the route Thomas would take to it.
## Fighting: where Thomas can move, who he can hit, and the squares a big blow is about to land on.

const TILE := 32
@onready var game: Game = get_parent()


func _rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * TILE, c.y * TILE, TILE, TILE)


func _draw() -> void:
	if game.level == null:
		return
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
			draw_rect(_rect(c).grow(-2), Color(0.95, 0.85, 0.6, 0.13))
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
