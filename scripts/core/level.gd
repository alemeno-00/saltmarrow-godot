class_name Level
extends RefCounted
## One level's tiles and the rules for walking them.
## Pure data with no drawing, so it can be tested headless and saved as it is.

enum Tile { WALL, FLOOR, DOOR_CLOSED, DOOR_OPEN, WATER }

const DIRS_8: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

var width: int
var height: int
var tiles: PackedByteArray
var seed_value: int = 0
var rooms: Array[Rect2i] = []
var start: Vector2i = Vector2i.ZERO

var _astar := AStarGrid2D.new()


func _init(w: int = 60, h: int = 40) -> void:
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
	return t == Tile.FLOOR or t == Tile.DOOR_CLOSED or t == Tile.DOOR_OPEN or t == Tile.WATER


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
	return t == Tile.WALL or t == Tile.DOOR_CLOSED


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


## Rooms joined by corridors, with doors where corridors meet rooms. Same seed, same level.
func generate(seed_in: int) -> void:
	seed_value = seed_in
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_in
	tiles.fill(Tile.WALL)
	rooms.clear()
	var tries := 0
	while rooms.size() < 12 and tries < 400:
		tries += 1
		var w := rng.randi_range(5, 11)
		var h := rng.randi_range(4, 8)
		var r := Rect2i(rng.randi_range(1, width - w - 2), rng.randi_range(1, height - h - 2), w, h)
		var clash := false
		for o in rooms:
			if r.grow(2).intersects(o):
				clash = true
				break
		if clash:
			continue
		rooms.append(r)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				tiles[idx(Vector2i(x, y))] = Tile.FLOOR
	# join each room to the next, in order of position, so everything connects
	rooms.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.get_center().x + a.get_center().y * 0.3 < b.get_center().x + b.get_center().y * 0.3)
	for i in range(1, rooms.size()):
		_corridor(rooms[i - 1].get_center(), rooms[i].get_center(), rng)
	# a few extra loops so it isn't a straight line of rooms
	for _n in 3:
		if rooms.size() > 3:
			var a := rooms[rng.randi_range(0, rooms.size() - 1)]
			var b := rooms[rng.randi_range(0, rooms.size() - 1)]
			if a != b:
				_corridor(a.get_center(), b.get_center(), rng)
	_place_doors(rng)
	# a pool of water in one room
	if rooms.size() > 2:
		var pr := rooms[rng.randi_range(1, rooms.size() - 1)]
		var pc := pr.get_center()
		for y in range(pc.y - 1, pc.y + 2):
			for x in range(pc.x - 2, pc.x + 2):
				if get_tile(Vector2i(x, y)) == Tile.FLOOR and rng.randf() < 0.8:
					tiles[idx(Vector2i(x, y))] = Tile.WATER
	start = rooms[0].get_center() if rooms.size() > 0 else Vector2i(1, 1)
	tiles[idx(start)] = Tile.FLOOR
	rebuild_paths()


func _corridor(a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> void:
	var horizontal_first := rng.randf() < 0.5
	var c := a
	var steps: Array[Vector2i] = []
	if horizontal_first:
		steps.append(Vector2i(b.x, a.y))
		steps.append(b)
	else:
		steps.append(Vector2i(a.x, b.y))
		steps.append(b)
	for target in steps:
		while c != target:
			c += Vector2i(signi(target.x - c.x), signi(target.y - c.y))
			if get_tile(c) == Tile.WALL:
				tiles[idx(c)] = Tile.FLOOR


## A door goes where a corridor passes through a room's wall line: floor on both sides along one axis, wall on the other.
func _place_doors(rng: RandomNumberGenerator) -> void:
	for r in rooms:
		var ring := r.grow(1)
		for y in range(ring.position.y, ring.end.y):
			for x in range(ring.position.x, ring.end.x):
				var c := Vector2i(x, y)
				if r.has_point(c) or get_tile(c) != Tile.FLOOR:
					continue
				var ns := get_tile(c + Vector2i.UP) == Tile.WALL and get_tile(c + Vector2i.DOWN) == Tile.WALL
				var we := get_tile(c + Vector2i.LEFT) == Tile.WALL and get_tile(c + Vector2i.RIGHT) == Tile.WALL
				if (ns or we) and rng.randf() < 0.6:
					tiles[idx(c)] = Tile.DOOR_CLOSED


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
	return {"w": width, "h": height, "seed": seed_value, "tiles": Marshalls.raw_to_base64(tiles), "start": [start.x, start.y]}


static func from_dict(d: Dictionary) -> Level:
	var l := Level.new(int(d.w), int(d.h))
	l.seed_value = int(d.seed)
	l.tiles = Marshalls.base64_to_raw(d.tiles)
	l.start = Vector2i(int(d.start[0]), int(d.start[1]))
	l.rebuild_paths()
	return l
