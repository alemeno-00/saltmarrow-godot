extends TestBase
## Cover and levels built for sneaking (design/quick-specs/sneaking-2026-10-30.md, "Cover, and levels built for
## sneaking"): crates and barrels hide a crouched Thomas, water hides him a little, and the generator makes loops and
## covered ways into rooms, without ever cutting the level in two.

const SEEDS := 40

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


## A dark hall with a crate at (6, 5) and a pool of water in its south-west corner.
func _hall() -> void:
	var l := Level.new(22, 12)
	for y in range(1, 11):
		for x in range(1, 21):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	for y in range(7, 11):
		for x in range(1, 6):
			l.set_tile(Vector2i(x, y), Level.Tile.WATER)
	l.set_tile(Vector2i(6, 5), Level.Tile.COVER)
	l.cover[Vector2i(6, 5)] = "crate"
	l.start = Vector2i(2, 5)
	l.rebuild_paths()
	game.clear_enemies()
	game.battle = null
	game.level = l
	game.view.show_level(l)
	Grounding.level = l
	Grounding.lights.clear()
	game.set_lantern("lit")
	game.sneaking = false


func _put(p: Vector2) -> void:
	game.hero.place(MovementRules.cell_of(p))
	game.hero.glide_free(p, 0.0)
	game.hero_unit.pos = p


func _watcher(c: Vector2i, look: Vector2) -> Combatant:
	var f := game._add_enemy(Bestiary.faithful(), c)
	game.views[f].look = look.normalized()
	game._heads[f] = 9999.0
	return f


func test_a_crate_hides_him_only_when_he_crouches_close_behind_it() -> void:
	_hall()
	var f := _watcher(Vector2i(9, 5), Vector2.LEFT)
	_put(MovementRules.centre(Vector2i(5, 5)))   # right behind the crate, 4 squares from the watcher
	check(game.sees_thomas(f), "standing behind it, his head shows over it: seen")
	game.toggle_sneak()
	check(not game.sees_thomas(f), "crouched behind it: hidden")
	_put(MovementRules.centre(Vector2i(3, 5)))   # still in line with it, but 3 squares back
	check(game.sees_thomas(f), "crouched too far behind it, it doesn't hide him")
	_put(MovementRules.centre(Vector2i(5, 3)))   # beside it, not behind it
	check(game.sees_thomas(f), "and not when it isn't between them")


func test_crates_block_walking_but_not_sight() -> void:
	_hall()
	check(not game.level.is_walkable(Vector2i(6, 5)), "nobody walks through a crate")
	check(game.level.line_of_sight(Vector2i(2, 5), Vector2i(10, 5)), "but it is low: it doesn't block sight on its own")


func test_crouching_in_water_slows_the_meter() -> void:
	_hall()
	game.set_lantern("out")
	game.toggle_sneak()
	_watcher(Vector2i(12, 8), Vector2.LEFT)
	_put(MovementRules.centre(Vector2i(6, 8)))   # crouched on dry floor
	var dry := 0.0
	while not game.in_fight() and dry < 15.0:
		game._check_spotted(1.0 / 60.0)
		dry += 1.0 / 60.0
	_hall()
	game.set_lantern("out")
	game.toggle_sneak()
	_watcher(Vector2i(12, 8), Vector2.LEFT)
	_put(MovementRules.centre(Vector2i(5, 8)) + Vector2(14, 0))   # in the water's edge square, about as far
	var wet := 0.0
	while not game.in_fight() and wet < 15.0:
		game._check_spotted(1.0 / 60.0)
		wet += 1.0 / 60.0
	check(wet > dry * 1.25, "half under the water he lasts longer in its view (%.2f s vs %.2f s)" % [wet, dry])


func test_levels_have_loops_cover_and_covered_ways_in() -> void:
	var with_loops := 0
	var rooms := 0
	var covered := 0
	for s in SEEDS:
		var l := Level.new()
		l.generate(s, s % 3 == 0)
		if l.loops > 0:
			with_loops += 1
		check(not l.cover.is_empty(), "seed %d: crates and barrels to hide behind" % s)
		for c in l.cover:
			eq(l.get_tile(c), Level.Tile.COVER, "seed %d: every crate stands on its square" % s)
		for p in l.pieces:
			if not p.kind in ["junction", "chamber", "flooded"]:
				continue
			rooms += 1
			var r: Rect2i = p.rect
			if l.cover.keys().any(func(c): return r.has_point(c)):
				covered += 1
			check(l.is_walkable(r.get_center()), "seed %d: the middle of %s, where a band waits, is clear" % [s, p.layout])
	check(with_loops >= SEEDS * 0.6, "most levels have another way round (%d of %d)" % [with_loops, SEEDS])
	check(covered >= rooms * 0.9, "nearly every room a band can wait in has cover (%d of %d)" % [covered, rooms])


func test_the_same_seed_gives_the_same_cover() -> void:
	var a := Level.new()
	a.generate(77)
	var b := Level.new()
	b.generate(77)
	eq(a.cover, b.cover, "same seed, same crates in the same places")
	eq(a.loops, b.loops, "and the same loops")
