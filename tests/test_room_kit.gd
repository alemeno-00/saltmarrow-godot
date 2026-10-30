extends TestBase
## The Sewers room kit: layouts read from blockouts, and levels assembled from them.
## Spec: design/quick-specs/sewer-room-kit-2026-10-29.md · blockout standard: design/art-briefs/README.md

const SEEDS := 300
const WALKABLE_CODES := [".", ",", "D", "~", "S"]
const TILE_OF := {
	"#": Level.Tile.WALL, "F": Level.Tile.WALL, "L": Level.Tile.WALL, ".": Level.Tile.FLOOR, ",": Level.Tile.FLOOR,
	"D": Level.Tile.FLOOR, "~": Level.Tile.WATER, "P": Level.Tile.PROP, "B": Level.Tile.PROP, "X": Level.Tile.PROP,
	"r": Level.Tile.RAIL, "S": Level.Tile.STAIRS,
}


## Which side a door square belongs to.
func _door_side(lay: RoomLayout, c: Vector2i) -> String:
	var connector := lay.size.x == 4
	if c.y == 0 or (not connector and c.y == 1 and lay.cell(Vector2i(c.x, 0)) == "D"):
		return "n"
	if c.y == lay.size.y - 1:
		return "s"
	if c.x == 0:
		return "w"
	return "e"


func test_every_layout_follows_the_door_standard() -> void:
	for id in SewerKit.all_layouts():
		var lay := RoomLayout.get_layout(id)
		check(lay != null, "%s loads from its blockout" % id)
		if lay == null:
			continue
		var connector := id.begins_with("connector_")
		eq(lay.size.x % 4 + lay.size.y % 4, 0, "%s is a whole number of 4-square blocks" % id)
		var at := 1 if connector else 5
		for side in lay.doors:
			var want: Array[Vector2i] = []
			match side:
				"n":
					want = [Vector2i(at, 0), Vector2i(at + 1, 0)]
				"s":
					want = [Vector2i(at, lay.size.y - 1), Vector2i(at + 1, lay.size.y - 1)]
				"w":
					want = [Vector2i(0, at), Vector2i(0, at + 1)]
				"e":
					want = [Vector2i(lay.size.x - 1, at), Vector2i(lay.size.x - 1, at + 1)]
			for c in want:
				eq(lay.cell(c), "D", "%s: door square %s on side %s" % [id, c, side])
		if connector:
			continue
		check(lay.doors.size() == 4, "%s has a door on every side (unused ones are walled off)" % id)
		# north walls are two squares thick, except where the door goes through
		for x in lay.size.x:
			if x != 5 and x != 6:
				check(not lay.cell(Vector2i(x, 1)) in WALKABLE_CODES, "%s: north wall is two squares thick at column %d" % [id, x])
		check(lay.cell(lay.size / 2) in WALKABLE_CODES, "%s: the centre square is walkable" % id)
		# the two squares straight in front of every door stay clear
		for side in lay.doors:
			for step in [1, 2]:
				for k in [5, 6]:
					var c: Vector2i = {"n": Vector2i(k, 1 + step), "s": Vector2i(k, lay.size.y - 1 - step),
						"w": Vector2i(step, k), "e": Vector2i(lay.size.x - 1 - step, k)}[side]
					check(lay.cell(c) in WALKABLE_CODES, "%s: square %s in front of the %s door is clear" % [id, c, side])
		# light reaches the whole room
		for y in lay.size.y:
			for x in lay.size.x:
				var c := Vector2i(x, y)
				if not lay.cell(c) in WALKABLE_CODES or lay.cell(c) == "D":
					continue
				var lit := false
				for l in lay.lights:
					if maxi(absi(l.x - x), absi(l.y - y)) <= 6:
						lit = true
				check(lit, "%s: square %s has a light within 6 squares" % [id, c])


## Every square of a placed piece is what its blockout says (mirrored if the piece is, unused doors walled off).
func _piece_matches(l: Level, p: Dictionary) -> int:
	var lay := RoomLayout.get_layout(p.layout)
	var bad := 0
	var r: Rect2i = p.rect
	for y in r.size.y:
		for x in r.size.x:
			var src := Vector2i(r.size.x - 1 - x if p.mirrored else x, y)
			var code := lay.cell(src)
			if code == "D":
				var side := _door_side(lay, src)
				if p.mirrored:
					side = {"w": "e", "e": "w"}.get(side, side)
				if not (p.open as Array).has(side):
					code = "F" if side == "n" else "#"
			var t := l.get_tile(r.position + Vector2i(x, y))
			if (t == Level.Tile.COVER or t == Level.Tile.GRATE_SHUT or t == Level.Tile.GRATE_OPEN) and TILE_OF[code] == Level.Tile.FLOOR:
				continue   # a crate, barrel, valve or grate stands on the blockout's floor
			if t != TILE_OF[code]:
				bad += 1
	return bad


func test_levels_over_many_seeds() -> void:
	for s in SEEDS:
		var bottom := s % 3 == 0
		var l := Level.new()
		l.generate(s, bottom)
		for g in l.grate:
			l.set_tile(g, Level.Tile.GRATE_OPEN)   # behind the locked grate is reachable once it's open
		var rooms := l.pieces.filter(func(p): return p.kind != "connector")
		check(rooms.size() >= 8 and rooms.size() <= 13, "seed %d: 8-12 rooms plus the exit (has %d)" % [s, rooms.size()])
		var reach := l.reachable_from(l.start)
		var walk := 0
		for y in l.height:
			for x in l.width:
				if l.is_walkable(Vector2i(x, y)):
					walk += 1
		eq(reach.size(), walk, "seed %d: every walkable square is reachable" % s)
		var exit_cell := l.outflow.get_center() if bottom else l.stairs
		check(reach.has(exit_cell), "seed %d: the exit is reachable" % s)
		var lore := 0
		var max_depth := 0
		var exit_depth := -1
		for p in l.pieces:
			if p.kind == "outflow":
				exit_depth = p.depth
				continue
			eq(_piece_matches(l, p), 0, "seed %d: %s at %s matches its blockout" % [s, p.layout, p.rect.position])
			if p.kind == "lore":
				lore += 1
			if p.kind == "stairs":
				exit_depth = p.depth
			elif p.kind != "connector":
				max_depth = maxi(max_depth, p.depth)
			if p.parent >= 0 and p.kind != "connector":
				var parent: Dictionary = l.pieces[p.parent]
				check(parent.layout != p.layout, "seed %d: %s doesn't follow itself" % [s, p.layout])
		check(lore <= 1, "seed %d: at most one lore room (has %d)" % [s, lore])
		check(exit_depth > max_depth, "seed %d: the exit is at the end of the longest branch" % s)


func test_layouts_vary_and_some_are_mirrored() -> void:
	var seen := {}
	var mirrored := 0
	for s in 40:
		var l := Level.new()
		l.generate(s)
		for p in l.pieces:
			seen[p.layout] = true
			if p.mirrored:
				mirrored += 1
	for id in SewerKit.ROOMS_BY_KIND.junction + SewerKit.ROOMS_BY_KIND.chamber + SewerKit.ROOMS_BY_KIND.flooded:
		check(seen.has(id), "%s turns up within 40 levels" % id)
	check(mirrored > 0, "some rooms are mirrored")


func test_props_block_and_rails_dont_hide() -> void:
	var l := Level.new(7, 3)
	for x in range(1, 6):
		l.set_tile(Vector2i(x, 1), Level.Tile.FLOOR)
	l.set_tile(Vector2i(2, 1), Level.Tile.PROP)
	l.set_tile(Vector2i(4, 1), Level.Tile.RAIL)
	l.rebuild_paths()
	check(not l.is_walkable(Vector2i(2, 1)), "a prop blocks movement")
	check(l.blocks_sight(Vector2i(2, 1)), "a prop blocks sight")
	check(not l.is_walkable(Vector2i(4, 1)), "a railing blocks movement")
	check(not l.blocks_sight(Vector2i(4, 1)), "but not sight")
	check(l.line_of_sight(Vector2i(3, 1), Vector2i(5, 1)), "you can see across a railing")


func test_save_keeps_the_rooms() -> void:
	var l := Level.new()
	l.generate(11, true)
	var back := Level.from_dict(JSON.parse_string(JSON.stringify(l.to_dict())))
	eq(back.tiles, l.tiles, "tiles survive saving")
	eq(back.stairs, l.stairs, "stairs survive saving")
	eq(back.outflow, l.outflow, "the Outflow survives saving")
	eq(back.gates, l.gates, "the gates survive saving")
	eq(back.lights, l.lights, "the lights survive saving")
	eq(back.pieces.size(), l.pieces.size(), "every piece survives saving")
	for i in l.pieces.size():
		for k in ["kind", "layout", "mirrored", "variant", "depth", "parent"]:
			eq(back.pieces[i][k], l.pieces[i][k], "piece %d keeps its %s" % [i, k])
		eq(back.pieces[i].rect, l.pieces[i].rect, "piece %d keeps its place" % i)


func test_each_depth_has_its_own_seed() -> void:
	eq(Game.depth_seed(1234, 1), 1234, "depth 1 uses the life's seed")
	eq(Game.depth_seed(1234, 2), Game.depth_seed(1234, 2), "the same life and depth always give the same level")
	check(Game.depth_seed(1234, 2) != Game.depth_seed(1234, 3), "each depth differs")
	check(Game.depth_seed(1234, 2) != Game.depth_seed(1235, 1), "a new life's first level is not the last life's second")


func test_same_seed_same_level_every_time() -> void:
	for s in 30:
		var a := Level.new()
		a.generate(s, s % 3 == 0)
		var b := Level.new()
		b.generate(s, s % 3 == 0)
		eq(a.tiles, b.tiles, "seed %d builds the same level twice" % s)
