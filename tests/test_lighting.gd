extends TestBase
## The dark and the lights: every light square gets a real light, no drawn chunk of the level is reached by more
## lights than the web renderer can show on one item (15), and fight markers stay bright.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func test_every_light_square_gets_a_light() -> void:
	for life in [7, 8, 9]:
		game.new_level(life)
		eq(game.lighting.light_count(), game.level.lights.size(), "life %d: one light for each lantern and brazier" % life)


func test_the_outflow_lanterns_are_lit() -> void:
	game._descend()
	game._descend()
	eq(game.lighting.light_count(), game.level.lights.size() + 3, "the Outflow's three lanterns are lit too")


func test_no_chunk_is_reached_by_more_than_15_lights() -> void:
	var worst := 0
	for s in 120:
		var l := Level.new()
		l.generate(s, s % 3 == 0)
		var points := Lighting.light_points(l)
		for n in LevelView.chunk_light_counts(l, points, Lighting.LANTERN_RADIUS * Lighting.TILE):
			worst = maxi(worst, n)
	check(worst <= Lighting.MAX_LIGHTS_PER_ITEM, "at most 15 lights reach any chunk (worst: %d)" % worst)


func test_the_world_is_dark_but_the_markers_are_not() -> void:
	check(game.darkness != null and game.darkness.color == Lighting.AMBIENT, "the world is dimmed")
	check(game.hero.get_children().any(func(c): return c is PointLight2D), "Thomas carries a lantern")
	check(game.overlay.get_parent() is CanvasLayer, "the fight markers are drawn on an undimmed layer")


func test_unused_doorways_are_sealed() -> void:
	game.new_level(7)
	for p in game.level.pieces:
		if p.kind == "connector" or p.kind == "outflow":
			continue
		var lay := RoomLayout.get_layout(p.layout)
		eq(LevelView.sealed_doorways(p).size(), lay.doors.size() - (p.open as Array).size(), "%s: every unused doorway gets a seal" % p.layout)
