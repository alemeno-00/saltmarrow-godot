extends TestBase
## Drives the real exploration scene: steps, walls, doors, diagonals, held keys and click-to-walk.

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


## A small hand-made room so the tests know exactly what is where.
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
	game.hero.place(l.start)
	game.path.clear()


func _run(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		game._process(1.0 / 60.0)
		t += 1.0 / 60.0


func test_step_and_wall() -> void:
	_room()
	check(game.try_step(Vector2i(1, 0)), "steps onto open floor")
	eq(game.hero.grid_pos, Vector2i(3, 3), "moved one square east")
	game.hero.place(Vector2i(4, 2))
	check(not game.try_step(Vector2i(1, 0)), "blocked by the wall")
	eq(game.hero.grid_pos, Vector2i(4, 2), "did not move into the wall")


func test_turns_count() -> void:
	_room()
	var t0: int = game.turn
	game.try_step(Vector2i(0, 1))
	game.wait_turn()
	eq(game.turn, t0 + 2, "a step and a wait are a turn each")


func test_door_opens_when_walked_into() -> void:
	_room()
	game.hero.place(Vector2i(4, 3))
	check(game.try_step(Vector2i(1, 0)), "walks into the closed door")
	eq(game.level.get_tile(Vector2i(5, 3)), Level.Tile.DOOR_OPEN, "the door is now open")


func test_blocked_diagonal_slides() -> void:
	_room()
	game.hero.place(Vector2i(4, 2))
	# up-right is blocked by the wall line; he should slide straight up instead
	check(game.try_step(Vector2i(1, -1)), "a blocked diagonal still moves")
	eq(game.hero.grid_pos, Vector2i(4, 1), "slid along the open direction")


func test_two_keys_make_a_diagonal() -> void:
	_room()
	Input.action_press("move_right")
	Input.action_press("move_down")
	game._pending_timer = game.COMBO_WINDOW
	_run(0.05)
	eq(game.hero.grid_pos, Vector2i(3, 4), "right + down together step diagonally")
	Input.action_release("move_right")
	Input.action_release("move_down")
	_run(0.05)


func test_holding_a_key_repeats() -> void:
	_room()
	game.hero.place(Vector2i(1, 3))
	Input.action_press("move_down")
	game._pending_timer = game.COMBO_WINDOW
	_run(0.05)
	eq(game.hero.grid_pos, Vector2i(1, 4), "first step comes at once")
	_run(0.35)
	eq(game.hero.grid_pos, Vector2i(1, 6), "holding keeps stepping until the wall")
	Input.action_release("move_down")
	_run(0.05)


func test_click_to_walk_through_the_door() -> void:
	_room()
	check(game.walk_to(Vector2i(7, 3)), "a route exists to the far room")
	_run(2.0)
	eq(game.hero.grid_pos, Vector2i(7, 3), "walked all the way, through the door")
	eq(game.level.get_tile(Vector2i(5, 3)), Level.Tile.DOOR_OPEN, "opened the door on the way")


func test_a_key_stops_walking() -> void:
	_room()
	game.walk_to(Vector2i(7, 3))
	_run(0.15)
	var ev := InputEventAction.new()
	ev.action = "move_up"
	ev.pressed = true
	game._unhandled_input(ev)
	check(game.path.is_empty(), "pressing a movement key cancels the walk")
