extends TestBase
## The First Shift in the running game: the bottom level, Garrick, and winning the run.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func _garrick() -> Combatant:
	for e in game.enemies:
		if e.kind == "solo":
			return e
	return null


func test_the_bottom_depth_holds_garrick() -> void:
	game._descend()
	check(not game.level.outflow.has_area(), "depth 2 is an ordinary level")
	check(_garrick() == null, "with no boss")
	game._descend()
	eq(game.depth, Game.BOTTOM_DEPTH, "depth 3")
	check(game.level.outflow.has_area(), "has the Outflow")
	var g := _garrick()
	check(g != null, "Garrick is there")
	if g != null:
		check(game.level.outflow.has_point(g.cell), "waiting in the Outflow")


func test_a_new_life_starts_at_the_top() -> void:
	game._descend()
	game._descend()
	game.new_level(99)
	eq(game.depth, 1, "back to depth 1")
	check(not game.level.outflow.has_area(), "no Outflow at the top")


func test_picking_up_the_tag_wins_the_run() -> void:
	game._descend()
	game._descend()
	for e in game.enemies:
		e.dead = true
	var c := game.level.start
	var next := c + Vector2i(1, 0)
	if not game.level.is_walkable(next):
		next = c + Vector2i(0, 1)
	game.tag_cell = next
	game.try_step(next - c)
	check(game.won, "the run is won")
	eq(game.tag_cell, Vector2i(-1, -1), "the tag is picked up")
