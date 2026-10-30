extends TestBase
## Sneaking (design/quick-specs/sneaking-2026-10-30.md): view cones, the spotting meter, light and the lantern,
## noise, suspicious enemies coming to look, and striking from the dark with a surprise round.

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


## A dark, empty hall (20 x 10) with no lamps, Thomas at its west end, his lantern out unless a test lights it.
func _hall() -> void:
	var l := Level.new(22, 12)
	for y in range(1, 11):
		for x in range(1, 21):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.start = Vector2i(2, 5)
	l.rebuild_paths()
	game.clear_enemies()
	game.level = l
	game.view.show_level(l)
	Grounding.level = l
	Grounding.lights.clear()
	_put(MovementRules.centre(l.start))
	game.sneaking = false
	game.set_lantern("out")


func _put(p: Vector2) -> void:
	game.hero.place(MovementRules.cell_of(p))
	game.hero.glide_free(p, 0.0)
	game.hero_unit.pos = p
	game.path.clear()
	game._vel = Vector2.ZERO


## A Faithful standing at `c`, looking along `look`, its head held still.
func _watcher(c: Vector2i, look: Vector2) -> Combatant:
	var f := game._add_enemy(Bestiary.faithful(), c)
	game.views[f].look = look.normalized()
	game._heads[f] = 9999.0
	return f


## Seconds until the fight starts while Thomas stands still (up to `limit`).
func _time_to_spot(limit: float) -> float:
	var t := 0.0
	while t < limit and not game.in_fight():
		game._process(1.0 / 60.0)
		t += 1.0 / 60.0
	return t


# ---------------------------------------------------------------- the rules on their own

func test_a_cone_in_front_and_a_small_circle_all_round() -> void:
	var at := Vector2(100, 100)
	check(StealthRules.in_view(at, Vector2.RIGHT, at + Vector2(150, 30)), "in front, a little to the side: seen")
	check(not StealthRules.in_view(at, Vector2.RIGHT, at + Vector2(-150, 0)), "behind: not seen")
	check(StealthRules.in_view(at, Vector2.RIGHT, at + Vector2(-30, 0)), "behind but within 2 m: noticed")
	check(StealthRules.in_view(at, Vector2.RIGHT, at + Vector2(-150, 0), true), "already after him: it looks all round")


func test_the_meter_fills_slower_far_dark_and_sneaking() -> void:
	eq(StealthRules.fill_time(1.0, 1.0, false), StealthRules.FILL_FAST, "right beside it: at once")
	var lit_near := StealthRules.fill_time(4.0, 1.0, false)
	var dark_far_sneaking := StealthRules.fill_time(10.0, 0.0, true)
	check(lit_near < 1.0, "near and lit: under a second (%.2f s)" % lit_near)
	check(absf(dark_far_sneaking - StealthRules.FILL_SLOW) < 0.3, "far, dark and sneaking: about %.0f s (%.2f s)" % [StealthRules.FILL_SLOW, dark_far_sneaking])
	check(StealthRules.fill_time(6.0, 0.0, false) > StealthRules.fill_time(6.0, 1.0, false), "the dark helps")
	check(StealthRules.fill_time(6.0, 0.5, true) > StealthRules.fill_time(6.0, 0.5, false), "sneaking helps")


func test_his_lantern_and_the_room_lights_light_him() -> void:
	var none: Array[Vector2] = []
	eq(StealthRules.light_at(Vector2.ZERO, none, "lit"), 1.0, "his lantern lit: fully lit")
	check(StealthRules.light_at(Vector2.ZERO, none, "shuttered") < 0.6, "shuttered: dim")
	eq(StealthRules.light_at(Vector2.ZERO, none, "out"), 0.0, "out, no lamps: black")
	var lamp: Array[Vector2] = [Vector2(20, 0)]
	check(StealthRules.light_at(Vector2.ZERO, lamp, "out") > 0.8, "his lantern out but under a lamp: lit anyway")


func test_footsteps_carry_and_walls_muffle() -> void:
	eq(StealthRules.noise_radius(false, false), StealthRules.NOISE_WALK, "walking: 4 m")
	eq(StealthRules.noise_radius(true, false), StealthRules.NOISE_SNEAK, "sneaking: 1 m")
	eq(StealthRules.noise_radius(false, true), StealthRules.NOISE_WALK * StealthRules.NOISE_WADE, "wading: twice as far")
	_hall()
	for y in range(1, 11):
		game.level.set_tile(Vector2i(10, y), Level.Tile.WALL)
	var a := MovementRules.centre(Vector2i(8, 5))
	var b := MovementRules.centre(Vector2i(12, 5))   # 6 m away through the wall
	check(not StealthRules.hears(game.level, a, b, 8.0), "8 m of noise is only 4 m through a wall: not heard at 6 m")
	check(StealthRules.hears(game.level, a, b, 13.0), "a louder one is")


# ---------------------------------------------------------------- in the game

func test_behind_its_back_it_never_sees_him() -> void:
	_hall()
	game.set_lantern("lit")
	_watcher(Vector2i(8, 5), Vector2.RIGHT)   # 9 m east of him, looking further east
	check(_time_to_spot(3.0) >= 3.0, "three seconds standing in the light behind it: no fight")


func test_facing_him_in_the_light_it_spots_him_fast() -> void:
	_hall()
	game.set_lantern("lit")
	_watcher(Vector2i(5, 5), Vector2.LEFT)   # 4.5 m away
	var t := _time_to_spot(5.0)
	check(t < 1.2, "looking straight at him, lantern lit, 4.5 m off: spotted in %.2f s" % t)


func test_sneaking_in_the_dark_takes_much_longer() -> void:
	_hall()
	_watcher(Vector2i(8, 5), Vector2.LEFT)
	game.toggle_sneak()
	var dark := _time_to_spot(10.0)
	_hall()
	game.set_lantern("lit")
	_watcher(Vector2i(8, 5), Vector2.LEFT)
	var lit := _time_to_spot(10.0)
	check(dark > lit * 2.5, "crouched with his lantern out he lasts far longer in its view (%.2f s vs %.2f s)" % [dark, lit])


func test_half_seen_it_comes_to_look_then_goes_back() -> void:
	_hall()
	var f := _watcher(Vector2i(14, 5), Vector2.LEFT)
	f.alert = StealthRules.SUSPICIOUS_AT + 0.01
	game._become_suspicious(f, Vector2i(9, 5))
	eq(f.state, "suspicious", "it stops and stares")
	_put(MovementRules.centre(Vector2i(2, 1)))   # Thomas slips out of its view
	game.views[f].look = Vector2.LEFT
	run(game, StealthRules.SUSPICIOUS_WAIT + 0.2)
	eq(f.state, "investigating", "then goes to look")
	run(game, 6.0)
	check(f.cell.x <= 10, "it walked to where it saw him (now at %s)" % f.cell)
	run(game, StealthRules.SEARCH_LOOK + 1.0)
	eq(f.state, "idle", "found nothing, it settles again")
	check(not game.in_fight(), "and no fight")


func test_walking_close_behind_it_is_heard_but_sneaking_is_not() -> void:
	_hall()
	var f := _watcher(Vector2i(6, 5), Vector2.RIGHT)   # looking away from him
	_put(MovementRules.centre(Vector2i(4, 5)) + Vector2(-20, 0))
	game.toggle_sneak()
	hold(game, ["move_right"], 0.4)
	eq(f.state, "idle", "crept up behind it unheard")
	game.toggle_sneak()
	hold(game, ["move_right"], 0.15)
	check(f.state == "suspicious" or game.in_fight(), "walking, it hears him and turns")


func test_the_lantern_shutters_goes_out_and_takes_time_to_light() -> void:
	_hall()
	game.set_lantern("lit")
	var full := game.hero_lantern.texture_scale
	game.shutter_lantern()
	eq(game.lantern, "shuttered", "L shutters it")
	check(game.hero_lantern.texture_scale < full and game.hero_lantern.enabled, "a smaller pool, still lit")
	game.douse_lantern()
	check(not game.hero_lantern.enabled, "O puts it out")
	game.shutter_lantern()
	var from := game.hero.position
	hold(game, ["move_right"], StealthRules.RELIGHT_TIME * 0.5)
	eq(game.lantern, "out", "striking a light takes a moment")
	check(game.hero.position.distance_to(from) < 0.5, "and he stands still while he does it")
	run(game, StealthRules.RELIGHT_TIME * 0.6)
	eq(game.lantern, "lit", "then it catches")


func test_striking_from_the_dark_gives_a_surprise_round() -> void:
	_hall()
	game.toggle_sneak()
	var f := _watcher(Vector2i(6, 5), Vector2.RIGHT)
	var g := _watcher(Vector2i(7, 7), Vector2.RIGHT)
	game.creep_or_walk(game.views[f].position)
	run(game, 4.0)
	check(game.in_fight(), "creeping up and striking starts the fight")
	check(f.surprised or f.dead, "the one he struck was caught unaware")
	check(game.battle.units.has(g) and g.surprised, "and so was its companion, who hadn't seen him either")
	for i in 600:   # let the opening play out on screen, where the log fills
		await tree.process_frame
		if not game.busy:
			break
	check(game.combat_hud.history.any(func(l): return l.contains("strikes from the dark")), "the log says so")
	check(game.combat_hud.history.any(func(l): return l.contains("with an edge")), "his first blow lands with an edge")


func test_surprised_enemies_give_no_free_strike_and_it_wears_off() -> void:
	var l := Level.new(10, 8)
	for y in range(1, 7):
		for x in range(1, 9):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.rebuild_paths()
	var h := Bestiary.thomas_full()
	h.cell = Vector2i(4, 3)
	var m := Bestiary.drowned_miner()
	m.cell = Vector2i(5, 3)
	m.surprised = true
	var b := Battle.new()
	b.setup(l, h, [m], 1)
	b.injuries_on = false
	b.start(true)
	b.hero_move_to(Vector2i(2, 3))
	eq(h.stamina, 24, "walking away from a surprised miner draws no free strike")
	b.forced_rolls = [[1, 1], [1, 1], [1, 1]]
	b.hero_end_turn()
	check(not m.surprised, "the surprise is over after the first round")
