class_name RoomContents
extends RefCounted
## What the rooms hold besides enemies (design/quick-specs/room-contents-2026-10-30.md, parts 3 and 4): caches to
## search and one puzzle per level. Placed from the level's seed, after the rooms, their cover and their paths.
##
## - **Caches**: 2-3 of the crates and barrels already standing as cover hold a salve or a bandage.
## - **One puzzle**, picked at random:
##   - **a locked grate** across a tunnel that leads only to a quiet side room (never the way to the exit), with a
##     cache behind it and the grate key in a cache elsewhere;
##   - **a sluice valve** in one room that drains a flooded room elsewhere, revealing a satchel in its basin.

const CACHES := Vector2i(2, 3)          # ordinary caches per level
const CACHE_ROOMS := ["junction", "chamber", "stairs", "lore", "flooded"]
const ITEMS := ["salve", "bandage"]

var level: Level
var rng := RandomNumberGenerator.new()


static func place(l: Level) -> void:
	var rc := RoomContents.new()
	rc.level = l
	rc.rng.seed = hash([l.seed_value, "contents"])
	rc._place()


func _place() -> void:
	var puzzle := "grate" if rng.randf() < 0.5 else "valve"
	var placed := _grate() if puzzle == "grate" else _valve()
	if not placed:
		placed = _valve() if puzzle == "grate" else _grate()
	var reachable := level.reachable_from(level.start)
	var free: Array[Vector2i] = []
	for c in level.cover:
		if not level.caches.has(c) and _room_kind(c) in CACHE_ROOMS and _beside_reachable(c, reachable):
			free.append(c)
	free.sort()
	for _i in rng.randi_range(CACHES.x, CACHES.y):
		if free.is_empty():
			break
		var c: Vector2i = free.pop_at(rng.randi_range(0, free.size() - 1))
		level.caches[c] = {"kind": level.cover[c], "item": ITEMS[rng.randi_range(0, ITEMS.size() - 1)], "opened": false}


## The kind of room a square is in ("" outside rooms).
func _room_kind(c: Vector2i) -> String:
	for p in level.pieces:
		if (p.rect as Rect2i).has_point(c):
			return p.kind
	return ""


func _beside_reachable(c: Vector2i, reachable: Dictionary) -> bool:
	for d in Level.DIRS_8:
		if reachable.has(c + d):
			return true
	return false


## A locked grate across a straight tunnel that cuts off a quiet side room and nothing the level needs. Returns
## false if no tunnel fits.
func _grate() -> bool:
	var exit := level.outflow.get_center() if level.outflow.has_area() else level.stairs
	var before := level.reachable_from(level.start)
	var options: Array = []
	for p in level.pieces:
		if p.kind != "connector" or not (p.layout == "connector_ns" or p.layout == "connector_ew"):
			continue
		var r: Rect2i = p.rect
		# across the middle of the 2-square walkway
		var cells: Array[Vector2i] = [r.position + Vector2i(1, 1)]
		cells.append(r.position + (Vector2i(2, 1) if p.layout == "connector_ns" else Vector2i(1, 2)))
		for c in cells:
			level.set_tile(c, Level.Tile.GRATE_SHUT)
		var after := level.reachable_from(level.start)
		for c in cells:
			level.set_tile(c, Level.Tile.FLOOR)
		if not after.has(exit) or not after.has(level.start):
			continue
		# what the grate shuts off: it must hold a room with a crate or barrel to be worth opening
		var behind: Array[Vector2i] = []
		for c in level.cover:
			if not _beside_reachable(c, after) and _beside_reachable(c, before):
				behind.append(c)
		if not behind.is_empty() and after.size() < before.size() - 8:
			behind.sort()
			options.append([cells, behind, p.layout])
	if options.is_empty():
		return false
	var pick: Array = options[rng.randi_range(0, options.size() - 1)]
	var cells: Array = pick[0]
	for c in cells:
		level.set_tile(c, Level.Tile.GRATE_SHUT)
	level.grate.assign(cells)
	level.grate_across = "ns" if pick[2] == "connector_ns" else "ew"
	var prize: Vector2i = pick[1][rng.randi_range(0, (pick[1] as Array).size() - 1)]
	level.caches[prize] = {"kind": level.cover[prize], "item": "salve", "opened": false}
	# the key, in a cache Thomas can reach without it
	var reach := level.reachable_from(level.start)
	var keys: Array[Vector2i] = []
	for c in level.cover:
		if not level.caches.has(c) and _beside_reachable(c, reach):
			keys.append(c)
	if keys.is_empty():
		for c in cells:
			level.set_tile(c, Level.Tile.FLOOR)
		level.grate.clear()
		level.caches.erase(prize)
		return false
	keys.sort()
	var k: Vector2i = keys[rng.randi_range(0, keys.size() - 1)]
	level.caches[k] = {"kind": level.cover[k], "item": "grate_key", "opened": false}
	return true


## A sluice valve in one room and a flooded room elsewhere to drain, with a satchel in its basin. Returns false if
## the level has no flooded room or nowhere to put the valve.
func _valve() -> bool:
	var basins: Array = level.pieces.filter(func(p): return p.kind == "flooded")
	var rooms: Array = level.pieces.filter(func(p): return p.kind in ["junction", "chamber"])
	if basins.is_empty() or rooms.is_empty():
		return false
	var basin: Dictionary = basins[rng.randi_range(0, basins.size() - 1)]
	var water: Array[Vector2i] = []
	var r: Rect2i = basin.rect
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if level.get_tile(Vector2i(x, y)) == Level.Tile.WATER:
				water.append(Vector2i(x, y))
	if water.is_empty():
		return false
	var room: Dictionary = rooms[rng.randi_range(0, rooms.size() - 1)]
	var spot := _floor_by_wall(room.rect)
	if spot.x < 0:
		return false
	level.valve = spot
	level.set_tile(spot, Level.Tile.COVER)   # the standpipe stands in the way, like a crate
	level.drain = water
	var middle := water[water.size() / 2]
	level.caches[middle] = {"kind": "satchel", "item": ITEMS[rng.randi_range(0, ITEMS.size() - 1)], "opened": false, "drowned": true}
	return true


## A floor square against a wall, away from doorways and the middle of a room, that blocks nothing.
func _floor_by_wall(r: Rect2i) -> Vector2i:
	var spots: Array[Vector2i] = []
	var middle := r.get_center()
	var walkable := level.reachable_from(level.start).size()
	for y in range(r.position.y + 2, r.end.y - 1):
		for x in range(r.position.x + 1, r.end.x - 1):
			var c := Vector2i(x, y)
			if level.get_tile(c) != Level.Tile.FLOOR or maxi(absi(c.x - middle.x), absi(c.y - middle.y)) <= 2:
				continue
			if level.get_tile(c + Vector2i(0, -1)) == Level.Tile.WALL or level.get_tile(c + Vector2i(-1, 0)) == Level.Tile.WALL or level.get_tile(c + Vector2i(1, 0)) == Level.Tile.WALL:
				spots.append(c)
	while not spots.is_empty():
		var c: Vector2i = spots.pop_at(rng.randi_range(0, spots.size() - 1))
		level.set_tile(c, Level.Tile.COVER)
		var ok := level.reachable_from(level.start).size() == walkable - 1
		level.set_tile(c, Level.Tile.FLOOR)
		if ok:
			return c
	return Vector2i(-1, -1)
