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
				Level.Tile.GATE_OPEN:
					# a sluice mouth in the wall, water pouring through
					draw_rect(r, Color(0.16, 0.15, 0.16))
					draw_rect(r.grow(-4), Color(0.03, 0.05, 0.07))
					var flow := fmod(Time.get_ticks_msec() / 400.0, 1.0)
					for i in 3:
						var sx := r.position.x + 9 + i * 6
						draw_line(Vector2(sx, r.position.y + 4 + flow * 8), Vector2(sx, r.end.y - 2), Color(0.45, 0.65, 0.75, 0.6), 1.0)
					draw_rect(Rect2(r.position.x + 2, r.position.y + 2, TILE - 4, 3), Color(0.35, 0.33, 0.3))
				Level.Tile.GATE_SHUT:
					# an iron sluice plate, bolted
					draw_rect(r, Color(0.16, 0.15, 0.16))
					draw_rect(r.grow(-3), Color(0.22, 0.24, 0.25))
					for i in 3:
						draw_rect(Rect2(r.position.x + 5, r.position.y + 7 + i * 7, TILE - 10, 2), Color(0.12, 0.13, 0.14))
					draw_rect(Rect2(r.position.x + 4, r.position.y + 4, 2, 2), Color(0.55, 0.45, 0.3))
					draw_rect(Rect2(r.end.x - 6, r.position.y + 4, 2, 2), Color(0.55, 0.45, 0.3))


func _process(_delta: float) -> void:
	# the open sluices move
	if level != null and level.gates.any(func(g): return level.get_tile(g) == Level.Tile.GATE_OPEN):
		queue_redraw()


func _touches_floor(c: Vector2i) -> bool:
	for d in Level.DIRS_8:
		if level.is_walkable(c + d):
			return true
	return false


static func _noise(x: int, y: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663)
	return float(absi(h) % 1000) / 1000.0
