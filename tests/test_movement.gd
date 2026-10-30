extends TestBase
## Drives the real exploration scene with free movement (design/quick-specs/free-movement-2026-10-30.md): speed,
## speeding up and stopping, diagonals, sliding along walls, doorways, doors, water, click-to-walk, turn dust, and
## everyone stepping onto squares when a fight starts.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(a)
	if game != null:
		game.queue_free()


## A small hand-made room so the tests know exactly what is where: floor x 1-8, y 1-6, a wall down x 5 with a
## one-square door at (5, 3).
func _room() -> void:
	var l := Level.new(10, 8)
	for y in range(1, 7):
		for x in range(1, 9):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	for y in range(1, 7):
		l.set_tile(Vector2i(5, y), Level.Tile.WALL)
	l.set_tile(Vector2i(5, 3), Level.Tile.DOOR_CLOSED)
	l.start = Vector2i(2, 3)
	l.rebuild_paths()
	game.clear_enemies()
	game.level = l
	game.view.show_level(l)
	_put(MovementRules.centre(l.start))


func _put(p: Vector2) -> void:
	game.hero.place(MovementRules.cell_of(p))
	game.hero.glide_free(p, 0.0)
	game.hero_unit.cell = game.hero.grid_pos
	game.path.clear()
	game._vel = Vector2.ZERO


func _speed() -> float:
	return MovementRules.px(MovementRules.WALK_SPEED)


func test_walking_covers_the_walk_speed() -> void:
	_room()
	var from := game.hero.position
	hold(game, ["move_right"], 0.5)
	var moved := game.hero.position - from
	# 0.5 s at 3 m/s, less the first 0.1 s spent speeding up
	var want := _speed() * (0.5 - MovementRules.ACCEL_TIME / 2.0)
	check(absf(moved.x - want) < 2.0, "half a second covers about %.1f px (moved %.1f)" % [want, moved.x])
	check(absf(moved.y) < 0.01, "and straight east")


func test_speeds_up_and_stops_quickly() -> void:
	_room()
	hold(game, ["move_right"], MovementRules.ACCEL_TIME + 0.02)
	check(game._vel.length() > _speed() * 0.97, "full speed after %.2f s (%.1f px/s)" % [MovementRules.ACCEL_TIME, game._vel.length()])
	run(game, MovementRules.STOP_TIME + 0.02)
	eq(game._vel, Vector2.ZERO, "stopped %.2f s after letting go" % MovementRules.STOP_TIME)


func test_two_keys_go_diagonally_and_no_faster() -> void:
	_room()
	_put(Vector2(48, 48))
	var from := game.hero.position
	hold(game, ["move_right", "move_down"], 0.4)
	var moved := game.hero.position - from
	check(absf(moved.x - moved.y) < 0.5, "right + down goes diagonally (%s)" % moved)
	_put(Vector2(48, 48))
	hold(game, ["move_right"], 0.4)
	var straight := game.hero.position.x - 48.0
	check(absf(moved.length() - straight) < 1.0, "a diagonal covers the same distance as a straight line (%.1f vs %.1f)" % [moved.length(), straight])


func test_slides_along_a_wall() -> void:
	_room()
	_put(MovementRules.centre(Vector2i(4, 2)))
	var start_y := game.hero.position.y
	hold(game, ["move_right", "move_up"], 1.0)
	var r := MovementRules.px(MovementRules.HERO_RADIUS)
	check(game.hero.position.x <= 5 * 32 - r + 0.1, "the wall stops him going east (x %.1f)" % game.hero.position.x)
	check(game.hero.position.x > 5 * 32 - r - 1.0, "he stays against it")
	check(game.hero.position.y < start_y - 12.0, "and slides on north along it (y %.1f from %.1f)" % [game.hero.position.y, start_y])


func test_never_sticks_on_a_doorway_corner() -> void:
	_room()
	# heading east a little high, so his shoulder meets the corner of the wall above the door
	_put(Vector2(140, 100))
	hold(game, ["move_right"], 1.5)
	check(game.hero.position.x > 6 * 32, "he rounds the corner and goes through the door (x %.1f)" % game.hero.position.x)
	eq(game.level.get_tile(Vector2i(5, 3)), Level.Tile.DOOR_OPEN, "and the door opened as he walked into it")


func test_click_to_walk_through_the_door() -> void:
	_room()
	check(game.walk_to(Vector2i(7, 3)), "a route exists to the far room")
	run(game, 3.0)
	eq(game.hero.grid_pos, Vector2i(7, 3), "walked all the way, through the door")
	check(game.hero.position.distance_to(MovementRules.centre(Vector2i(7, 3))) <= MovementRules.ARRIVE + 1.0, "and stopped on the square")
	eq(game.level.get_tile(Vector2i(5, 3)), Level.Tile.DOOR_OPEN, "opened the door on the way")


func test_a_key_stops_walking() -> void:
	_room()
	game.walk_to(Vector2i(7, 3))
	run(game, 0.15)
	var ev := InputEventAction.new()
	ev.action = "move_up"
	ev.pressed = true
	game._unhandled_input(ev)
	check(game.path.is_empty(), "pressing a movement key cancels the walk")


func test_water_slows_him() -> void:
	_room()
	var from := game.hero.position
	hold(game, ["move_right"], 0.4)
	var dry := game.hero.position.x - from.x
	for y in range(1, 7):
		for x in range(1, 5):
			game.level.set_tile(Vector2i(x, y), Level.Tile.WATER)
	_put(from)
	hold(game, ["move_right"], 0.4)
	var wet := game.hero.position.x - from.x
	check(absf(wet / dry - MovementRules.WATER_SLOW) < 0.05, "wading goes at %d%% of walking (%.1f vs %.1f px)" % [roundi(MovementRules.WATER_SLOW * 100), wet, dry])


func test_a_sharp_turn_kicks_up_dust() -> void:
	_room()
	_put(Vector2(48, 112))
	var before := game.dust_made
	hold(game, ["move_right"], 0.3)
	eq(game.dust_made, before, "walking straight raises none")
	hold(game, ["move_left"], 0.05)
	eq(game.dust_made, before + 1, "turning back at speed kicks up a puff")


func test_a_fight_starts_where_everyone_stands() -> void:
	_room()
	_put(MovementRules.centre(Vector2i(2, 3)) + Vector2(10, 5))
	var f := game._add_enemy(Bestiary.faithful(), Vector2i(3, 5))
	game.views[f].glide_free(MovementRules.centre(Vector2i(3, 5)) + Vector2(-9, 7), 0.0)
	game.views[f].face_point(game.hero.position)   # looking his way
	var where := game.hero.position
	game._check_spotted()
	check(game.in_fight(), "being seen starts a fight")
	check(game.hero_unit.pos.distance_to(where) < 0.01, "Thomas fights from exactly where he stood, off the grid (%s)" % game.hero_unit.pos)
	for u in game.battle.units:
		for o in game.battle.units:
			if u != o and u.alive() and o.alive():
				check(u.pos.distance_to(o.pos) >= u.radius() + o.radius() - 0.1, "%s and %s don't overlap" % [u.name, o.name])


func test_click_to_walk_stops_exactly_where_clicked() -> void:
	_room()
	var spot := Vector2(117.0, 151.0)   # a third of the way into a square, not its middle
	check(game.walk_to_point(spot), "a route exists")
	run(game, 2.0)
	check(game.hero.position.distance_to(spot) <= MovementRules.ARRIVE + 1.0, "he stops on the clicked point, not a square's middle (%s)" % game.hero.position)


func test_a_clicked_route_cuts_straight_across_open_floor() -> void:
	_room()
	_put(Vector2(40.0, 40.0))
	game.walk_to_point(Vector2(150.0, 190.0))
	eq(game.path.size(), 1, "across an open room the route is one straight line, not square by square")


func test_clicking_a_wall_walks_up_to_it() -> void:
	_room()
	check(game.walk_to_point(Vector2(5 * 32 + 10, 60.0)), "a click on the wall still sets off")
	run(game, 2.0)
	check(game.hero.position.x > 4 * 32 and game.hero.position.x < 5 * 32, "he stops against the wall, beside where it was clicked (x %.1f)" % game.hero.position.x)
