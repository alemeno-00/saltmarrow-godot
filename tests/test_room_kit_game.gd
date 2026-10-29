extends TestBase
## The room kit in the running game: where enemies wait, and a fresh world each life.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func _check_enemies() -> void:
	var entry: Rect2i = game.level.pieces[0].rect
	for e in game.enemies:
		check(not entry.has_point(e.cell), "no enemy waits in the entry (one at %s)" % e.cell)
		if e.kind != "solo":
			check(game.level.find_path(game.level.start, e.cell).size() >= 15, "no enemy within 15 steps of the start (one at %s)" % e.cell)


func test_enemies_wait_away_from_the_start() -> void:
	for life in [7, 8, 9, 10, 11]:
		game.new_level(life)
		_check_enemies()
		check(not game.enemies.is_empty(), "life %d: there is someone to fight" % life)


func test_the_same_life_keeps_its_levels_and_a_new_life_changes_them() -> void:
	game.new_level(21)
	var first := game.level.tiles
	game._descend()
	var second := game.level.tiles
	game.new_level(21)
	eq(game.level.tiles, first, "the same seed gives the same first level")
	game._descend()
	eq(game.level.tiles, second, "and the same second level")
	game.new_level(22)
	check(game.level.tiles != first and game.level.tiles != second, "a new life gets new levels")
