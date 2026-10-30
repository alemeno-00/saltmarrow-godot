class_name SewerKit
extends RefCounted
## Builds a Sewers level from the room kit (design/quick-specs/sewer-room-kit-2026-10-29.md).
##
## The map is a grid of 4 x 4-square blocks. Rooms are 2 or 3 blocks a side; connectors are one block. Starting from
## the entry, rooms are added as a tree: each new room hangs off a free door of an existing one, joined by a short
## run of connectors (straight, sometimes with one bend). The exit (stairs down, or on the deepest level the Outflow)
## goes at the end of the longest branch. Unused doors are walled off.
##
## Every door is in the middle block of its side (the later one when there are two), so a door is always in the
## block one along from a room's corner, and connectors line up with it.

const ROOMS_BY_KIND := {
	"entry": ["entry"],
	"stairs": ["stairs"],
	"lore": ["lore_a", "lore_b"],
	"junction": ["junction_a", "junction_b", "junction_c"],
	"chamber": ["chamber_a", "chamber_b", "chamber_c"],
	"flooded": ["flooded_a", "flooded_b"],
}
const CONNECTORS := ["ew", "ns", "ne", "nw", "es", "sw", "new", "nes", "esw", "nsw", "nesw", "n", "e", "s", "w"]

# Tuning knobs (spec: Tuning Knobs)
const ROOMS_MIN := 8                 # rooms per level, the exit included
const ROOMS_MAX := 12
const LORE_MAX := 1                  # lore rooms per level
const MIRROR_CHANCE := 0.5           # chance a room is drawn mirrored left to right
const BEND_CHANCE := 0.35            # chance a run of connectors turns once
const KIND_WEIGHTS := {"junction": 4, "chamber": 4, "flooded": 2, "lore": 1}
# Made for sneaking (design/quick-specs/sneaking-2026-10-30.md, "Cover, and levels built for sneaking")
const LOOPS_MAX := 3                 # extra connections where doorways line up, so a guarded room has another way round
const COVER_PER_ROOM := Vector2i(2, 4)   # crates and barrels in a room
const COVER_ROOMS := ["junction", "chamber", "flooded", "lore", "stairs"]
const APPROACH := Vector2i(2, 4)     # squares from an open doorway where a crate gives a covered way in
# Long sewage tunnels (design/quick-specs/deep-sewage-tunnels-2026-10-30.md)
const SEWAGE_CHANCE := 0.3           # chance a new room is reached by a sewage tunnel instead of an ordinary one
const SEWAGE_MAX := 2                # sewage tunnels per level
const SEWAGE_BLOCKS := Vector2i(3, 5)    # a tunnel's length in blocks (12-20 squares)
const LEDGE_CHANCE := 0.5            # chance a sewage tunnel has a narrow raised ledge along one side

const DIRS := {"n": Vector2i(0, -1), "e": Vector2i(1, 0), "s": Vector2i(0, 1), "w": Vector2i(-1, 0)}
const OPPOSITE := {"n": "s", "s": "n", "e": "w", "w": "e"}
const OUTFLOW_BLOCKS := Vector2i(4, 4)   # the Outflow's 14 x 11 squares fit in 4 x 4 blocks, entrance in the west

var level: Level
var rng: RandomNumberGenerator
var _occupied := {}   # block -> true


## Every layout in the kit: rooms, then connectors.
static func all_layouts() -> Array[String]:
	var out: Array[String] = []
	for kind in ROOMS_BY_KIND:
		for id in ROOMS_BY_KIND[kind]:
			out.append(id)
	for c in CONNECTORS:
		out.append("connector_" + c)
	return out


## Fills `l` with a level; false if this attempt couldn't fit the rooms or the exit (the caller tries another seed).
static func build(l: Level, r: RandomNumberGenerator, bottom: bool) -> bool:
	var kit := SewerKit.new()
	kit.level = l
	kit.rng = r
	return kit._build(bottom)


func _build(bottom: bool) -> bool:
	var map := Vector2i(level.width / 4, level.height / 4)
	var entry := RoomLayout.get_layout("entry")
	var eb := entry.size / 4
	# on the deepest level the entry starts in the west third, leaving room for the Outflow to the east
	var max_x := map.x / 3 if bottom else map.x - eb.x
	_add_room("entry", "entry", Vector2i(rng.randi_range(0, max_x), rng.randi_range(0, map.y - eb.y)), false, -1)
	var target := rng.randi_range(ROOMS_MIN, ROOMS_MAX) - 1
	var tries := 0
	while _room_count() < target and tries < 800:
		tries += 1
		var pi := rng.randi_range(0, level.pieces.size() - 1)
		var parent: Dictionary = level.pieces[pi]
		if parent.kind == "connector":
			continue
		var free := _free_sides(parent)
		if free.is_empty():
			continue
		var kind := _pick_kind()
		var choices: Array = ROOMS_BY_KIND[kind].filter(func(id): return id != parent.layout)
		var id: String = choices[rng.randi_range(0, choices.size() - 1)]
		_try_attach(pi, free[rng.randi_range(0, free.size() - 1)], kind, id, rng.randf() < MIRROR_CHANCE)
	if _room_count() < ROOMS_MIN - 1:
		return false
	# the exit hangs off a room at the far end of the longest branch
	var deepest := 0
	for p in level.pieces:
		if p.kind != "connector":
			deepest = maxi(deepest, p.depth)
	var ends: Array = []
	for i in level.pieces.size():
		if level.pieces[i].kind != "connector" and level.pieces[i].depth == deepest:
			ends.append(i)
	# shuffled with the level's own random numbers (Array.shuffle() would use the global ones and break same seed, same level)
	for i in range(ends.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = ends[i]
		ends[i] = ends[j]
		ends[j] = tmp
	for pi in ends:
		for side in _free_sides(level.pieces[pi]):
			var placed := _try_attach_outflow(pi, side) if bottom else _try_attach(pi, side, "stairs", "stairs", rng.randf() < MIRROR_CHANCE)
			if placed:
				_add_loops()
				_stamp()
				_place_cover()
				return true
	return false


## Join a room's free doorway, by a straight run of 1-5 connectors across empty blocks, to another room's doorway
## facing it or to a tunnel already there (which becomes a T or a crossroads), up to LOOPS_MAX times, so the level
## isn't a tree: a guarded room can be got round.
func _add_loops() -> void:
	var tries: Array = []
	for i in level.pieces.size():
		var p: Dictionary = level.pieces[i]
		if p.kind == "connector" or p.kind == "outflow":
			continue
		for s in _free_sides(p):
			tries.append([i, s])
	for i in range(tries.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = tries[i]
		tries[i] = tries[j]
		tries[j] = tmp
	var made := 0
	for t in tries:
		if made >= LOOPS_MAX:
			return
		var pi: int = t[0]
		var side: String = t[1]
		if not _free_sides(level.pieces[pi]).has(side):
			continue
		var start := _door_block(level.pieces[pi], side)
		var d: Vector2i = DIRS[side]
		for length in range(1, 6):
			var blocks: Array[Vector2i] = []
			for k in length:
				blocks.append(start + d * k)
			if not _free(blocks):
				break
			var qi := _room_with_door_at(blocks[-1], OPPOSITE[side], pi)
			if qi >= 0:
				_add_run(pi, side, {"blocks": blocks, "dir": side})
				level.pieces[qi].open.append(OPPOSITE[side])
				made += 1
				level.loops += 1
				break
			var ci := _connector_at(blocks[-1] + d)
			if ci >= 0 and level.pieces[ci].parent != pi and not (level.pieces[ci].open as Array).has(OPPOSITE[side]):
				_add_run(pi, side, {"blocks": blocks, "dir": side})
				var c: Dictionary = level.pieces[ci]
				c.open.append(OPPOSITE[side])
				var name := ""
				for o in ["n", "e", "s", "w"]:
					if (c.open as Array).has(o):
						name += o
				c.layout = "connector_" + name
				made += 1
				level.loops += 1
				break


## The ordinary connector piece on block `b`, or -1 (a sewage tunnel doesn't branch).
func _connector_at(b: Vector2i) -> int:
	for i in level.pieces.size():
		if level.pieces[i].kind == "connector" and level.pieces[i].block == b and not String(level.pieces[i].layout).begins_with("sewage"):
			return i
	return -1


## The room (other than `not_this`) whose free doorway on `side` opens onto block `b`, or -1.
func _room_with_door_at(b: Vector2i, side: String, not_this: int) -> int:
	for i in level.pieces.size():
		var q: Dictionary = level.pieces[i]
		if i == not_this or q.kind == "connector" or q.kind == "outflow":
			continue
		if _free_sides(q).has(side) and _door_block(q, side) == b:
			return i
	return -1


## Crates and barrels in the rooms, for hiding behind: one a few squares in from each open doorway where it can go
## (a covered way in), the rest against the walls. Doorways stay clear, and every walkable square stays reachable.
func _place_cover() -> void:
	var walkable := 0
	for i in level.tiles.size():
		if Level._passable(level.tiles[i]):
			walkable += 1
	for p in level.pieces:
		if not p.kind in COVER_ROOMS:
			continue
		var r: Rect2i = p.rect
		var doors: Array[Vector2i] = []
		var floor: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				if level.get_tile(c) != Level.Tile.FLOOR:
					continue
				if not r.grow(-1).has_point(c) or (y == r.position.y + 1 and level.get_tile(Vector2i(x, r.position.y)) == Level.Tile.FLOOR):
					doors.append(c)   # floor on a room's edge is an open doorway (a north one runs two squares deep)
				else:
					floor.append(c)
		var spots: Array[Vector2i] = []
		var middle: Vector2i = r.get_center()
		for c in floor:
			# doorways stay clear, and so does the middle of the room, where a band waits and a patrol aims
			if _dist_to(c, doors) >= 2 and maxi(absi(c.x - middle.x), absi(c.y - middle.y)) > 2:
				spots.append(c)
		var want := rng.randi_range(COVER_PER_ROOM.x, COVER_PER_ROOM.y)
		var placed := 0
		# first a covered way in for each doorway, then against the walls
		var near_doors := spots.filter(func(c): var d := _dist_to(c, doors); return d >= APPROACH.x and d <= APPROACH.y)
		var by_walls := spots.filter(func(c): return _beside_wall(c))
		for pool in [near_doors, by_walls]:
			while placed < want and not pool.is_empty():
				var c: Vector2i = pool.pop_at(rng.randi_range(0, pool.size() - 1))
				if level.get_tile(c) != Level.Tile.FLOOR or _next_to_cover(c):
					continue
				level.tiles[level.idx(c)] = Level.Tile.COVER
				if _count_reachable() < walkable - 1:
					level.tiles[level.idx(c)] = Level.Tile.FLOOR   # it would cut the level in two
					continue
				walkable -= 1
				level.cover[c] = "crate" if rng.randf() < 0.5 else "barrel"
				placed += 1
				if pool == near_doors and placed >= doors.size() / 2:
					break


static func _dist_to(c: Vector2i, cells: Array[Vector2i]) -> int:
	var best := 999
	for d in cells:
		best = mini(best, maxi(absi(c.x - d.x), absi(c.y - d.y)))
	return best


func _beside_wall(c: Vector2i) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var t := level.get_tile(c + d)
		if t == Level.Tile.WALL or t == Level.Tile.PROP:
			return true
	return false


func _next_to_cover(c: Vector2i) -> bool:
	for y in range(-1, 2):
		for x in range(-1, 2):
			if level.get_tile(c + Vector2i(x, y)) == Level.Tile.COVER:
				return true
	return false


## Walkable squares reachable from the start (a flood fill over the squares; the paths aren't built yet).
func _count_reachable() -> int:
	var seen := {level.start: true}
	var stack: Array[Vector2i] = [level.start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not seen.has(n) and level.in_bounds(n) and Level._passable(level.get_tile(n)):
				seen[n] = true
				stack.append(n)
	return seen.size()


func _room_count() -> int:
	return level.pieces.filter(func(p): return p.kind != "connector").size()


func _pick_kind() -> String:
	var lore := level.pieces.filter(func(p): return p.kind == "lore").size()
	var total := 0
	for k in KIND_WEIGHTS:
		if k != "lore" or lore < LORE_MAX:
			total += KIND_WEIGHTS[k]
	var roll := rng.randi_range(1, total)
	for k in KIND_WEIGHTS:
		if k == "lore" and lore >= LORE_MAX:
			continue
		roll -= KIND_WEIGHTS[k]
		if roll <= 0:
			return k
	return "junction"


func _free_sides(p: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if p.kind == "outflow" or p.kind == "connector":
		return out
	for s in RoomLayout.get_layout(p.layout).sides(p.mirrored):
		if not (p.open as Array).has(s):
			out.append(s)
	return out


## Only rooms 12 squares wide can be mirrored: their north and south doors (squares 5-6) land on squares 5-6 again.
## In an 8-wide room they would move to squares 1-2 and miss their connectors.
static func can_mirror(lay: RoomLayout) -> bool:
	return lay.size.x == 12


## The block just outside a room's door on `side`: one block along from the corner.
func _door_block(p: Dictionary, side: String) -> Vector2i:
	var b: Vector2i = p.block
	var s: Vector2i = p.blocks
	match side:
		"n":
			return Vector2i(b.x + 1, b.y - 1)
		"s":
			return Vector2i(b.x + 1, b.y + s.y)
		"w":
			return Vector2i(b.x - 1, b.y + 1)
	return Vector2i(b.x + s.x, b.y + 1)


## Where a room of `bs` blocks goes so that its door on `entry_side` meets the connector block `e`.
static func _room_pos(e: Vector2i, entry_side: String, bs: Vector2i) -> Vector2i:
	match entry_side:
		"w":
			return Vector2i(e.x + 1, e.y - 1)
		"e":
			return Vector2i(e.x - bs.x, e.y - 1)
		"n":
			return Vector2i(e.x - 1, e.y + 1)
	return Vector2i(e.x - 1, e.y - bs.y)


## A run of connector blocks out of a door: 1-3 straight, sometimes turning once for 1-2 more. Now and then a long
## straight sewage tunnel instead (3-5 blocks, waist-deep, sometimes with a ledge).
func _run(start: Vector2i, side: String) -> Dictionary:
	if level.sewage.size() < SEWAGE_MAX and rng.randf() < SEWAGE_CHANCE:
		var blocks: Array[Vector2i] = []
		for i in rng.randi_range(SEWAGE_BLOCKS.x, SEWAGE_BLOCKS.y):
			blocks.append(start + DIRS[side] * i)
		var ledge := ""
		if rng.randf() < LEDGE_CHANCE:
			var sides: Array = ["w", "e"] if side == "n" or side == "s" else ["n", "s"]
			ledge = sides[rng.randi_range(0, 1)]
		return {"blocks": blocks, "dir": side, "sewage": true, "ledge": ledge}
	var blocks: Array[Vector2i] = []
	var d: Vector2i = DIRS[side]
	var at := start
	for _i in rng.randi_range(1, 3):
		blocks.append(at)
		at += d
	var last := side
	if rng.randf() < BEND_CHANCE:
		var turns: Array = ["e", "w"] if side == "n" or side == "s" else ["n", "s"]
		last = turns[rng.randi_range(0, 1)]
		at = blocks[blocks.size() - 1] + DIRS[last]
		for _i in rng.randi_range(1, 2):
			blocks.append(at)
			at += DIRS[last]
	return {"blocks": blocks, "dir": last, "sewage": false}


func _free(blocks: Array) -> bool:
	for b in blocks:
		if b.x < 0 or b.y < 0 or b.x >= level.width / 4 or b.y >= level.height / 4 or _occupied.has(b):
			return false
	return true


func _area(pos: Vector2i, bs: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in bs.y:
		for x in bs.x:
			out.append(pos + Vector2i(x, y))
	return out


func _try_attach(pi: int, side: String, kind: String, id: String, mirrored: bool) -> bool:
	var lay := RoomLayout.get_layout(id)
	var bs := lay.size / 4
	mirrored = mirrored and can_mirror(lay)
	var start := _door_block(level.pieces[pi], side)
	for _attempt in 8:
		var run := _run(start, side)
		var entry_side: String = OPPOSITE[run.dir]
		if not lay.sides(mirrored).has(entry_side):
			continue
		var pos := _room_pos(run.blocks[run.blocks.size() - 1], entry_side, bs)
		if not _free(run.blocks) or not _free(_area(pos, bs)):
			continue
		_add_run(pi, side, run)
		var ri := _add_room(kind, id, pos, mirrored, pi)
		level.pieces[ri].open.append(entry_side)
		return true
	return false


func _try_attach_outflow(pi: int, side: String) -> bool:
	var start := _door_block(level.pieces[pi], side)
	for _attempt in 24:
		var run := _run(start, side)
		if run.dir != "e":
			continue
		var pos := _room_pos(run.blocks[run.blocks.size() - 1], "w", OUTFLOW_BLOCKS)
		if not _free(run.blocks) or not _free(_area(pos, OUTFLOW_BLOCKS)):
			continue
		_add_run(pi, side, run)
		# the Outflow's walls start at the block's left edge; its inside starts 4 squares down, so the west
		# entrance (inside rows 1-2) lines up with the connector's door (block rows 1-2)
		level.outflow = Rect2i(pos * 4 + Vector2i(1, 4), Level.OUTFLOW_SIZE)
		for b in _area(pos, OUTFLOW_BLOCKS):
			_occupied[b] = true
		level.pieces.append({"kind": "outflow", "layout": "outflow", "block": pos, "blocks": OUTFLOW_BLOCKS,
			"rect": level.outflow.grow(1), "mirrored": false, "variant": 0, "depth": level.pieces[pi].depth + 1,
			"parent": pi, "open": ["w"]})
		return true
	return false


func _add_room(kind: String, id: String, pos: Vector2i, mirrored: bool, parent: int) -> int:
	var lay := RoomLayout.get_layout(id)
	var bs := lay.size / 4
	for b in _area(pos, bs):
		_occupied[b] = true
	level.pieces.append({"kind": kind, "layout": id, "block": pos, "blocks": bs, "rect": Rect2i(pos * 4, lay.size),
		"mirrored": mirrored and can_mirror(lay), "variant": rng.randi_range(0, 999),
		"depth": 0 if parent < 0 else level.pieces[parent].depth + 1, "parent": parent, "open": []})
	return level.pieces.size() - 1


## The connectors between a room's door and the next room: each block gets doors toward its neighbours.
func _add_run(pi: int, side: String, run: Dictionary) -> void:
	level.pieces[pi].open.append(side)
	var blocks: Array = run.blocks
	if run.get("sewage", false):
		var axis := "ns" if side == "n" or side == "s" else "ew"
		var lay := "sewage_" + axis + ("_" + String(run.ledge) if run.ledge != "" else "")
		var area := Rect2i(blocks[0] * 4, Vector2i(4, 4))
		for b in blocks:
			_occupied[b] = true
			area = area.merge(Rect2i(b * 4, Vector2i(4, 4)))
			var sides: Array = [axis.left(1), axis.right(1)]
			level.pieces.append({"kind": "connector", "layout": lay, "block": b, "blocks": Vector2i.ONE,
				"rect": Rect2i(b * 4, Vector2i(4, 4)), "mirrored": false, "variant": rng.randi_range(0, 999),
				"depth": level.pieces[pi].depth, "parent": pi, "open": sides})
		level.sewage.append(area)
		return
	for i in blocks.size():
		var b: Vector2i = blocks[i]
		var sides := {}
		sides[OPPOSITE[side] if i == 0 else _side_toward(b, blocks[i - 1])] = true
		sides[run.dir if i == blocks.size() - 1 else _side_toward(b, blocks[i + 1])] = true
		var name := ""
		for s in ["n", "e", "s", "w"]:
			if sides.has(s):
				name += s
		_occupied[b] = true
		level.pieces.append({"kind": "connector", "layout": "connector_" + name, "block": b, "blocks": Vector2i.ONE,
			"rect": Rect2i(b * 4, Vector2i(4, 4)), "mirrored": false, "variant": rng.randi_range(0, 999),
			"depth": level.pieces[pi].depth, "parent": pi, "open": sides.keys()})


static func _side_toward(from: Vector2i, to: Vector2i) -> String:
	var d := to - from
	for s in DIRS:
		if DIRS[s] == d:
			return s
	return "n"


const TILE_OF := {
	"#": Level.Tile.WALL, "F": Level.Tile.WALL, "L": Level.Tile.WALL, ".": Level.Tile.FLOOR, ",": Level.Tile.FLOOR,
	"D": Level.Tile.FLOOR, "~": Level.Tile.WATER, "P": Level.Tile.PROP, "B": Level.Tile.PROP, "X": Level.Tile.PROP,
	"r": Level.Tile.RAIL, "S": Level.Tile.STAIRS, "w": Level.Tile.DEEP, "d": Level.Tile.DEEP,
}


## Writes every piece into the level's squares: rooms as their blockouts say (mirrored if chosen, unused doors walled
## off), connectors likewise, and the Outflow by its own rules.
func _stamp() -> void:
	for p in level.pieces:
		if p.kind == "outflow":
			level.stamp_outflow()
			continue
		var lay := RoomLayout.get_layout(p.layout)
		var r: Rect2i = p.rect
		for y in r.size.y:
			for x in r.size.x:
				var src := Vector2i(r.size.x - 1 - x if p.mirrored else x, y)
				var code := lay.cell(src)
				if code == "D" or code == "d":
					var s := lay.door_side(src)
					if p.mirrored:
						s = {"w": "e", "e": "w"}.get(s, s)
					if not (p.open as Array).has(s):
						code = "F" if s == "n" else "#"
				var c := r.position + Vector2i(x, y)
				level.tiles[level.idx(c)] = TILE_OF[code]
				if code == "L" or code == "B":
					level.lights.append(c)
				elif code == "S":
					level.stairs = c
		if p.kind == "entry":
			level.start = r.position + lay.size / 2
	for p in level.pieces:
		if p.kind != "connector":
			level.rooms.append(level.outflow if p.kind == "outflow" else p.rect)
