extends Node2D
## Drawn above the level: the square under the mouse and the route Thomas would take to it.

const TILE := 32
@onready var game: Game = get_parent()


func _draw() -> void:
	var c := game.hover_cell()
	if game.level == null or not game.level.in_bounds(c):
		return
	var p := game.hover_path()
	for s in p:
		draw_circle(Vector2(s.x * TILE + TILE / 2.0, s.y * TILE + TILE / 2.0), 2.0, Color(1, 0.85, 0.5, 0.5))
	var ok := not p.is_empty()
	draw_rect(Rect2(c.x * TILE, c.y * TILE, TILE, TILE), Color(1, 0.85, 0.5, 0.65) if ok else Color(1, 0.4, 0.3, 0.35), false, 1.5)
