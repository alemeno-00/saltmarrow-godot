class_name Level
extends RefCounted
## One level's tiles and the rules for walking them.
## Pure data with no drawing, so it can be tested headless and saved as it is.

enum Tile { WALL, FLOOR, DOOR_CLOSED, DOOR_OPEN, WATER, STAIRS, GATE_OPEN, GATE_SHUT, PROP, RAIL, COVER, GRATE_SHUT, GRATE_OPEN }
## COVER: a crate or barrel. Blocks walking, not sight; a crouched Thomas right behind one is hidden (sneaking spec).
## GRATE_SHUT / GRATE_OPEN: an iron grate across a tunnel (room contents, part 4): bars you can see through.
## PROP: machinery, pillars, crates: blocks movement and sight. RAIL: a railing: blocks movement, not sight.

const DIRS_8: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

var width: int
var height: int
var tiles: PackedByteArray
var seed_value: int = 0
var rooms: Array[Rect2i] = []
## The room kit's pieces as placed: kind, layout, block, blocks, rect, mirrored, variant, depth, parent, open (door sides).
var pieces: Array = []
## Squares with a light: wall lanterns and standing braziers, from the blockouts.
var lights: Array[Vector2i] = []
var start: Vector2i = Vector2i.ZERO
var stairs: Vector2i = Vector2i(-1, -1)
## The boss room on the deepest level (empty elsewhere), and the sluice gates in its walls.
var outflow := Rect2i()
var gates: Array[Vector2i] = []
## Crates and barrels (COVER squares): square -> "crate" or "barrel".
var cover := {}
## Extra connections the generator made where doorways lined up (so the level isn't a tree).
var loops := 0
## Room contents (design/quick-specs/room-contents-2026-10-30.md, parts 3-4), placed by RoomContents.
## Caches: square -> {kind: crate / barrel / satchel, item: salve / bandage / grate_key, opened, drowned (under water
## until the valve drains it)}.
var caches := {}
var grate: Array[Vector2i] = []   # the locked grate's squares, if this level's puzzle is a grate
var grate_across := ""            # "ns" (across a north-south tunnel) or "ew"
var valve := Vector2i(-1, -1)     # the sluice valve, if this level's puzzle is a valve
var drain: Array[Vector2i] = []   # the water squares the valve drains
var drained := {}                 # squares the valve has drained (drawn as wet silt over the painting)

const OUTFLOW_SIZE := Vector2i(12, 9)
# The Outflow's fixed layout, matching design/art-briefs/outflow/outflow-blockout.png (columns and rows inside the room).
const OUTFLOW_CHANNEL_ROW := 4
const OUTFLOW_GATE_COLUMNS := [2, 9]
const OUTFLOW_LANTERN_COLUMNS := [0, 6, 11]
const OUTFLOW_ENTRANCE_ROWS := [1, 2]

var _astar := AStarGrid2D.new()


func _init(w: int = 80, h: int = 48) -> void:
	width = w
	height = h
	tiles = PackedByteArray()
	tiles.resize(w * h)
	tiles.fill(Tile.WALL)


func idx(c: Vector2i) -> int:
	return c.y * width + c.x


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func get_tile(c: Vector2i) -> int:
	return tiles[idx(c)] if in_bounds(c) else Tile.WALL


func set_tile(c: Vector2i, t: int) -> void:
	if not in_bounds(c):
		return
	tiles[idx(c)] = t
	if _astar.region.has_point(c):
		_astar.set_point_solid(c, not _passable(t))


static func _passable(t: int) -> bool:
	return t == Tile.FLOOR or t == Tile.DOOR_CLOSED or t == Tile.DOOR_OPEN or t == Tile.WATER or t == Tile.STAIRS or t == Tile.GRATE_OPEN


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and _passable(get_tile(c))


## Can something standing on `from` move one square in `dir`?
## Diagonal moves may not cut a corner: both squares beside the diagonal must be open.
func can_step(from: Vector2i, dir: Vector2i) -> bool:
	if dir == Vector2i.ZERO or abs(dir.x) > 1 or abs(dir.y) > 1:
		return false
	var to := from + dir
	if not is_walkable(to):
		return false
	if dir.x != 0 and dir.y != 0:
		if not is_walkable(from + Vector2i(dir.x, 0)) or not is_walkable(from + Vector2i(0, dir.y)):
			return false
	return true


## Walls and closed doors block sight.
func blocks_sight(c: Vector2i) -> bool:
	var t := get_tile(c)
	return t == Tile.WALL or t == Tile.DOOR_CLOSED or t == Tile.GATE_OPEN or t == Tile.GATE_SHUT or t == Tile.PROP


## Can something at `a` see `b`? A straight line between the two squares, blocked by walls and closed doors.
func line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(1, n):
		var t := float(i) / float(n)
		var c := Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)))
		if blocks_sight(c):
			return false
	return true


## A list of squares from `from` (excluded) to `to` (included), or empty if unreachable.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if from == to or not is_walkable(to) or not in_bounds(from):
		return out
	var ids := _astar.get_id_path(from, to)
	for i in range(1, ids.size()):
		out.append(ids[i])
	return out


## A path like find_path, treating the `blocked` squares as solid too (where creatures stand). The start and end
## squares are never blocked.
func find_path_avoiding(from: Vector2i, to: Vector2i, blocked: Array[Vector2i]) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for c in blocked:
		if c != from and c != to and in_bounds(c) and not _astar.is_point_solid(c):
			_astar.set_point_solid(c, true)
			changed.append(c)
	var out := find_path(from, to)
	for c in changed:
		_astar.set_point_solid(c, false)
	return out


func rebuild_paths() -> void:
	_astar.region = Rect2i(0, 0, width, height)
	_astar.cell_size = Vector2(1, 1)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in height:
		for x in width:
			var c := Vector2i(x, y)
			_astar.set_point_solid(c, not is_walkable(c))


## A Sewers level from the room kit (scripts/levels/sewer_kit.gd). Same seed, same level.
## `bottom`: the deepest level, where the exit is the Outflow instead of stairs down.
func generate(seed_in: int, bottom := false) -> void:
	seed_value = seed_in
	var rng := RandomNumberGenerator.new()
	for attempt in 20:
		rng.seed = seed_in if attempt == 0 else hash([seed_in, attempt])
		_clear()
		if SewerKit.build(self, rng, bottom):
			break
	rebuild_paths()
	RoomContents.place(self)


func _clear() -> void:
	tiles.fill(Tile.WALL)
	cover.clear()
	loops = 0
	caches.clear()
	grate.clear()
	grate_across = ""
	valve = Vector2i(-1, -1)
	drain.clear()
	drained.clear()
	rooms.clear()
	pieces.clear()
	lights.clear()
	outflow = Rect2i()
	gates.clear()
	stairs = Vector2i(-1, -1)
	start = Vector2i.ZERO


## Writes the Outflow (placed by the room kit) into the squares: its inside, its fixed layout, its west entrance.
func stamp_outflow() -> void:
	_carve(outflow)
	_make_outflow()
	for row in OUTFLOW_ENTRANCE_ROWS:
		tiles[idx(Vector2i(outflow.position.x - 1, outflow.position.y + row))] = Tile.FLOOR


func _carve(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			tiles[idx(Vector2i(x, y))] = Tile.FLOOR


## The boss room, laid out exactly as the blockout in design/art-briefs/outflow/ so the painted room lines up:
## a water channel on the fifth row inside, two sluice gates in the north wall, a two-square entrance in the west wall.
func _make_outflow() -> void:
	var o := outflow.position
	for x in range(outflow.position.x, outflow.end.x):
		tiles[idx(Vector2i(x, o.y + OUTFLOW_CHANNEL_ROW))] = Tile.WATER
	gates.clear()
	for gx in OUTFLOW_GATE_COLUMNS:
		var g := Vector2i(o.x + gx, o.y - 1)
		gates.append(g)
		tiles[idx(g)] = Tile.GATE_OPEN


## The wall squares where the painted room has its lanterns (the blockout's yellow marks).
func outflow_lanterns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if outflow.has_area():
		for lx in OUTFLOW_LANTERN_COLUMNS:
			out.append(outflow.position + Vector2i(lx, -1))
	return out


## Rising water: every floor square in `area` beside water floods, unless water already covers `cap` of the area's open squares.
## Returns the squares that flooded.
func flood_step(area: Rect2i, cap: float) -> Array[Vector2i]:
	var open := 0
	var wet := 0
	var fresh: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := Vector2i(x, y)
			var t := get_tile(c)
			if t == Tile.WATER:
				wet += 1
				open += 1
			elif t == Tile.FLOOR:
				open += 1
				for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if area.has_point(c + d) and get_tile(c + d) == Tile.WATER:
						fresh.append(c)
						break
	if open == 0 or float(wet) / open >= cap:
		return []
	for c in fresh:
		set_tile(c, Tile.WATER)
	return fresh


## Every walkable square reachable from `from` (used by tests and later by level checks).
func reachable_from(from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in DIRS_8:
			var n := c + d
			if not seen.has(n) and can_step(c, d):
				seen[n] = true
				queue.append(n)
	return seen


func to_dict() -> Dictionary:
	var ps: Array = []
	for p in pieces:
		var r: Rect2i = p.rect
		ps.append({"kind": p.kind, "layout": p.layout, "block": [p.block.x, p.block.y], "blocks": [p.blocks.x, p.blocks.y],
			"rect": [r.position.x, r.position.y, r.size.x, r.size.y], "mirrored": p.mirrored, "variant": p.variant,
			"depth": p.depth, "parent": p.parent, "open": p.open})
	return {"w": width, "h": height, "seed": seed_value, "tiles": Marshalls.raw_to_base64(tiles), "start": [start.x, start.y],
		"stairs": [stairs.x, stairs.y], "outflow": [outflow.position.x, outflow.position.y, outflow.size.x, outflow.size.y],
		"gates": gates.map(func(g): return [g.x, g.y]), "lights": lights.map(func(c): return [c.x, c.y]), "pieces": ps,
		"cover": cover.keys().map(func(c): return [c.x, c.y, cover[c]])}


static func _v(a) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


static func from_dict(d: Dictionary) -> Level:
	var l := Level.new(int(d.w), int(d.h))
	l.seed_value = int(d.seed)
	l.tiles = Marshalls.base64_to_raw(d.tiles)
	l.start = _v(d.start)
	for c in d.get("cover", []):
		l.cover[Vector2i(int(c[0]), int(c[1]))] = String(c[2])
	if d.has("stairs"):
		l.stairs = _v(d.stairs)
		l.outflow = Rect2i(int(d.outflow[0]), int(d.outflow[1]), int(d.outflow[2]), int(d.outflow[3]))
		for g in d.gates:
			l.gates.append(_v(g))
		for c in d.lights:
			l.lights.append(_v(c))
		for p in d.pieces:
			var r: Array = p.rect
			var open: Array[String] = []
			for o in p.open:
				open.append(String(o))
			l.pieces.append({"kind": String(p.kind), "layout": String(p.layout), "block": _v(p.block), "blocks": _v(p.blocks),
				"rect": Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])), "mirrored": bool(p.mirrored),
				"variant": int(p.variant), "depth": int(p.depth), "parent": int(p.parent), "open": open})
			if p.kind != "connector":
				l.rooms.append(l.outflow if p.kind == "outflow" else l.pieces[-1].rect)
	l.rebuild_paths()
	return l
