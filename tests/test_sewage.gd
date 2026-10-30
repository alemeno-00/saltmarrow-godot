extends TestBase
## Deep sewage tunnels (design/quick-specs/deep-sewage-tunnels-2026-10-30.md): long waist-deep tunnels in the
## levels, wading (slow, costly, loud, deep), drowning, ledges, and the lurkers: unseen, their tell spotted by
## creeping, rising to strike, dragging under.

const SEEDS := 60

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


# ---------------------------------------------------------------- the tunnels in the levels

func test_levels_get_long_sewage_tunnels() -> void:
	var with := 0
	for s in SEEDS:
		var l := Level.new()
		l.generate(s, s % 3 == 0)
		check(l.sewage.size() <= SewerKit.SEWAGE_MAX, "seed %d: at most two" % s)
		if not l.sewage.is_empty():
			with += 1
		for r in l.sewage:
			check(maxi(r.size.x, r.size.y) >= 12 and maxi(r.size.x, r.size.y) <= 20, "seed %d: 12-20 squares long (%s)" % [s, r.size])
			var deep := 0
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					if l.get_tile(Vector2i(x, y)) == Level.Tile.DEEP:
						deep += 1
			check(deep >= maxi(r.size.x, r.size.y), "seed %d: its walkway is deep sewage" % s)
	check(with >= SEEDS / 3, "plenty of levels have one (%d of %d)" % [with, SEEDS])


func test_tunnels_hide_lurkers() -> void:
	var tunnels := 0
	var with := 0
	for s in range(1, 25):
		game.new_level(s)
		for r in game.level.sewage:
			tunnels += 1
			var lurkers := game.enemies.filter(func(e): return e.state == "lurking" and (r as Rect2i).has_point(e.cell))
			check(lurkers.size() <= StealthRules.LURKERS_PER_TUNNEL, "seed %d: one lurker at most" % s)
			if not lurkers.is_empty():
				with += 1
			for l in lurkers:
				eq(game.level.get_tile(l.cell), Level.Tile.DEEP, "seed %d: lying in the sewage" % s)
				check(not game.views[l].visible, "seed %d: unseen" % s)
	check(tunnels > 0, "some tunnels were checked (%d)" % tunnels)
	# a tunnel straight off the entry is too near the start for anything to wait in (enemies keep 15 steps off)
	check(with >= tunnels / 2, "most tunnels hide one (%d of %d)" % [with, tunnels])


# ---------------------------------------------------------------- wading

## A hall with a deep sewage channel along y 5-6 and a dry ledge along y 4.
func _hall() -> void:
	var l := Level.new(22, 12)
	for y in range(1, 11):
		for x in range(1, 21):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	for x in range(1, 21):
		l.set_tile(Vector2i(x, 5), Level.Tile.DEEP)
		l.set_tile(Vector2i(x, 6), Level.Tile.DEEP)
	l.start = Vector2i(2, 8)
	l.rebuild_paths()
	game.clear_enemies()
	game.battle = null
	game.level = l
	game.view.show_level(l)
	Grounding.level = l
	Grounding.lights.clear()
	_put(MovementRules.centre(l.start))


func _put(p: Vector2) -> void:
	game.hero.place(MovementRules.cell_of(p))
	game.hero.glide_free(p, 0.0)
	game.hero_unit.pos = p
	game.path.clear()
	game._vel = Vector2.ZERO


func test_wading_through_sewage_is_slow_costly_loud_and_deep() -> void:
	_hall()
	check(game.level.is_walkable(Vector2i(5, 5)) and game.level.is_wet(Vector2i(5, 5)), "sewage can be waded")
	_put(MovementRules.centre(Vector2i(2, 5)))
	hold(game, ["move_right"], 0.5)
	var wet := game.hero.position.x - MovementRules.centre(Vector2i(2, 5)).x
	_put(MovementRules.centre(Vector2i(2, 8)))
	hold(game, ["move_right"], 0.5)
	var dry := game.hero.position.x - MovementRules.centre(Vector2i(2, 8)).x
	check(absf(wet / dry - MovementRules.DEEP_SLOW) < 0.05, "40%% of walking speed (%.1f vs %.1f px)" % [wet, dry])
	var pts: Array[Vector2] = [MovementRules.centre(Vector2i(6, 5))]
	check(absf(MovementRules.route_cost(game.level, MovementRules.centre(Vector2i(2, 5)), pts) - 4 * 1.5 * MovementRules.DEEP_COST) < 0.05, "in a fight every metre costs three")
	eq(StealthRules.noise_radius(false, true), StealthRules.NOISE_WALK * StealthRules.NOISE_WADE, "and splashing carries twice as far")
	_put(MovementRules.centre(Vector2i(4, 5)))
	eq(Grounding.wade_depth(game.hero.position), Grounding.DEEP_DEPTH, "he stands in it to the waist")


func test_going_down_in_sewage_drowns() -> void:
	_hall()
	var h := Bestiary.thomas_full()
	h.cell = Vector2i(4, 5)
	h.prone = true
	var m := Bestiary.drowned_miner()
	m.cell = Vector2i(15, 9)
	var b := Battle.new()
	b.setup(game.level, h, [m], 1)
	var before := h.stamina
	b.start(true)
	eq(h.stamina, before - Battle.DROWN_DAMAGE, "down in the sewage at the start of his turn, he drowns")


func test_pushed_off_the_ledge_goes_under() -> void:
	_hall()
	var h := Bestiary.thomas_full()
	h.cell = Vector2i(5, 3)
	var m := Bestiary.drowned_miner()
	m.cell = Vector2i(5, 4)   # on the ledge, the sewage behind it
	m.big = {}
	var b := Battle.new()
	b.setup(game.level, h, [m], 1)
	b.injuries_on = false
	b.start(true)
	b.forced_rolls = [[8, 8]]   # a strong Heavy Blow pushes 1
	b.hero_ability_on(0, m)
	eq(game.level.get_tile(m.cell), Level.Tile.DEEP, "knocked off the ledge into the sewage")
	check(m.prone, "and under it")


# ---------------------------------------------------------------- lurkers

func _lurker(c: Vector2i) -> Combatant:
	var l := game._add_enemy(Bestiary.lurker(), c)
	game.views[l].visible = false
	return l


func test_a_lurker_cannot_be_seen_and_does_not_watch() -> void:
	_hall()
	var l := _lurker(Vector2i(10, 5))
	check(not game.views[l].visible, "under the sewage, it can't be seen")
	_put(MovementRules.centre(Vector2i(10, 9)))
	game._check_spotted()
	check(not game.in_fight(), "and it doesn't start a fight by looking")


func test_creeping_close_spots_its_tell_and_lets_him_strike_first() -> void:
	_hall()
	var l := _lurker(Vector2i(10, 5))
	game.set_lantern("out")
	game.toggle_sneak()
	_put(MovementRules.centre(Vector2i(7, 7)))   # about 5.4 m off, a clear view
	run(game, StealthRules.LURKER_NOTICE_TIME + 0.2)
	check(l.noticed and game.views[l].visible, "crouched and watching, he spots it")
	check(not game.in_fight(), "and it hasn't stirred")
	game.creep_or_walk(game.views[l].position)
	run(game, 4.0)
	check(game.in_fight(), "creeping up and striking starts the fight")
	check(not game.hero_unit.surprised, "on his terms")


func test_walking_onto_an_unseen_lurker_it_strikes_first() -> void:
	_hall()
	var l := _lurker(Vector2i(10, 5))
	_put(MovementRules.centre(Vector2i(10, 7)) + Vector2(0, 8))   # just over 2 m off
	game.walk_to_point(MovementRules.centre(Vector2i(10, 6)))
	run(game, 2.0)
	check(game.in_fight(), "it rises as he comes close")
	check(game.views[l].visible, "out of the sewage")
	for i in 900:   # let the opening play out, where the log fills
		await tree.process_frame
		if not game.busy:
			break
	check(game.combat_hud.history.any(func(x): return x.contains("Caught unawares")), "he is caught unawares: it moves first")
	check(game.combat_hud.history.any(func(x): return x.contains("Drag Under") and x.contains("with an edge")), "and its grab comes with an edge (%s)" % [game.combat_hud.history])


func test_a_lurkers_grab_drags_him_under() -> void:
	_hall()
	var h := Bestiary.thomas_full()
	h.cell = Vector2i(10, 6)
	var l := Bestiary.lurker()
	l.cell = Vector2i(11, 6)
	l.state = "hunting"
	var b := Battle.new()
	b.setup(game.level, h, [l], 1)
	b.injuries_on = false
	b.forced_rolls = [[6, 6]]   # 12 + 2: a solid hit, 5 damage and dragged under
	var before := h.stamina
	var ev := b.start(false)
	check(ev.any(func(e): return e.t == "hit" and e.unit == h and e.dmg == 5), "Drag Under hits for 5")
	check(h.prone, "and pulls him down")
	eq(h.stamina, before - 5 - Battle.DROWN_DAMAGE, "and his turn starts under the sewage, drowning")
