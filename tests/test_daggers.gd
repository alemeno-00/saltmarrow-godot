extends TestBase
## The Shadow backstory and the Daggers tree (docs/trees.md, Daggers; design/quick-specs/sneaking-2026-10-30.md,
## part 2), with fixed dice: Agility, Stab and Twin Fangs, Backstab against the unaware, Open the Vein, Throw's reach,
## Killer's Eye, The Shadow's Due, Shadow's Resolve, choosing a backstory, and throwing a dagger outside a fight.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func _room() -> Level:
	var l := Level.new(12, 8)
	for y in range(1, 7):
		for x in range(1, 11):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.rebuild_paths()
	return l


## A Shadow with every working dagger skill, against `enemies`, his turn.
func _shadow_battle(enemies: Array, perks: Array[String] = []) -> Battle:
	var p := Progress.shadow()
	for n in ["open_the_vein", "throw"]:
		p.owned.append("daggers/" + n)
	var h := Bestiary.thomas(p)
	h.perks = perks
	h.cell = Vector2i(4, 3)
	var b := Battle.new()
	b.setup(_room(), h, enemies, 1)
	b.injuries_on = false
	b.start(true)
	return b


func _miner(c: Vector2i) -> Combatant:
	var m := Bestiary.drowned_miner()
	m.cell = c
	m.big = {}
	return m


func _index(b: Battle, id: String) -> int:
	for i in b.hero.abilities.size():
		if b.hero.abilities[i].id == id:
			return i
	return -1


func test_a_shadow_fights_with_daggers_and_agility() -> void:
	var p := Progress.shadow()
	eq(p.weapon_tree(), "daggers", "a Shadow's tree is Daggers")
	check(p.owns("daggers", "backstab") and p.owns("daggers", "twin_fangs"), "starting with Backstab and Twin Fangs")
	var h := Bestiary.thomas(p)
	eq(h.basic.id, "stab", "his basic attack is Stab")
	eq(h.agility, 2, "Agility 2")
	var m := _miner(Vector2i(5, 3))
	var b := _shadow_battle([m])
	b.forced_rolls = [[3, 3]]   # 6 + Agility 2 = 8: tier 1, 2 damage
	b.hero_ability_on(0, m)
	eq(m.stamina, 18, "Stab rolls with Agility: tier 1 does 2")


func test_twin_fangs_strikes_twice() -> void:
	var m := _miner(Vector2i(5, 3))
	var b := _shadow_battle([m], ["twin_fangs"] as Array[String])
	b.forced_rolls = [[6, 6]]   # 12 + 2 = 14: tier 2, 4 damage, and 2 from the off-hand
	b.hero_ability_on(0, m)
	eq(m.stamina, 20 - 4 - 2, "the off-hand blade follows for half")


func test_backstab_only_against_the_unaware() -> void:
	var m := _miner(Vector2i(5, 3))
	var b := _shadow_battle([m])
	b.hero.resolve = 5
	var i := _index(b, "backstab")
	b.hero_ability_on(i, m)
	eq(m.stamina, 20, "refused against a miner who saw him coming")
	m.surprised = true
	b.forced_rolls = [[8, 7]]   # 15 + Agility 2, +2 for the edge against the surprised: 19, tier 3, 11 damage
	b.hero_ability_on(i, m)
	eq(m.stamina, 9, "against one caught unaware, it lands for 11")


func test_open_the_vein_bleeds_four_a_turn() -> void:
	var m := _miner(Vector2i(5, 3))
	var b := _shadow_battle([m])
	b.hero.resolve = 5
	b.forced_rolls = [[6, 6]]   # tier 2: 4 damage and heavy bleeding
	b.hero_ability_on(_index(b, "open_the_vein"), m)
	eq(m.stamina, 16, "4 damage")
	check(m.bleeding and m.bleed == 4, "and bleeding 4 a turn")
	b.forced_rolls = [[1, 1], [1, 1]]
	b.hero_end_turn()
	eq(m.stamina, 12, "it loses 4 at the start of its turn")


func test_throw_reaches_five_squares_with_a_clear_line() -> void:
	var near := _miner(Vector2i(8, 3))   # 4 squares off
	var far := _miner(Vector2i(10, 6))   # 6 squares off
	var b := _shadow_battle([near, far])
	var ab: Dictionary = b.hero.abilities[_index(b, "throw")]
	var targets := b.valid_targets(b.hero, ab)
	check(targets.has(near), "a miner 4 squares off can be hit")
	check(not targets.has(far), "one 6 squares off can't")
	b.level.set_tile(Vector2i(6, 3), Level.Tile.WALL)
	check(not b.valid_targets(b.hero, ab).has(near), "nor one behind a wall")


func test_killers_eye_crits_on_seventeen() -> void:
	var m := _miner(Vector2i(5, 3))
	var b := _shadow_battle([m])
	b.forced_rolls = [[9, 8]]
	var ev := b.hero_ability_on(0, m)
	check(not ev.any(func(e): return e.t == "roll" and e.roll.crit), "a natural 17 is no crit without it")
	m.stamina = 20
	var b2 := _shadow_battle([m], ["killers_eye"] as Array[String])
	b2.forced_rolls = [[9, 8]]
	ev = b2.hero_ability_on(0, m)
	check(ev.any(func(e): return e.t == "roll" and e.roll.crit), "with Killer's Eye a dagger crits on 17")


func test_the_shadows_due_gives_resolve_on_a_crit() -> void:
	var m := _miner(Vector2i(5, 3))
	var b := _shadow_battle([m], ["shadows_due"] as Array[String])
	var before := b.hero.resolve
	b.forced_rolls = [[10, 10]]
	b.hero_ability_on(0, m)
	eq(b.hero.resolve, before + 1, "+1 Resolve for the crit")


func test_a_shadow_gains_resolve_striking_the_unaware_and_a_fury_when_hurt() -> void:
	var m := _miner(Vector2i(5, 3))
	m.surprised = true
	var b := _shadow_battle([m])
	var before := b.hero.resolve
	b.forced_rolls = [[3, 3], [3, 3]]
	b.hero_ability_on(0, m)
	eq(b.hero.resolve, before + 1, "striking an enemy that couldn't see him: +1")
	b._damage(b.hero, 3, false, 1)
	eq(b.hero.resolve, before + 1, "a Shadow gains nothing from being hurt")
	var f := Bestiary.thomas_full()
	f.cell = Vector2i(4, 3)
	var b2 := Battle.new()
	b2.setup(_room(), f, [_miner(Vector2i(5, 3))], 1)
	b2.start(true)
	var r := f.resolve
	b2._damage(f, 3, false, 1)
	eq(f.resolve, r + 1, "a Fury gains 1 when first hurt")


func test_each_new_life_asks_who_thomas_was() -> void:
	game.ask_backstory = true
	game.new_level(5)
	check(game.backstory_screen.visible and game.paused(), "a new life opens the choice, and the game waits")
	game.backstory_screen.choose("shadow")
	check(not game.paused(), "choosing closes it")
	eq(game.progress.backstory, "shadow", "this life is a Shadow")
	eq(game.hero_unit.basic.id, "stab", "fighting with daggers")
	game._descend()
	check(not game.backstory_screen.visible, "going deeper doesn't ask again")
	eq(game.progress.backstory, "shadow", "and he is still a Shadow")
	game.tree_screen.open(game.progress, true)
	eq(game.tree_screen.tree_id, "daggers", "his skill tree screen shows Daggers")
	game.tree_screen.visible = false


func _hall_with_lamp() -> void:
	var l := Level.new(22, 12)
	for y in range(1, 11):
		for x in range(1, 21):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.lights.append(Vector2i(6, 1))
	l.start = Vector2i(2, 5)
	l.rebuild_paths()
	game.clear_enemies()
	game.battle = null
	game.level = l
	game.view.show_level(l)
	game.lighting.build(l)
	game.hero.place(l.start)
	game.hero_unit.pos = game.hero.position
	game.progress.owned.append("daggers/throw")


func test_a_thrown_dagger_puts_out_a_lamp() -> void:
	_hall_with_lamp()
	game.douse_lantern()
	game.hero.glide_free(MovementRules.centre(Vector2i(6, 2)), 0.0)
	var lit := game.light_on_thomas()
	game.hero.glide_free(MovementRules.centre(Vector2i(2, 5)), 0.0)
	eq(game.throw_at(MovementRules.centre(Vector2i(6, 2))), "doused", "a dagger landing by the lamp puts it out")
	eq(game.lighting.light_count(), 0, "its light is gone")
	game.hero.glide_free(MovementRules.centre(Vector2i(6, 2)), 0.0)
	check(game.light_on_thomas() < lit - 0.5, "and where it lit him is dark now (%.2f, was %.2f)" % [game.light_on_thomas(), lit])


func test_a_clatter_draws_one_enemy_off_alone() -> void:
	_hall_with_lamp()
	var a := game._add_enemy(Bestiary.faithful(), Vector2i(10, 6))   # about 6 m from where it lands
	var b := game._add_enemy(Bestiary.faithful(), Vector2i(11, 8))   # about 7.5 m: it hears too
	eq(game.throw_at(MovementRules.centre(Vector2i(6, 7))), "clatter", "it clatters off the stone")
	var curious := [a, b].filter(func(e): return e.state == "suspicious")
	eq(curious.size(), 1, "exactly one of them comes to look")
	eq(curious[0], a, "the nearer one")
	eq(game.throw_at(MovementRules.centre(Vector2i(19, 9))), "too far", "and it can't be thrown further than 7.5 m")
