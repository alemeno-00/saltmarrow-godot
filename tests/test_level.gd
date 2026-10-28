extends TestBase


func test_same_seed_same_level() -> void:
	var a := Level.new(); a.generate(42)
	var b := Level.new(); b.generate(42)
	eq(a.tiles, b.tiles, "same seed gives the same tiles")
	var c := Level.new(); c.generate(43)
	check(a.tiles != c.tiles, "different seed gives a different level")


func test_every_floor_square_is_reachable() -> void:
	for s in [1, 2, 3, 7, 99, 1234, 55555]:
		var l := Level.new(); l.generate(s)
		check(l.rooms.size() >= 6, "seed %d has at least 6 rooms (has %d)" % [s, l.rooms.size()])
		var seen := l.reachable_from(l.start)
		var walk := 0
		for y in l.height:
			for x in l.width:
				if l.is_walkable(Vector2i(x, y)):
					walk += 1
		eq(seen.size(), walk, "seed %d: every walkable square reachable from the start" % s)


func test_walls_and_corners_block() -> void:
	var l := Level.new(5, 5)
	for y in range(1, 4):
		for x in range(1, 4):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.set_tile(Vector2i(2, 1), Level.Tile.WALL)
	l.rebuild_paths()
	check(not l.can_step(Vector2i(1, 1), Vector2i(-1, 0)), "can't walk into the outer wall")
	check(not l.can_step(Vector2i(1, 1), Vector2i(1, 0)), "can't walk into a wall square")
	check(not l.can_step(Vector2i(1, 2), Vector2i(1, -1)), "can't cut the corner of a wall diagonally")
	check(l.can_step(Vector2i(1, 2), Vector2i(1, 1)), "can step diagonally in the open")
	check(not l.can_step(Vector2i(1, 1), Vector2i(2, 0)), "can't move two squares at once")


func test_paths_are_legal_steps() -> void:
	var l := Level.new(); l.generate(7)
	var target: Vector2i = l.rooms[l.rooms.size() - 1].get_center()
	var p := l.find_path(l.start, target)
	check(not p.is_empty(), "a route exists to the last room")
	var c := l.start
	for s in p:
		check(l.can_step(c, s - c), "each step of the route is a legal step (%s to %s)" % [c, s])
		c = s
	eq(c, target, "the route ends at the target")
	check(l.find_path(l.start, Vector2i(0, 0)).is_empty(), "no route into solid rock")


func test_save_round_trip() -> void:
	var l := Level.new(); l.generate(5)
	l.set_tile(l.start + Vector2i(1, 0), Level.Tile.DOOR_OPEN)
	var back := Level.from_dict(JSON.parse_string(JSON.stringify(l.to_dict())))
	eq(back.tiles, l.tiles, "tiles survive saving")
	eq(back.start, l.start, "start survives saving")
