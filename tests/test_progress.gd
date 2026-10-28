extends TestBase
## Growth: experience and levels, weapon mastery, the Maces tree, and the passives in a fight.


func test_fury_starts_with_two_mace_skills() -> void:
	var p := Progress.fury()
	check(p.owns("maces", "skull_crack") and p.owns("maces", "weight_behind_it"), "Skull Crack and Weight Behind It")
	var t := Bestiary.thomas(p)
	eq(t.abilities.size(), 2, "Heavy Blow and Skull Crack")
	check(t.perks.has("weight_behind_it"), "the passive is on")


func test_levels() -> void:
	var p := Progress.fury()
	eq(p.xp_needed(), 5, "level 2 at 5 experience")
	eq(p.add_xp(4), 0, "4 is not enough")
	eq(p.add_xp(1), 1, "5 is")
	eq(p.level, 2, "level 2")
	eq(p.level_points, 1, "with a level point")
	eq(p.max_stamina(), 27, "and 3 more Stamina")
	p.add_xp(10)
	eq(p.level, 3, "level 3 at 15")
	eq(p.stat_points, 1, "a stat point every third level")
	check(p.raise_stat("might") and int(p.stats.might) == 3, "spent on Might")


func test_mastery_from_hits() -> void:
	var p := Progress.fury()
	for i in Progress.HITS_PER_POINT - 1:
		eq(p.add_hit("maces"), "", "no point yet")
	eq(p.add_hit("maces"), "point", "a point every %d hits" % Progress.HITS_PER_POINT)
	eq(p.points_for("maces"), 1, "one mace mastery point")


func test_closed_tree_opens_by_use() -> void:
	var p := Progress.fury()
	for i in Progress.OPEN_AT - 1:
		p.add_hit("swords")
	check(not p.open_trees.has("swords"), "not yet")
	eq(p.add_hit("swords"), "opened", "opens after %d hits" % Progress.OPEN_AT)


func test_learning_follows_the_links() -> void:
	var p := Progress.fury()
	p.mastery["maces"] = 5
	check(p.cannot_take("maces", "execution") != "", "can't jump to row 4")
	check(p.cannot_take("maces", "shatter") != "", "Shatter isn't in the game yet")
	check(p.take("maces", "knee_breaker"), "Knee Breaker links from row 1")
	check(p.take("maces", "wide_arc"), "Wide Arc links from Knee Breaker")
	check(p.take("maces", "execution"), "Execution links from Wide Arc")
	eq(p.points_for("maces"), 2, "three points spent")
	var names := Bestiary.thomas(p).abilities.map(func(a): return a.id)
	eq(names, ["heavy_blow", "skull_crack", "knee_breaker", "wide_arc", "execution"], "abilities in tree order")


func _fight(perks: Array[String], enemy_cell: Vector2i) -> Battle:
	var l := Level.new(10, 8)
	for y in range(1, 7):
		for x in range(1, 9):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.rebuild_paths()
	var h := Bestiary.thomas_full()
	h.perks = perks
	h.cell = Vector2i(4, 3)
	var m := Bestiary.drowned_miner()
	m.cell = enemy_cell
	var b := Battle.new()
	b.setup(l, h, [m], 1)
	b.injuries_on = false
	b.start(true)
	return b


func test_weight_behind_it() -> void:
	var b := _fight(["weight_behind_it"] as Array[String], Vector2i(5, 3))
	var m: Combatant = b.units[1]
	b.forced_rolls = [[6, 6]]   # 14, a solid Heavy Blow: now pushes 1 + 1
	b.hero_ability(0, m.cell)
	eq(m.cell, Vector2i(7, 3), "pushed two squares")
	var b2 := _fight(["weight_behind_it"] as Array[String], Vector2i(7, 3))
	b2.hero.cell = Vector2i(6, 3)
	var m2: Combatant = b2.units[1]
	b2.forced_rolls = [[6, 6]]
	b2.hero_ability(0, m2.cell)
	eq(m2.stamina, 20 - 5 - 1 - 2, "the wall hurts more: 1 per square left, plus 2")


func test_ringing_blows() -> void:
	var b := _fight(["ringing_blows"] as Array[String], Vector2i(5, 3))
	var m: Combatant = b.units[1]
	m.dazed = 1
	b.forced_rolls = [[5, 4]]   # 9 + 2 might = 11, plus the edge = 13: solid
	var ev := b.hero_ability(0, m.cell)
	var edges := 0
	for e in ev:
		if e.t == "roll":
			edges = e.roll.edges
	eq(edges, 1, "an edge against the dazed miner")
	eq(m.stamina, 15, "a solid hit")


func test_landed_hits_are_reported() -> void:
	var b := _fight([] as Array[String], Vector2i(5, 3))
	var m: Combatant = b.units[1]
	b.forced_rolls = [[3, 3]]
	var ev := b.hero_ability(0, m.cell)
	check(ev.any(func(e): return e.t == "landed" and e.weapon == "mace"), "a mace hit counts toward mastery")


func test_stairs_exist_and_can_be_walked_on() -> void:
	var l := Level.new()
	l.generate(5)
	check(l.stairs.x >= 0, "the level has stairs down")
	check(l.is_walkable(l.stairs), "you can walk onto them")
	check(l.reachable_from(l.start).has(l.stairs), "and reach them from the start")
