extends TestBase
## The fight rules, with fixed dice so every result is known. Distances are in metres (one square is 1.5 m);
## creatures are placed in the middle of squares so the old square-by-square cases still hold.

var level: Level


## An empty 10 x 8 room with walls around it.
func _room() -> Level:
	var l := Level.new(10, 8)
	for y in range(1, 7):
		for x in range(1, 9):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.rebuild_paths()
	return l


func _battle(enemies: Array, hero_cell := Vector2i(4, 3)) -> Battle:
	level = _room()
	var h := Bestiary.thomas_full()
	h.cell = hero_cell
	var b := Battle.new()
	b.setup(level, h, enemies, 1)
	b.injuries_on = false
	return b


func _at(c: Combatant, cell: Vector2i) -> Combatant:
	c.cell = cell
	return c


func _has(events: Array, t: String) -> bool:
	for e in events:
		if e.t == t:
			return true
	return false


func test_thomas_gains_resolve_each_turn() -> void:
	var b := _battle([_at(Bestiary.drowned_miner(), Vector2i(8, 6))])
	b.start(true)
	eq(b.hero.resolve, 2, "2 Resolve at the start of his turn")
	check(b.is_hero_turn(), "it is Thomas's turn")


func test_heavy_blow_tiers() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.forced_rolls = [[3, 3]]   # 6 + 2 = 8, tier 1
	b.hero_ability(0, m.cell)
	eq(m.stamina, 18, "tier 1 Heavy Blow does 2")
	eq(b.budget.main, 0, "the main action is spent")


func test_strong_heavy_blow_pushes_and_slams() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(8, 3))
	var b := _battle([m], Vector2i(7, 3))
	b.start(true)
	b.forced_rolls = [[8, 8]]   # 18, tier 3: 7 damage, push 1 into the wall
	var ev := b.hero_ability(0, m.cell)
	eq(m.cell, Vector2i(8, 3), "a wall stops the push")
	eq(m.stamina, 20 - 7 - 1, "7 from the blow and 1 from the wall")
	check(_has(ev, "slam"), "a slam event plays")


func test_push_moves_the_target() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.forced_rolls = [[8, 8]]
	b.hero_ability(0, m.cell)
	eq(m.cell, Vector2i(6, 3), "pushed one square straight away")


func test_resolve_costs_and_limits() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	var ev := b.hero_ability(1, m.cell)   # Skull Crack costs 3, he has 2
	eq(m.stamina, 20, "not enough Resolve, nothing happens")
	check(_has(ev, "log"), "and it says why")
	b.hero.resolve = 5
	b.forced_rolls = [[6, 6]]   # 14, tier 2: 5 damage and dazed
	b.hero_ability(1, m.cell)
	eq(b.hero.resolve, 2, "Skull Crack spent 3")
	eq(m.stamina, 15, "5 damage")
	check(m.dazed > 0, "and dazed")


func test_dazed_enemy_only_gets_one_action() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(7, 3))
	var b := _battle([m])
	b.start(true)
	m.dazed = 1
	b.forced_rolls = [[5, 5]]
	b.hero_end_turn()
	eq(Battle.dist(m.cell, b.hero.cell), 1, "the dazed miner walked up to Thomas")
	eq(b.hero.stamina, 24, "but could not attack in the same turn")
	eq(m.dazed, 0, "and the daze wore off at the end of its turn")


func test_knee_breaker_puts_down_and_breaks_the_wind_up() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	m.telegraph = b.band(m)
	b.hero.resolve = 3
	b.forced_rolls = [[9, 8]]   # 19 is natural 17 + 2: tier 3, prone
	b.hero_ability(2, m.cell)
	check(m.prone, "knocked prone")
	check(m.telegraph.is_empty(), "the big swing is cancelled")


func test_free_strike_when_walking_away() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.hero_move_to(Vector2i(2, 3))
	eq(b.hero.stamina, 24 - 3, "the miner's free strike lands as he leaves")
	eq(b.hero.cell, Vector2i(2, 3), "and he still gets away")
	check(absf(b.budget.move - 4.5) < 0.01, "3 m of his 7.5 m used (%.2f left)" % b.budget.move)


func test_moving_around_an_enemy_is_free() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.hero_move_to(Vector2i(4, 4))
	eq(b.hero.stamina, 24, "staying next to it gives no free strike")


func test_telegraphed_smash_hits_only_marked_squares() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.forced_rolls = [[1, 1]]
	b.hero_end_turn()   # the miner, next to him, raises its pick
	check(not m.telegraph.is_empty(), "the miner winds up")
	check(Battle.in_band(m.telegraph, b.hero.pos), "aimed where Thomas stands")
	b.hero_move_to(Vector2i(4, 5))   # step out of the marked squares (taking a free strike)
	var before := b.hero.stamina
	b.forced_rolls = [[9, 9]]
	b.hero_end_turn()
	eq(b.hero.stamina, before, "the smash lands on empty stone")
	check(m.telegraph.is_empty(), "the wind-up is spent")


func test_smash_lands_if_he_stays() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.hero_end_turn()
	b.forced_rolls = [[6, 6]]   # 14: tier 2, 9 damage and prone
	b.hero_end_turn()
	eq(b.hero.stamina, 24 - 9, "the smash hits for 9")
	check(b.hero.prone, "and knocks him down")


func test_minion_damage_carries_over() -> void:
	var a := _at(Bestiary.faithful(), Vector2i(5, 3))
	var c := _at(Bestiary.faithful(), Vector2i(6, 3))
	var b := _battle([a, c])
	b.start(true)
	b.forced_rolls = [[5, 5]]   # 12: tier 2, 5 damage; 4 kills, 1 carries on
	b.hero_ability(0, a.cell)
	check(a.dead, "the first Faithful dies")
	eq(c.stamina, 3, "the extra damage carries into the one beside it")


func test_wide_arc_hits_everyone_adjacent() -> void:
	var a := _at(Bestiary.faithful(), Vector2i(5, 3))
	var c := _at(Bestiary.faithful(), Vector2i(3, 3))
	var far := _at(Bestiary.faithful(), Vector2i(8, 6))
	var b := _battle([a, c, far])
	b.start(true)
	b.hero.resolve = 5
	b.forced_rolls = [[5, 5]]   # 12: tier 2, 5 damage
	b.hero_ability(3, Vector2i.ZERO)
	check(a.dead and c.dead, "both neighbours die")
	check(far.alive(), "the far one is untouched")


func test_execution_needs_a_set_up_target() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.hero.resolve = 7
	b.hero_ability(4, m.cell)
	eq(b.hero.resolve, 7, "refused against a healthy, standing enemy")
	m.prone = true
	b.forced_rolls = [[8, 8]]   # 16 + 2 + edge vs prone = 20: tier 3, skull crushed
	b.hero_ability(4, m.cell)
	check(m.dead and m.crushed, "the skull is crushed")
	check(b.over and b.winner == "hero", "the fight is won")


func test_crit_gives_another_main_action() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.forced_rolls = [[10, 10]]
	b.hero_ability(0, m.cell)
	eq(b.budget.main, 1, "a crit gives another main action")


func test_dying_then_dead() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b._damage(b.hero, 24, false, 1)
	check(b.hero.dying and not b.hero.dead, "at 0 Stamina he is dying, not dead")
	b.hero_catch_breath()
	check(not b.hero.dying, "catching his breath brings him back")
	b._damage(b.hero, 30, false, 1)
	check(b.hero.dead and b.over and b.winner == "enemies", "far enough below 0, he dies")


func test_enemies_walk_up_and_attack() -> void:
	var f := _at(Bestiary.faithful(), Vector2i(8, 3))
	var b := _battle([f])
	b.start(true)
	b.forced_rolls = [[6, 6]]   # 13: tier 2, 2 damage
	b.hero_end_turn()
	eq(Battle.dist(f.cell, b.hero.cell), 1, "the Faithful closes in")
	eq(b.hero.stamina, 22, "and claws him")
	check(b.is_hero_turn(), "then it is Thomas's turn again")
	eq(b.round, 2, "round two")


func test_line_of_sight() -> void:
	var l := _room()
	check(l.line_of_sight(Vector2i(1, 1), Vector2i(8, 6)), "an open room has sight across it")
	l.set_tile(Vector2i(4, 3), Level.Tile.WALL)
	check(not l.line_of_sight(Vector2i(2, 3), Vector2i(7, 3)), "a wall blocks sight")


func test_malice_grows_each_round() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(8, 6))
	var b := _battle([m])
	b.start(true)
	eq(b.malice, 1, "the enemy side starts with 1 Malice")
	b.forced_rolls = [[1, 1], [1, 1], [1, 1]]
	b.hero_end_turn()
	eq(b.malice, 2, "round 1: +1")
	b.hero_end_turn()
	check(b.malice >= 3, "and it keeps growing (spending aside)")


func test_swarming_hymn_moves_the_faithful() -> void:
	var a := _at(Bestiary.faithful(), Vector2i(8, 1))
	var c := _at(Bestiary.faithful(), Vector2i(8, 6))
	var b := _battle([a, c], Vector2i(1, 3))
	b.start(true)
	b.malice = 3   # +1 at the start of their turn makes 4, enough for the Hymn
	var ev := b.hero_end_turn()
	var spent := false
	for e in ev:
		if e.t == "malice_spend" and e.name == "Swarming Hymn":
			spent = true
	check(spent, "the Hymn is spent")
	# each Faithful moved 2 (hymn) + 5 (its own turn) toward Thomas; both started 7 away
	eq(Battle.dist(a.cell, b.hero.cell), 1, "the first one reached him")
	eq(Battle.dist(c.cell, b.hero.cell), 1, "and so did the second")


func test_flanking_gives_an_edge() -> void:
	var a := _at(Bestiary.faithful(), Vector2i(3, 3))
	var c := _at(Bestiary.faithful(), Vector2i(5, 3))
	var b := _battle([a, c])
	b.start(true)
	b.forced_rolls = [[4, 4], [4, 4]]
	var ev := b.hero_end_turn()
	var edges: Array = []
	for e in ev:
		if e.t == "roll":
			edges.append(e.roll.edges)
	eq(edges, [1, 1], "both attack with an edge, being on opposite sides of him")


func test_press_the_attack() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	m.big = {}
	var b := _battle([m])
	b.start(true)
	b.malice = 10
	b.forced_rolls = [[3, 3], [3, 3]]
	b.hero_end_turn()
	eq(b.hero.stamina, 24 - 3 - 3, "the miner strikes twice")


func test_badly_hurt_miner_runs_and_escapes() -> void:
	level = Level.new(30, 5)
	for x in range(1, 29):
		level.set_tile(Vector2i(x, 2), Level.Tile.FLOOR)
	level.rebuild_paths()
	var h := Bestiary.thomas_full()
	h.cell = Vector2i(2, 2)
	var m := _at(Bestiary.drowned_miner(), Vector2i(4, 2))
	m.stamina = 5
	var b := Battle.new()
	b.setup(level, h, [m], 1)
	b.injuries_on = false
	b.start(true)
	b.hero_end_turn()
	check(m.fled_once, "it broke and ran")
	b.hero_end_turn()
	b.hero_end_turn()
	check(m.fled, "far enough down the tunnel, it escapes")
	check(b.over and b.winner == "hero", "and the fight ends")


func test_losing_them_ends_the_fight() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(8, 3))
	var b := _battle([m], Vector2i(2, 3))
	for y in range(1, 7):
		level.set_tile(Vector2i(5, y), Level.Tile.WALL)   # a solid wall: no way through, no sight
	level.rebuild_paths()
	b.start(true)
	b.hero_end_turn()
	check(not b.over, "one round out of sight isn't enough")
	b.hero_end_turn()
	check(b.over and b.winner == "escaped", "two in a row, and Thomas has lost them")


func test_careful_step_draws_no_free_strike() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var b := _battle([m])
	b.start(true)
	b.hero_shift(Vector2i(3, 3))
	eq(b.hero.cell, Vector2i(3, 3), "stepped away")
	eq(b.hero.stamina, 24, "with no free strike")
	eq(b.budget.maneuver, 0, "it used the maneuver")
	eq(b.budget.move, 7.5, "and none of his movement")


func test_bystanders_join_when_they_see_him() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	var far := _at(Bestiary.faithful(), Vector2i(8, 6))
	var b := _battle([m])
	b.bystanders = [far] as Array[Combatant]
	b.start(true)
	b.forced_rolls = [[1, 1], [1, 1]]
	b.hero_end_turn()
	check(b.units.has(far), "the Faithful across the room sees the fight and joins")


func test_he_can_stop_anywhere_not_just_on_squares() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(8, 6))
	var b := _battle([m])
	b.start(true)
	var spot := Vector2(150.0, 120.0)   # part-way across a square
	b.hero_move_to_point(spot)
	check(b.hero.pos.distance_to(spot) < 0.5, "he stands exactly where he was sent (%s)" % b.hero.pos)
	check(absf(b.budget.move - (7.5 - MovementRules.metres(Vector2(144, 112).distance_to(spot)))) < 0.05, "and paid for exactly that distance")


func test_movement_runs_out_part_way() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(8, 6))
	var b := _battle([m], Vector2i(1, 1))
	b.start(true)
	b.hero_move_to(Vector2i(8, 1))   # 10.5 m away, he has 7.5 m
	check(absf(MovementRules.metres(b.hero.pos.x - 48.0) - 7.5) < 0.1, "he walks his 7.5 m and stops (%.2f m)" % MovementRules.metres(b.hero.pos.x - 48.0))
	check(b.budget.move < 0.05, "with nothing left")


func test_routes_go_round_bodies() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(5, 3))
	m.dazed = 1   # no free strike, so only the route is tested
	var b := _battle([m], Vector2i(3, 3))
	b.start(true)
	var pv := b.move_preview(MovementRules.centre(Vector2i(7, 3)))
	check(pv.points.size() >= 2, "the straight way is blocked by the miner, so the route bends")
	check(pv.cost > 6.0 and pv.cost < 7.5, "a little longer than the 6 m straight line (%.2f m)" % pv.cost)
	b.hero_move_to(Vector2i(7, 3))
	eq(b.hero.cell, Vector2i(7, 3), "and he gets round")


func test_reach_is_measured_between_bodies() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(6, 3))
	var b := _battle([m], Vector2i(4, 3))
	b.start(true)
	check(not Battle.in_reach(b.hero, m), "two squares apart is out of reach")
	m.pos.x -= 20.0
	check(Battle.in_reach(b.hero, m), "close the gap to under 1.5 m between their bodies and it is in reach")


func test_clicking_a_far_enemy_walks_up_and_strikes() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(7, 3))
	var b := _battle([m], Vector2i(3, 3))
	b.start(true)
	b.forced_rolls = [[3, 3]]
	var ev := b.hero_close_and_strike(0, m)
	check(_has(ev, "move") and _has(ev, "roll"), "he walks up and swings")
	check(Battle.in_reach(b.hero, m), "ending in reach")
	eq(m.stamina, 18, "and the blow lands")


func test_keys_move_him_smoothly_in_a_fight() -> void:
	var m := _at(Bestiary.drowned_miner(), Vector2i(8, 6))
	var b := _battle([m])
	b.start(true)
	var from := b.hero.pos
	for i in 30:   # half a second of holding a key at 60 frames a second
		b.hero_nudge(b.hero.pos + Vector2(1.0, 0.0) * MovementRules.px(MovementRules.WALK_SPEED) / 60.0)
	var moved := b.hero.pos.x - from.x
	check(absf(MovementRules.metres(moved) - MovementRules.WALK_SPEED * 0.5) < 0.05, "he glides 1.75 m, not a square at a time (%.2f m)" % MovementRules.metres(moved))
	check(absf(b.budget.move - (7.5 - MovementRules.metres(moved))) < 0.02, "and pays for exactly that")
