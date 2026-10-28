class_name LevelView
extends Node2D
## Draws a Level. Placeholder stone, water and doors until the biome art is in.

const TILE := 32
var level: Level


func show_level(l: Level) -> void:
	level = l
	queue_redraw()


func _draw() -> void:
	if level == null:
		return
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			var t := level.get_tile(c)
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var n := _noise(x, y)
			match t:
				Level.Tile.WALL:
					if _touches_floor(c):
						draw_rect(r, Color(0.16, 0.15, 0.16).lerp(Color(0.2, 0.19, 0.2), n))
						draw_rect(Rect2(r.position.x, r.position.y + TILE - 6, TILE, 6), Color(0.1, 0.09, 0.1))
					else:
						draw_rect(r, Color(0.04, 0.04, 0.05))
				Level.Tile.FLOOR:
					draw_rect(r, Color(0.27, 0.25, 0.23).lerp(Color(0.31, 0.29, 0.26), n))
					draw_rect(r, Color(0, 0, 0, 0.18), false, 1.0)
				Level.Tile.WATER:
					draw_rect(r, Color(0.08, 0.16, 0.2).lerp(Color(0.1, 0.2, 0.25), n))
					draw_line(r.position + Vector2(6, 12 + n * 6), r.position + Vector2(18, 12 + n * 6), Color(0.4, 0.6, 0.7, 0.4), 1.0)
				Level.Tile.DOOR_CLOSED:
					draw_rect(r, Color(0.27, 0.25, 0.23))
					draw_rect(r.grow(-4), Color(0.36, 0.24, 0.14))
					draw_rect(Rect2(r.position.x + 20, r.position.y + 15, 3, 3), Color(0.8, 0.7, 0.4))
				Level.Tile.STAIRS:
					draw_rect(r, Color(0.27, 0.25, 0.23))
					for i in 4:
						draw_rect(Rect2(r.position.x + 3, r.position.y + 4 + i * 6, TILE - 6 - i * 4, 4), Color(0.12, 0.11, 0.1).lerp(Color(0.02, 0.02, 0.03), i / 3.0))
				Level.Tile.DOOR_OPEN:
					draw_rect(r, Color(0.27, 0.25, 0.23))
					draw_rect(Rect2(r.position.x + 2, r.position.y + 2, 6, TILE - 4), Color(0.3, 0.2, 0.12))


func _touches_floor(c: Vector2i) -> bool:
	for d in Level.DIRS_8:
		if level.is_walkable(c + d):
			return true
	return false


static func _noise(x: int, y: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663)
	return float(absi(h) % 1000) / 1000.0
