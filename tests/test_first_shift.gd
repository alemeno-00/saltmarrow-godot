extends TestBase
## The First Shift: Garrick, the Sewers boss, and the Outflow room.
## Spec: design/quick-specs/first-shift-boss-2026-10-29.md

var level: Level


## A 12 x 10 room with walls around it, a sluice gate in the top wall at x 3 and x 8,
## and a row of water along y 5. The room is the arena.
func _outflow() -> Level:
	var l := Level.new(12, 10)
	for y in range(1, 9):
		for x in range(1, 11):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	for x in range(1, 11):
		l.set_tile(Vector2i(x, 5), Level.Tile.WATER)
	l.outflow = Rect2i(1, 1, 10, 8)
	l.gates = [Vector2i(3, 0), Vector2i(8, 0)]
	for g in l.gates:
		l.set_tile(g, Level.Tile.GATE_OPEN)
	l.rebuild_paths()
	return l


func _battle(garrick_cell: Vector2i, hero_cell: Vector2i, arena := true) -> Battle:
	level = _outflow()
	var h := Bestiary.thomas_full()
	h.cell = hero_cell
	var g := Bestiary.garrick()
	g.cell = garrick_cell
	var b := Battle.new()
	b.setup(level, h, [g], 1)
	b.injuries_on = false
	if arena:
		b.arena = level.outflow
	return b


func _garrick(b: Battle) -> Combatant:
	return b.units[1]


func _water_count(l: Level) -> int:
	var n := 0
	for y in range(l.outflow.position.y, l.outflow.end.y):
		for x in range(l.outflow.position.x, l.outflow.end.x):
			if l.get_tile(Vector2i(x, y)) == Level.Tile.WATER:
				n += 1
	return n


func _exec_index(h: Combatant) -> int:
	for i in h.abilities.size():
		if h.abilities[i].id == "execution":
			return i
	return -1


# ---------------------------------------------------------------- the level

func test_bottom_level_has_the_outflow() -> void:
	var l := Level.new()
	l.generate(7, true)
	check(l.outflow.has_area(), "the deepest level has an Outflow room")
	eq(l.gates.size(), 2, "with two sluice gates")
	for g in l.gates:
		eq(l.get_tile(g), Level.Tile.GATE_OPEN, "each gate starts open")
	check(_water_count(l) > 0, "and water in the room")
	eq(l.stairs, Vector2i(-1, -1), "and no stairs down")
	var reach := l.reachable_from(l.start)
	check(reach.has(l.outflow.get_center()), "the Outflow can be reached from the start")


## The painted room (design/art-briefs/outflow/) only lines up if every Outflow has the blockout's layout.
func test_outflow_matches_the_blockout_on_every_seed() -> void:
	for seed in 40:
		var l := Level.new()
		l.generate(seed, true)
		var o := l.outflow
		eq(o.size, Vector2i(12, 9), "seed %d: 12 x 9 inside" % seed)
		eq(l.gates, [o.position + Vector2i(2, -1), o.position + Vector2i(9, -1)] as Array[Vector2i], "seed %d: gates on the blockout's red squares" % seed)
		eq(l.outflow_lanterns(), [o.position + Vector2i(0, -1), o.position + Vector2i(6, -1), o.position + Vector2i(11, -1)] as Array[Vector2i], "seed %d: lanterns on the yellow marks" % seed)
		var entrance: Array[Vector2i] = [o.position + Vector2i(-1, 1), o.position + Vector2i(-1, 2)]
		var ring := o.grow(1)
		var bad := 0
		for y in range(ring.position.y, ring.end.y):
			for x in range(ring.position.x, ring.end.x):
				var c := Vector2i(x, y)
				var t := l.get_tile(c)
				if o.has_point(c):
					var want := Level.Tile.WATER if y == o.position.y + 4 else Level.Tile.FLOOR
					if t != want:
						bad += 1
				elif entrance.has(c):
					if t != Level.Tile.FLOOR:
						bad += 1
				elif l.gates.has(c):
					if t != Level.Tile.GATE_OPEN:
						bad += 1
				elif t != Level.Tile.WALL:
					bad += 1
		eq(bad, 0, "seed %d: every square of the room and its walls matches the blockout" % seed)
		var reach := l.reachable_from(l.start)
		check(reach.has(o.get_center()), "seed %d: the Outflow can be reached" % seed)
		for r in l.rooms:
			check(reach.has(r.get_center()), "seed %d: every room can be reached" % seed)


func test_other_levels_have_stairs_and_no_outflow() -> void:
	var l := Level.new()
	l.generate(7)
	check(not l.outflow.has_area(), "no Outflow above the bottom")
	check(l.stairs != Vector2i(-1, -1), "stairs down as before")


# ---------------------------------------------------------------- Garrick

func test_garrick_never_flees() -> void:
	var b := _battle(Vector2i(5, 3), Vector2i(5, 2))
	var g := _garrick(b)
	g.stamina = 5
	b.start(false)
	check(not g.fleeing and not g.fled, "a solo stands and fights")


func test_execution_does_not_crush_him() -> void:
	var b := _battle(Vector2i(5, 3), Vector2i(5, 2))
	var g := _garrick(b)
	g.prone = true
	b.start(true)
	b.hero.resolve = 10
	b.forced_rolls = [[9, 9]]   # 18 + might: tier 3
	b.hero_ability(_exec_index(b.hero), g.cell)
	check(not g.dead and not g.crushed, "his skull holds")
	eq(g.stamina, g.max_stamina - 15, "Execution still does its 15")


func test_sweep_is_telegraphed_across_five_squares() -> void:
	var b := _battle(Vector2i(5, 3), Vector2i(5, 2))
	var g := _garrick(b)
	b.forced_rolls = [[5, 5]]   # his basic attack is not used: he winds up instead
	b.start(false)
	eq(g.telegraph.size(), 5, "five squares darken")
	for x in range(3, 8):
		check(g.telegraph.has(Vector2i(x, 2)), "square %d across Thomas is marked" % x)


func test_sweep_lands_on_everyone_still_there() -> void:
	var b := _battle(Vector2i(5, 3), Vector2i(5, 2))
	var g := _garrick(b)
	b.start(false)
	var before := b.hero.stamina
	b.forced_rolls = [[5, 5]]   # 10 + 3 = 13: tier 2, 12 damage
	b.hero_end_turn()
	eq(b.hero.stamina, before - 12, "the Sweep hits for 12")
	check(b.hero.prone, "and knocks Thomas down")
	check(g.telegraph.is_empty(), "the swing is spent")


func test_pushing_him_breaks_the_swing() -> void:
	var b := _battle(Vector2i(5, 4), Vector2i(5, 3))
	var g := _garrick(b)
	b.start(false)
	check(not g.telegraph.is_empty(), "he is winding up")
	b.forced_rolls = [[8, 8]]   # tier 3 Heavy Blow pushes
	b.hero_ability(0, g.cell)
	check(g.telegraph.is_empty(), "the push breaks the swing")


func test_sweep_comes_faster_when_he_is_hurt() -> void:
	var b := _battle(Vector2i(5, 3), Vector2i(5, 2))
	var g := _garrick(b)
	g.stamina = g.max_stamina / 2
	b.start(false)
	eq(g.big_cooldown, 2, "cooldown 2 at half Stamina")
	var b2 := _battle(Vector2i(5, 3), Vector2i(5, 2))
	b2.start(false)
	eq(_garrick(b2).big_cooldown, 3, "cooldown 3 when he is fresh")


func test_he_is_pushed_one_square_at_most_and_slams_daze_him() -> void:
	var b := _battle(Vector2i(5, 3), Vector2i(4, 3), false)
	var g := _garrick(b)
	b.hero.perks = ["weight_behind_it"]
	b.start(true)
	b.forced_rolls = [[8, 8]]   # tier 3 Heavy Blow: push 1, +1 from Weight Behind It
	b.hero_ability(0, g.cell)
	eq(g.cell, Vector2i(6, 3), "pushed just one square")
	g.dazed = 0
	g.cell = Vector2i(10, 3)
	b.hero.cell = Vector2i(9, 3)
	b.budget.main = 1
	b.forced_rolls = [[8, 8]]
	b.hero_ability(0, g.cell)
	check(g.dazed > 0, "slammed into the wall, he is dazed")


# ---------------------------------------------------------------- water and gates

func test_water_rises_while_a_gate_is_open() -> void:
	var b := _battle(Vector2i(2, 8), Vector2i(9, 8))
	b.start(true)
	var before := _water_count(level)
	b.hero_end_turn()
	check(_water_count(level) > before, "the water spreads")
	eq(level.get_tile(Vector2i(5, 4)), Level.Tile.WATER, "one square outward from the channel")
	eq(level.get_tile(Vector2i(5, 3)), Level.Tile.FLOOR, "but no further")


func test_water_stops_when_both_gates_are_shut() -> void:
	var b := _battle(Vector2i(2, 8), Vector2i(9, 8))
	for g in level.gates:
		level.set_tile(g, Level.Tile.GATE_SHUT)
	b.start(true)
	var before := _water_count(level)
	b.hero_end_turn()
	eq(_water_count(level), before, "no rise with both gates shut")


func test_water_stops_at_the_cap() -> void:
	var b := _battle(Vector2i(2, 8), Vector2i(9, 8))
	b.hero.max_stamina = 999
	b.hero.stamina = 999
	b.start(true)
	for i in 8:
		b.hero_end_turn()
	# rows 5, then 4 and 6, then 3 and 7: 50 of 80 squares, 62% and past the 60% cap, so it stops
	eq(_water_count(level), 50, "water stops once it passes the cap")
	eq(level.get_tile(Vector2i(5, 1)), Level.Tile.FLOOR, "dry ground remains")


func test_no_rise_away_from_the_arena() -> void:
	var b := _battle(Vector2i(2, 8), Vector2i(9, 8), false)
	b.start(true)
	var before := _water_count(level)
	b.hero_end_turn()
	eq(_water_count(level), before, "ordinary fights do not flood")


func test_thomas_can_shut_a_gate() -> void:
	var b := _battle(Vector2i(10, 8), Vector2i(3, 1))
	b.start(true)
	b.hero_shut_gate(Vector2i(3, 0))
	eq(level.get_tile(Vector2i(3, 0)), Level.Tile.GATE_SHUT, "the gate is shut")
	eq(b.budget.main, 0, "it takes his main action")


func test_garrick_reopens_a_gate_with_malice() -> void:
	var b := _battle(Vector2i(10, 8), Vector2i(1, 1))
	level.set_tile(Vector2i(3, 0), Level.Tile.GATE_SHUT)
	b.start(true)
	b.malice = Battle.SLUICE_COST
	b.hero_end_turn()
	eq(level.get_tile(Vector2i(3, 0)), Level.Tile.GATE_OPEN, "Open the Sluice")


func test_water_costs_thomas_two_squares() -> void:
	var b := _battle(Vector2i(10, 8), Vector2i(5, 4))
	b.start(true)
	var before: int = b.budget.move
	b.hero_step(Vector2i(0, 1))
	eq(b.hero.cell, Vector2i(5, 5), "he wades in")
	eq(b.budget.move, before - 2, "at the cost of two squares")


func test_garrick_ignores_water() -> void:
	var b := _battle(Vector2i(5, 7), Vector2i(5, 1))
	var g := _garrick(b)
	var prev := b.reachable(g, 4)
	check(prev.has(Vector2i(5, 3)), "four squares straight through the water")


func test_lying_in_water_drowns() -> void:
	var b := _battle(Vector2i(10, 8), Vector2i(5, 5))
	b.hero.prone = true
	var before := b.hero.stamina
	b.start(true)
	eq(b.hero.stamina, before - Battle.DROWN_DAMAGE, "2 damage for starting a turn prone in water")
