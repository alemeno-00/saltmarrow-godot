extends TestBase
## Room events, room contents part 5 (design/quick-specs/room-contents-2026-10-30.md): 1-2 per level, each in its
## own room and of its own kind, each firing once when Thomas walks in. The hymn waits for a Faithful band in earshot;
## the Drowned rise only in flooded rooms and add a miner; star frost makes the room's lanterns gutter; the pale
## figure stands just past his lantern's reach.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func test_each_level_has_one_or_two_events_in_their_own_rooms() -> void:
	var counts := {}
	var kinds := {}
	for s in range(1, 301):
		var l := Level.new()
		l.generate(s)
		var n := l.events.size()
		counts[n] = true
		var seen := {}
		for room in l.events:
			var p: Dictionary = l.pieces[room]
			var kind: String = l.events[room].kind
			kinds[kind] = true
			check(p.kind in RoomContents.EVENT_ROOMS, "seed %d: an event in a %s, not a room" % [s, p.kind])
			check(not (p.rect as Rect2i).has_point(l.start), "seed %d: never where he starts" % s)
			check(kind != "drowned_rise" or p.kind == "flooded", "seed %d: the Drowned rise only in a flooded room" % s)
			check(not seen.has(kind), "seed %d: never the same event twice in a level" % s)
			seen[kind] = true
		check(n >= 1 and n <= 2, "seed %d: 1-2 events (got %d)" % [s, n])
	check(counts.has(1) and counts.has(2), "some levels have one, some two")
	for k in RoomContents.EVENT_KINDS:
		check(kinds.has(k), "%s turns up somewhere" % k)


func test_the_same_seed_gives_the_same_events() -> void:
	var a := Level.new()
	a.generate(77)
	var b := Level.new()
	b.generate(77)
	eq(a.events, b.events, "seed 77 twice")


## A level with this event, started in the game with no enemies; returns its room.
func _level_with(kind: String) -> int:
	for s in range(1, 500):
		var l := Level.new()
		l.generate(s)
		for room in l.events:
			if l.events[room].kind == kind:
				game.new_level(s)
				game.clear_enemies()
				return room
	failures.append("no level has a %s" % kind)
	return -1


## Put Thomas on the dry floor square nearest the middle of a room.
func _enter(room: int) -> void:
	var r: Rect2i = game.level.pieces[room].rect
	var best := Vector2i(-1, -1)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if game.level.is_walkable(c) and not game.level.is_wet(c) and (best.x < 0 or Vector2(c - r.get_center()).length() < Vector2(best - r.get_center()).length()):
				best = c
	_put(best)


func _put(c: Vector2i) -> void:
	game.hero.place(c)
	game.hero.glide_free(MovementRules.centre(c), 0.0)
	game.hero_unit.pos = MovementRules.centre(c)
	game.path.clear()
	game._vel = Vector2.ZERO


func _leave() -> void:
	_put(game.level.start)
	run(game, 0.1)


func test_star_frost_fires_once_and_the_lanterns_gutter() -> void:
	var room := _level_with("star_frost")
	_enter(room)
	run(game, 0.1)
	eq(game.events_fired, ["star_frost"], "walking in, the frost comes")
	check(game.level.events[room].fired, "and it is spent")
	var r: Rect2i = game.level.pieces[room].rect
	var middle := Vector2(r.get_center()) * MovementRules.TILE
	check(game.lighting.gutter_at(middle) <= 1.0 and not game.lighting._gutters.is_empty(), "the room's flames gutter")
	_leave()
	_enter(room)
	run(game, 0.1)
	eq(game.events_fired, ["star_frost"], "going back in, nothing happens again")


func test_the_drowned_rise_from_the_water() -> void:
	var room := _level_with("drowned_rise")
	_enter(room)
	run(game, 0.05)
	eq(game.events_fired, ["drowned_rise"], "walking into the flooded room")
	eq(game.enemies.size(), 1, "something has risen")
	if game.enemies.size() == 1:
		var e: Combatant = game.enemies[0]
		eq(e.name, "Drowned Miner", "a Drowned Miner")
		check(game.level.is_wet(e.cell), "out of the water")
		check(e.state == "hunting" or game.in_fight(), "and it comes for him")
		var d := Vector2(e.cell - game.hero.grid_pos).length()
		check(d >= Game.RISE_NEAR and d <= Game.RISE_FAR, "close by (%.1f squares)" % d)


func test_the_hymn_waits_until_a_faithful_band_is_near() -> void:
	var room := _level_with("hymn")
	_enter(room)
	run(game, 0.1)
	check(game.events_fired.is_empty(), "no one near to sing: nothing yet")
	check(not game.level.events[room].fired, "the hymn is still waiting")
	# a Faithful about ten squares off, facing away so it doesn't spot him
	var spot := Vector2i(-1, -1)
	for y in range(-12, 13):
		for x in range(-12, 13):
			var c := game.hero.grid_pos + Vector2i(x, y)
			var d := Vector2(x, y).length()
			if d >= 8.0 and d <= Game.HYMN_REACH and game.level.is_walkable(c) and not game.level.line_of_sight(game.hero.grid_pos, c):
				spot = c
	check(spot.x >= 0, "a place out of sight for the Faithful")
	if spot.x < 0:
		return
	var f := game._add_enemy(Bestiary.faithful(), spot)
	game._heads[f] = 9999.0
	_leave()
	_enter(room)
	run(game, 0.1)
	eq(game.events_fired, ["hymn"], "with a Faithful in earshot, he hears them singing")


func test_something_stands_at_the_edge_of_the_light() -> void:
	var room := _level_with("watcher")
	_enter(room)
	run(game, 0.1)
	eq(game.events_fired, ["watcher"], "walking in")
	check(game.watcher != null, "a pale figure is there")
	if game.watcher != null:
		var d := MovementRules.metres(game.watcher.position.distance_to(game.hero.position)) / 1.5
		check(d > Lighting.HERO_RADIUS, "past the reach of his lantern (%.1f squares)" % d)
		check(d < Game.WATCHER_FAR + 1.0, "but close enough to see")
