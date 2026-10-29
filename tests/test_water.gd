extends TestBase
## Moving water: a shimmer over every water square (stand-in and painted alike), and ripples when anyone wades.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func _water_in(l: Level, region: Rect2i) -> int:
	var n := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			if l.get_tile(Vector2i(x, y)) == Level.Tile.WATER:
				n += 1
	return n


func test_every_water_square_shimmers() -> void:
	for life in [7, 8]:
		game.new_level(life)
		var total := 0
		for ch in game.view.chunks():
			var want := _water_in(game.level, ch.region)
			eq(ch.water_squares().size(), want, "life %d: chunk %s shimmers on each of its water squares" % [life, ch.region.position])
			if want > 0:
				check(ch.water != null and ch.water.material is ShaderMaterial, "the chunk's water uses the water shader")
			total += want
		check(total > 0, "life %d has some water" % life)


func test_wading_makes_ripples() -> void:
	for e in game.enemies:
		e.dead = true   # only Thomas's steps (the patrol wades too)
	var c: Vector2i = game.level.start
	var to := c + Vector2i(1, 0)
	game.level.set_tile(to, Level.Tile.WATER)
	var before := game.ripples_made
	game.try_step(Vector2i(1, 0))
	eq(game.hero.grid_pos, to, "Thomas steps into the water")
	eq(game.ripples_made, before + 1, "a ripple spreads where he stepped")
	game.try_step(Vector2i(-1, 0))
	eq(game.ripples_made, before + 1, "stepping out onto dry floor makes none")


func test_falling_in_water_splashes() -> void:
	var c: Vector2i = game.level.start
	game.level.set_tile(c, Level.Tile.WATER)
	game.hero_unit.prone = true
	var before := game.ripples_made
	await game._play_one({"t": "prone", "unit": game.hero_unit})
	eq(game.ripples_made, before + 1, "going down in water makes a splash")
