class_name LevelView
extends Node2D
## Draws a Level: ChatGPT's painted rooms where they exist (the Outflow; room-kit layouts in assets/tiles/sewers/rooms/),
## stand-in stone, water and props everywhere else.
##
## The level is drawn in chunks of CHUNK x CHUNK squares, each its own canvas item: the web renderer lights one item
## with at most 15 lights (Lighting.MAX_LIGHTS_PER_ITEM), and a whole level has many more lanterns than that.

const TILE := 32
const CHUNK := 8
const OUTFLOW_ART := "res://assets/tiles/sewers/outflow/outflow_room.png"
const OUTFLOW_DIR := "res://assets/tiles/sewers/outflow/"
const SLUICE_FRAME := 0.18   # seconds per frame of the open sluice (README: 180 ms)
const FLOOD_FRAME := 0.22    # seconds per frame of a square flooding (README: 220 ms)
const ROOMS_ART := "res://assets/tiles/sewers/rooms/"   # <layout>/1.png, 2.png ... (design/art-briefs/README.md)
const SEALED_ART := "res://assets/tiles/sewers/rooms/sealed/"   # north/south/west/east.png (sewer-rooms/BRIEF.md)

var level: Level
var outflow_art: Texture2D = null   # the painted Outflow, walls included (14 x 11 squares)
var _pieces := {}                   # the Outflow's moving pieces, by file name
var _flooded_at := {}               # square -> when it flooded, to play the flooding frames once
var _painted: Array = []            # [piece, Texture2D] for room-kit pieces that have a painting
var _sealed := {}                   # side -> sealed-doorway piece
var _chunks: Array[Chunk] = []
static var _room_art := {}          # layout -> Array of its paintings


## One CHUNK x CHUNK patch of the level, drawn as its own item so only nearby lights reach it. Its water squares
## get a shimmering layer on top (canvas_env_water.gdshader), also per chunk for the same reason.
class Chunk extends Node2D:
	var view: LevelView
	var region: Rect2i
	var water: WaterLayer = null
	func _draw() -> void:
		view._draw_region(self, region)
		# water can change during a fight (the Outflow floods): update the shimmer after drawing, not during it
		var have: Array[Vector2i] = []
		if water != null:
			have = water.squares
		if water_squares() != have:
			refresh_water.call_deferred()
	## Give this chunk's water squares their shimmering layer (or remove it when there's no water).
	func refresh_water() -> void:
		var squares := water_squares()
		if squares.is_empty():
			if water != null:
				water.queue_free()
				water = null
			return
		if water == null:
			water = WaterLayer.new()
			water.material = LevelView.water_material()
			add_child(water)
		water.squares = squares
		water.queue_redraw()
	func water_squares() -> Array[Vector2i]:
		var out: Array[Vector2i] = []
		for y in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				if view.level.get_tile(Vector2i(x, y)) == Level.Tile.WATER:
					out.append(Vector2i(x, y))
		return out


## The shimmer over a chunk's water squares: plain white squares that the water shader turns into moving light.
class WaterLayer extends Node2D:
	var squares: Array[Vector2i] = []
	func _draw() -> void:
		for c in squares:
			draw_rect(Rect2(Vector2(c) * LevelView.TILE, Vector2(LevelView.TILE, LevelView.TILE)), Color.WHITE)


static var _water_mat: ShaderMaterial = null


static func water_material() -> ShaderMaterial:
	if _water_mat == null:
		_water_mat = ShaderMaterial.new()
		_water_mat.shader = load("res://scripts/game/canvas_env_water.gdshader")
	return _water_mat


func chunks() -> Array[Chunk]:
	return _chunks


func show_level(l: Level) -> void:
	level = l
	if outflow_art == null and ResourceLoader.exists(OUTFLOW_ART):
		outflow_art = load(OUTFLOW_ART)
	if _pieces.is_empty():
		for n in ["sluice_open", "sluice_shut", "floor_flooding"]:
			if ResourceLoader.exists(OUTFLOW_DIR + n + ".png"):
				_pieces[n] = load(OUTFLOW_DIR + n + ".png")
	if _sealed.is_empty():
		for side in ["north", "south", "west", "east"]:
			if ResourceLoader.exists(SEALED_ART + side + ".png"):
				_sealed[side.left(1)] = load(SEALED_ART + side + ".png")
	_flooded_at.clear()
	_painted.clear()
	for p in level.pieces:
		if p.kind == "outflow":
			continue
		var art := _paintings(p.layout)
		if not art.is_empty():
			_painted.append([p, art[int(p.variant) % art.size()]])
	_make_chunks()
	queue_redraw()


func _make_chunks() -> void:
	for ch in _chunks:
		ch.queue_free()
	_chunks.clear()
	for cy in range(0, level.height, CHUNK):
		for cx in range(0, level.width, CHUNK):
			var ch := Chunk.new()
			ch.view = self
			ch.region = Rect2i(cx, cy, CHUNK, CHUNK).intersection(Rect2i(0, 0, level.width, level.height))
			add_child(ch)
			_chunks.append(ch)
			ch.refresh_water()


## Redrawing the view redraws its chunks (callers keep using queue_redraw()).
func _draw() -> void:
	for ch in _chunks:
		ch.queue_redraw()


## How many lights reach each chunk, for a level's light points ([pixel position, ...]) and light radius in pixels.
static func chunk_light_counts(l: Level, points: Array, radius: float) -> Array[int]:
	var out: Array[int] = []
	for cy in range(0, l.height, CHUNK):
		for cx in range(0, l.width, CHUNK):
			var r := Rect2(Vector2(cx, cy) * TILE, Vector2(CHUNK, CHUNK) * TILE)
			var n := 0
			for p in points:
				var at: Vector2 = p[0]
				var nearest := Vector2(clampf(at.x, r.position.x, r.end.x), clampf(at.y, r.position.y, r.end.y))
				if nearest.distance_to(at) < radius:
					n += 1
			out.append(n)
	return out


## A layout's paintings, if ChatGPT has delivered any: rooms/<layout>/1.png, 2.png and so on.
static func _paintings(layout: String) -> Array:
	if not _room_art.has(layout):
		var found: Array = []
		for i in range(1, 10):
			var path := "%s%s/%d.png" % [ROOMS_ART, layout, i]
			if not ResourceLoader.exists(path):
				break
			found.append(load(path))
		_room_art[layout] = found
	return _room_art[layout]


## The squares of a room's unused doorways, as [side, Rect2i]: painted rooms are painted with every doorway open,
## and these get a sealed piece laid over them.
static func sealed_doorways(p: Dictionary) -> Array:
	var out: Array = []
	var lay := RoomLayout.get_layout(p.layout)
	var r: Rect2i = p.rect
	for side in lay.sides(p.mirrored):
		if (p.open as Array).has(side):
			continue
		match side:
			"n":
				out.append(["n", Rect2i(r.position + Vector2i(5, 0), Vector2i(2, 2))])
			"s":
				out.append(["s", Rect2i(r.position + Vector2i(5, r.size.y - 1), Vector2i(2, 1))])
			"w":
				out.append(["w", Rect2i(r.position + Vector2i(0, 5), Vector2i(1, 2))])
			"e":
				out.append(["e", Rect2i(r.position + Vector2i(r.size.x - 1, 5), Vector2i(1, 2))])
	return out


func _in_painted_room(c: Vector2i) -> bool:
	for pr in _painted:
		if (pr[0].rect as Rect2i).has_point(c):
			return true
	return false


## The squares the painted Outflow covers: the room and its walls.
func painted_area() -> Rect2i:
	if outflow_art == null or level == null or not level.outflow.has_area():
		return Rect2i()
	return level.outflow.grow(1)


## Draw the part of a painting (covering `area` squares) that falls inside `region`, mirrored if asked.
static func _draw_clipped(canvas: CanvasItem, tex: Texture2D, area: Rect2i, region: Rect2i, mirrored: bool) -> void:
	var part := area.intersection(region)
	if not part.has_area():
		return
	var src_x := part.position.x - area.position.x
	if mirrored:
		src_x = area.size.x - src_x - part.size.x
	var src := Rect2(Vector2(src_x, part.position.y - area.position.y) * TILE, Vector2(part.size) * TILE)
	var dest := Rect2(Vector2(part.position) * TILE, Vector2(part.size) * TILE)
	if mirrored:
		canvas.draw_set_transform(Vector2(dest.position.x + dest.size.x, 0), 0, Vector2(-1, 1))
		canvas.draw_texture_rect_region(tex, Rect2(Vector2(0, dest.position.y), dest.size), src)
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		canvas.draw_texture_rect_region(tex, dest, src)


func _draw_region(canvas: CanvasItem, region: Rect2i) -> void:
	if level == null:
		return
	var painted := painted_area()
	if painted.has_area():
		_draw_clipped(canvas, outflow_art, painted, region, false)
	for pr in _painted:
		var p: Dictionary = pr[0]
		_draw_clipped(canvas, pr[1], p.rect, region, p.mirrored)
		for sd in sealed_doorways(p):
			var spot: Rect2i = sd[1]
			if not spot.intersects(region):
				continue
			if _sealed.has(sd[0]):
				_draw_clipped(canvas, _sealed[sd[0]], spot, region, false)
			else:
				var r := Rect2(Vector2(spot.position) * TILE, Vector2(spot.size) * TILE)
				canvas.draw_rect(r, Color(0.16, 0.15, 0.16))
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var c := Vector2i(x, y)
			var t := level.get_tile(c)
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var n := _noise(x, y)
			if painted.has_point(c):
				if _over_painting(c, t):
					_draw_painted_piece(canvas, c, t, r)
				continue
			if not _painted.is_empty() and _in_painted_room(c):
				continue
			match t:
				Level.Tile.PROP:
					# stand-in: a solid block (machinery, a pillar, crates)
					canvas.draw_rect(r, Color(0.27, 0.25, 0.23))
					canvas.draw_rect(r.grow(-3), Color(0.24, 0.17, 0.11))
					canvas.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(TILE - 6, 4)), Color(0.33, 0.24, 0.15))
				Level.Tile.RAIL:
					# stand-in: floor with a low iron railing across it
					canvas.draw_rect(r, Color(0.27, 0.25, 0.23).lerp(Color(0.31, 0.29, 0.26), n))
					canvas.draw_rect(Rect2(r.position + Vector2(0, 13), Vector2(TILE, 3)), Color(0.18, 0.18, 0.2))
					for px in [4, 15, 26]:
						canvas.draw_rect(Rect2(r.position + Vector2(px, 10), Vector2(2, 12)), Color(0.15, 0.15, 0.17))
				Level.Tile.WALL:
					if _touches_floor(c):
						canvas.draw_rect(r, Color(0.16, 0.15, 0.16).lerp(Color(0.2, 0.19, 0.2), n))
						canvas.draw_rect(Rect2(r.position.x, r.position.y + TILE - 6, TILE, 6), Color(0.1, 0.09, 0.1))
					else:
						canvas.draw_rect(r, Color(0.04, 0.04, 0.05))
				Level.Tile.FLOOR, Level.Tile.COVER:
					canvas.draw_rect(r, Color(0.27, 0.25, 0.23).lerp(Color(0.31, 0.29, 0.26), n))
					canvas.draw_rect(r, Color(0, 0, 0, 0.18), false, 1.0)
				Level.Tile.WATER:
					canvas.draw_rect(r, Color(0.08, 0.16, 0.2).lerp(Color(0.1, 0.2, 0.25), n))
					canvas.draw_line(r.position + Vector2(6, 12 + n * 6), r.position + Vector2(18, 12 + n * 6), Color(0.4, 0.6, 0.7, 0.4), 1.0)
				Level.Tile.DOOR_CLOSED:
					canvas.draw_rect(r, Color(0.27, 0.25, 0.23))
					canvas.draw_rect(r.grow(-4), Color(0.36, 0.24, 0.14))
					canvas.draw_rect(Rect2(r.position.x + 20, r.position.y + 15, 3, 3), Color(0.8, 0.7, 0.4))
				Level.Tile.STAIRS:
					canvas.draw_rect(r, Color(0.27, 0.25, 0.23))
					for i in 4:
						canvas.draw_rect(Rect2(r.position.x + 3, r.position.y + 4 + i * 6, TILE - 6 - i * 4, 4), Color(0.12, 0.11, 0.1).lerp(Color(0.02, 0.02, 0.03), i / 3.0))
				Level.Tile.DOOR_OPEN:
					canvas.draw_rect(r, Color(0.27, 0.25, 0.23))
					canvas.draw_rect(Rect2(r.position.x + 2, r.position.y + 2, 6, TILE - 4), Color(0.3, 0.2, 0.12))
				Level.Tile.GATE_OPEN, Level.Tile.GATE_SHUT:
					_draw_stand_in(canvas, t, r)
	for c in level.lights:
		if not region.has_point(c) or _in_painted_room(c):
			continue
		var r := Rect2(c.x * TILE, c.y * TILE, TILE, TILE)
		if level.get_tile(c) == Level.Tile.PROP:
			# stand-in brazier on its stand
			canvas.draw_rect(Rect2(r.position + Vector2(13, 14), Vector2(6, 12)), Color(0.15, 0.13, 0.12))
			canvas.draw_rect(Rect2(r.position + Vector2(9, 9), Vector2(14, 6)), Color(0.2, 0.17, 0.14))
			canvas.draw_rect(Rect2(r.position + Vector2(11, 5), Vector2(10, 5)), Color(1.0, 0.62, 0.25))
		else:
			# stand-in wall lantern
			canvas.draw_rect(Rect2(r.position + Vector2(12, 8), Vector2(8, 10)), Color(0.16, 0.14, 0.13))
			canvas.draw_rect(Rect2(r.position + Vector2(13, 9), Vector2(6, 7)), Color(1.0, 0.72, 0.3))


func _process(_delta: float) -> void:
	# the open sluices move, and newly flooded squares play their frames
	if level == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if level.gates.any(func(g): return level.get_tile(g) == Level.Tile.GATE_OPEN) or _flooded_at.values().any(func(t): return now - t < FLOOD_FRAME * 4.0):
		var area := level.outflow.grow(1)
		for ch in _chunks:
			if ch.region.intersects(area):
				ch.queue_redraw()


## ChatGPT's Outflow pieces, drawn over the painting: the sluice gates (open, looped; shut) and floor that has
## flooded (four frames once, then the last held). Falls back to the drawn stand-ins without them.
func _draw_painted_piece(canvas: CanvasItem, c: Vector2i, t: int, r: Rect2) -> void:
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
		_draw_stand_in(canvas, t, r)
		return
	canvas.draw_texture_rect_region(_pieces[piece], r, Rect2(frame * TILE, 0, TILE, TILE))


func _draw_stand_in(canvas: CanvasItem, t: int, r: Rect2) -> void:
	if t == Level.Tile.WATER:
		canvas.draw_rect(r, Color(0.08, 0.16, 0.2))
	elif t == Level.Tile.GATE_SHUT:
		canvas.draw_rect(r, Color(0.16, 0.15, 0.16))
		canvas.draw_rect(r.grow(-3), Color(0.22, 0.24, 0.25))
	else:
		canvas.draw_rect(r, Color(0.16, 0.15, 0.16))
		canvas.draw_rect(r.grow(-4), Color(0.03, 0.05, 0.07))


## Inside the painted room, only what changes during the fight is drawn on top: the gates, and floor that has flooded.
func _over_painting(c: Vector2i, t: int) -> bool:
	if t == Level.Tile.GATE_OPEN or t == Level.Tile.GATE_SHUT:
		return true
	return t == Level.Tile.WATER and c.y != level.outflow.position.y + Level.OUTFLOW_CHANNEL_ROW


func _touches_floor(c: Vector2i) -> bool:
	for d in Level.DIRS_8:
		if level.is_walkable(c + d):
			return true
	# the upper half of a two-square-thick north wall: floor two squares below
	return level.is_walkable(c + Vector2i(0, 2)) or level.get_tile(c + Vector2i(0, 2)) == Level.Tile.PROP


static func _noise(x: int, y: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663)
	return float(absi(h) % 1000) / 1000.0
