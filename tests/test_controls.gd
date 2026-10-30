extends TestBase
## Mouse-first controls, as in Baldur's Gate 3: left-click does the obvious thing (walk, strike from the dark, search a
## crate, turn the valve), right-click lists everything that can be done with what is under the mouse, and the belt's
## slots can be clicked.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func _labels(opts: Array) -> Array:
	return opts.map(func(o): return o[0])


func _pick(opts: Array, label: String) -> Callable:
	for o in opts:
		if o[0] == label:
			return o[1]
	return Callable()


## A cache to walk to, with the enemies cleared so nothing stops him on the way.
func _a_cache() -> Vector2i:
	for e in game.enemies:
		e.dead = true
	return game.level.caches.keys().filter(func(k): return not game.level.caches[k].get("drowned", false))[0]


func test_right_click_on_thomas_offers_crouching_the_lantern_and_the_belt() -> void:
	game.progress.belt.assign(["salve"])
	var labels := _labels(game.context_options(game.hero.position))
	check(labels.has("Crouch and sneak"), "crouch")
	check(labels.has("Shutter the lantern") and labels.has("Put the lantern out"), "the lantern")
	check(labels.has("Use the salve"), "and what is on the belt (%s)" % [labels])
	_pick(game.context_options(game.hero.position), "Put the lantern out").call()
	eq(game.lantern, "out", "choosing one does it")
	check(_labels(game.context_options(game.hero.position)).has("Light the lantern"), "and the menu changes to match")


func test_right_click_on_a_crate_walks_up_and_searches_it() -> void:
	var c := _a_cache()
	var opts := game.context_options(MovementRules.centre(c))
	var label: String = _labels(opts).filter(func(l): return l.begins_with("Search"))[0]
	_pick(opts, label).call()
	run(game, 20.0)
	check(game.level.caches[c].opened, "he walked over and searched it")
	eq(game.progress.belt.size(), 1, "its item is on the belt")


func test_left_click_on_a_crate_does_the_same() -> void:
	var c := _a_cache()
	game.creep_or_walk(MovementRules.centre(c))
	run(game, 20.0)
	check(game.level.caches[c].opened, "clicking a crate walks over and searches it")


func test_right_click_on_the_floor_walks_or_sneaks() -> void:
	var p := game.hero.position + Vector2(48, 0)
	var labels := _labels(game.context_options(p))
	check(labels.has("Walk here") and labels.has("Sneak here"), "walk or sneak (%s)" % [labels])
	_pick(game.context_options(p), "Sneak here").call()
	check(game.sneaking and not game.path.is_empty(), "sneaking there crouches him and sets off")


func test_right_click_on_an_enemy_offers_striking_from_the_dark() -> void:
	var e: Combatant = game.enemies.filter(func(x): return x.state == "idle")[0]
	check(_labels(game.context_options(game.views[e].position)).has("Strike from the dark"), "an unaware enemy can be ambushed")


func test_in_a_fight_right_click_lists_abilities_and_actions() -> void:
	var e: Combatant = game.enemies.filter(func(x): return x.state == "idle")[0]
	game.views[e].face_point(game.hero.position)
	game.hero.glide_free(game.views[e].position + Vector2(40, 0), 0.0)
	game.hero_unit.pos = game.hero.position
	game._start_battle(e)   # struck from the dark: his turn first
	for i in 600:
		await tree.process_frame
		if not game.busy:
			break
	check(game._can_act(), "it's his turn")
	var foe: Combatant = game.battle.enemies_of(game.hero_unit)[0]   # one still standing after his opening blow
	var on_enemy := _labels(game.context_options(foe.pos))
	check(on_enemy.any(func(l): return l.begins_with("Heavy Blow")), "on an enemy: his abilities (%s)" % [on_enemy])
	var greyed: Array = game.context_options(foe.pos).filter(func(o): return o.size() > 2 and o[2])
	check(not greyed.is_empty() and String(greyed[0][0]).contains("no main action"), "his opening blow used his main action, so they show greyed with the reason (%s)" % [_labels(greyed)])
	var on_self := _labels(game.context_options(game.hero_unit.pos))
	check(on_self.has("End the turn") and on_self.has("Catch your breath (main action)"), "on himself: his actions (%s)" % [on_self])
	check(_labels(game.context_options(game.hero_unit.pos + Vector2(60, 0))).has("Move here"), "on the floor: move")


func test_the_belt_slots_can_be_clicked() -> void:
	game.progress.belt.assign(["salve"])
	game.hero_unit.stamina = 3
	game.combat_hud.belt_pressed.emit(0)
	eq(game.hero_unit.stamina, 3 + Items.SALVE_HEAL, "clicking the salve's slot uses it")
