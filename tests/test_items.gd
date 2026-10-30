extends TestBase
## Room contents parts 3 and 4 (design/quick-specs/room-contents-2026-10-30.md): caches to search, the 4-slot belt,
## salves and bandages, and one puzzle per level (a locked grate with its key, or a sluice valve that drains a basin).

const SEEDS := 60

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


## The first life seed whose first level has this puzzle.
func _seed_with(puzzle: String) -> int:
	for s in range(1, 200):
		var l := Level.new()
		l.generate(s)
		if (puzzle == "grate" and not l.grate.is_empty()) or (puzzle == "valve" and l.valve.x >= 0):
			return s
	return -1


func _stand_by(c: Vector2i) -> void:
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		if game.level.is_walkable(c + d):
			game.hero.place(c + d)
			game.hero.glide_free(MovementRules.centre(c + d), 0.0)
			game.hero_unit.pos = game.hero.position
			return


# ---------------------------------------------------------------- placement

func test_every_level_has_caches_and_one_puzzle() -> void:
	var puzzles := 0
	for s in SEEDS:
		var l := Level.new()
		l.generate(s, s % 3 == 0)
		var reach := l.reachable_from(l.start)
		check(l.caches.size() >= 2, "seed %d: at least two caches (%d)" % [s, l.caches.size()])
		check(not l.caches.has(l.start), "seed %d: nothing on the start" % s)
		for c in l.caches:
			var cache: Dictionary = l.caches[c]
			if cache.get("drowned", false):
				eq(l.get_tile(c), Level.Tile.WATER, "seed %d: a drowned satchel lies under the water" % s)
			else:
				eq(l.get_tile(c), Level.Tile.COVER, "seed %d: a cache is a crate or barrel" % s)
		var has_grate := not l.grate.is_empty()
		var has_valve := l.valve.x >= 0
		check(not (has_grate and has_valve), "seed %d: one puzzle, not two" % s)
		if has_grate or has_valve:
			puzzles += 1
		var exit := l.outflow.get_center() if l.outflow.has_area() else l.stairs
		check(reach.has(exit), "seed %d: the exit can be reached with the grate shut" % s)
		if has_grate:
			var key: Array = l.caches.keys().filter(func(c): return l.caches[c].item == "grate_key")
			eq(key.size(), 1, "seed %d: one grate key" % s)
			check(key.size() == 1 and Level.DIRS_8.any(func(d): return reach.has(key[0] + d)), "seed %d: the key can be reached without it" % s)
			check(l.caches.keys().any(func(c): return not Level.DIRS_8.any(func(d): return reach.has(c + d))), "seed %d: something waits behind the grate" % s)
		if has_valve:
			check(Level.DIRS_8.any(func(d): return reach.has(l.valve + d)), "seed %d: the valve can be reached" % s)
			check(l.drain.all(func(c): return l.get_tile(c) == Level.Tile.WATER), "seed %d: it drains water" % s)
	check(puzzles >= SEEDS * 0.9, "nearly every level has its puzzle (%d of %d)" % [puzzles, SEEDS])


func test_the_same_seed_gives_the_same_contents() -> void:
	var a := Level.new()
	a.generate(31)
	var b := Level.new()
	b.generate(31)
	eq(a.caches, b.caches, "same caches")
	eq(a.grate, b.grate, "same grate")
	eq(a.valve, b.valve, "same valve")


# ---------------------------------------------------------------- searching and the belt

func test_searching_a_cache_puts_its_item_on_the_belt() -> void:
	var c: Vector2i = game.level.caches.keys().filter(func(k): return not game.level.caches[k].get("drowned", false) and game.level.caches[k].item != "grate_key")[0]
	_stand_by(c)
	var item: String = game.level.caches[c].item
	eq(game.interact(), "searched", "E beside it searches it")
	eq(game.progress.belt, [item] as Array[String], "its %s is on the belt" % item)
	check(game.level.caches[c].opened, "and it is open now")
	eq(game.interact(), "", "an open cache has nothing more")


func test_a_full_belt_leaves_the_item() -> void:
	var c: Vector2i = game.level.caches.keys().filter(func(k): return not game.level.caches[k].get("drowned", false))[0]
	_stand_by(c)
	game.progress.belt.assign(["salve", "salve", "bandage", "salve"])
	eq(game.interact(), "full", "the belt is full")
	check(not game.level.caches[c].opened, "so the item stays where it lies")


func test_salve_and_bandage_in_a_fight_use_a_maneuver() -> void:
	var l := Level.new(10, 8)
	for y in range(1, 7):
		for x in range(1, 9):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.rebuild_paths()
	var h := Bestiary.thomas_full()
	h.cell = Vector2i(4, 3)
	var m := Bestiary.drowned_miner()
	m.cell = Vector2i(8, 6)
	var b := Battle.new()
	b.setup(l, h, [m], 1)
	b.start(true)
	h.stamina = 10
	var ev := b.hero_use("salve")
	eq(h.stamina, 10 + Items.SALVE_HEAL, "a salve gives back 8")
	check(ev.any(func(e): return e.t == "heal"), "and says so")
	eq(b.budget.maneuver, 0, "using the maneuver")
	ev = b.hero_use("bandage")
	check(not ev.any(func(e): return e.t == "status"), "no second item without a maneuver")
	b.budget.maneuver = 1
	h.bleeding = true
	h.bleed = 4
	b.hero_use("bandage")
	check(not h.bleeding and h.bleed == 0, "a bandage stops the bleeding")


func test_belt_items_are_used_up_and_lost_on_death() -> void:
	game.progress.belt.assign(["salve"])
	game.hero_unit.stamina = 5
	game.use_belt(0)
	eq(game.hero_unit.stamina, 5 + Items.SALVE_HEAL, "outside a fight a salve heals at once")
	check(game.progress.belt.is_empty(), "and is gone")
	game.progress.belt.assign(["bandage"])
	game._descend()
	eq(game.progress.belt, ["bandage"] as Array[String], "the belt goes down the stairs with him")
	game.new_level(99)
	check(game.progress.belt.is_empty(), "a new life starts with an empty belt")


# ---------------------------------------------------------------- the puzzles

func test_the_grate_opens_only_with_its_key() -> void:
	game.new_level(_seed_with("grate"))
	var g: Vector2i = game.level.grate[0]
	check(not game.level.is_walkable(g), "the grate is shut")
	_stand_by(g)
	eq(game.interact(), "locked", "without the key it stays shut")
	game.progress.belt.assign(["grate_key"])
	eq(game.interact(), "unlocked", "with it, it opens")
	check(game.level.is_walkable(g), "and he can walk through")
	check(not game.progress.belt.has("grate_key"), "the key is used up")


func test_the_valve_drains_its_basin_and_reveals_a_satchel() -> void:
	game.new_level(_seed_with("valve"))
	var drain := game.level.drain.duplicate()
	var satchel: Vector2i = game.level.caches.keys().filter(func(k): return game.level.caches[k].kind == "satchel")[0]
	check(game.level.caches[satchel].drowned, "the satchel lies under the water")
	_stand_by(game.level.valve)
	eq(game.interact(), "valve", "E turns the valve")
	run(game, 0.1)
	check(game.level.get_tile(drain[-1]) == Level.Tile.WATER, "the water takes a while to go")
	run(game, 0.35 * 12 + 0.5)
	check(drain.all(func(c): return game.level.get_tile(c) == Level.Tile.FLOOR), "then the basin is dry")
	check(not game.level.caches[satchel].drowned, "and the satchel can be reached")
	_stand_by(satchel)
	eq(game.interact(), "searched", "and searched")
