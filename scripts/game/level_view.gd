class_name LevelView
extends Node2D
## Draws a Level. Placeholder stone, water and doors until the biome art is in.
## The Outflow uses ChatGPT's painted room when it exists (design/art-briefs/outflow/BRIEF.md).

const TILE := 32
const OUTFLOW_ART := "res://assets/tiles/sewers/outflow/outflow_room.png"
const OUTFLOW_DIR := "res://assets/tiles/sewers/outflow/"
const SLUICE_FRAME := 0.18   # seconds per frame of the open sluice (README: 180 ms)
const FLOOD_FRAME := 0.22    # seconds per frame of a square flooding (README: 220 ms)
var level: Level
var outflow_art: Texture2D = null   # the painted Outflow, walls included (14 x 11 squares)
var _pieces := {}                   # the Outflow's moving pieces, by file name
var _flooded_at := {}               # square -> when it flooded, to play the flooding frames once


func show_level(l: Level) -> void:
	level = l
	if outflow_art == null and ResourceLoader.exists(OUTFLOW_ART):
		outflow_art = load(OUTFLOW_ART)
	if _pieces.is_empty():
		for n in ["sluice_open", "sluice_shut", "floor_flooding"]:
			if ResourceLoader.exists(OUTFLOW_DIR + n + ".png"):
				_pieces[n] = load(OUTFLOW_DIR + n + ".png")
	_flooded_at.clear()
	queue_redraw()


## The squares the painted Outflow covers: the room and its walls.
func painted_area() -> Rect2i:
	if outflow_art == null or level == null or not level.outflow.has_area():
		return Rect2i()
	return level.outflow.grow(1)


func _draw() -> void:
	if level == null:
		return
	var painted := painted_area()
	if painted.has_area():
		draw_texture_rect(outflow_art, Rect2(Vector2(painted.position) * TILE, Vector2(painted.size) * TILE), false)
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			var t := level.get_tile(c)
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var n := _noise(x, y)
			if painted.has_point(c):
				if _over_painting(c, t):
					_draw_painted_piece(c, t, r)
				continue
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
	# the open sluices move, and newly flooded squares play their frames
	if level == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if level.gates.any(func(g): return level.get_tile(g) == Level.Tile.GATE_OPEN) or _flooded_at.values().any(func(t): return now - t < FLOOD_FRAME * 4.0):
		queue_redraw()


## ChatGPT's Outflow pieces, drawn over the painting: the sluice gates (open, looped; shut) and floor that has
## flooded (four frames once, then the last held). Falls back to the drawn stand-ins without them.
func _draw_painted_piece(c: Vector2i, t: int, r: Rect2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var piece := ""
	var frame := 0
	match t:
		Level.Tile.GATE_OPEN:
			piece = "sluice_open"
			frame = int(now / SLUICE_FRAME) % 4
		Level.Tile.GATE_SHUT:
			piece = "sluice_shut"
		Level.Tile.WATER:
			piece = "floor_flooding"
			if not _flooded_at.has(c):
				_flooded_at[c] = now
			frame = mini(3, int((now - _flooded_at[c]) / FLOOD_FRAME))
	if not _pieces.has(piece):
		_draw_stand_in(t, r)
		return
	draw_texture_rect_region(_pieces[piece], r, Rect2(frame * TILE, 0, TILE, TILE))


func _draw_stand_in(t: int, r: Rect2) -> void:
	if t == Level.Tile.WATER:
		draw_rect(r, Color(0.08, 0.16, 0.2))
	elif t == Level.Tile.GATE_SHUT:
		draw_rect(r.grow(-3), Color(0.22, 0.24, 0.25))
	else:
		draw_rect(r.grow(-4), Color(0.03, 0.05, 0.07))


## Inside the painted room, only what changes during the fight is drawn on top: the gates, and floor that has flooded.
func _over_painting(c: Vector2i, t: int) -> bool:
	if t == Level.Tile.GATE_OPEN or t == Level.Tile.GATE_SHUT:
		return true
	return t == Level.Tile.WATER and c.y != level.outflow.position.y + Level.OUTFLOW_CHANNEL_ROW


func _touches_floor(c: Vector2i) -> bool:
	for d in Level.DIRS_8:
		if level.is_walkable(c + d):
			return true
	return false


static func _noise(x: int, y: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663)
	return float(absi(h) % 1000) / 1000.0
