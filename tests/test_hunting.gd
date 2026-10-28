extends TestBase
## Enemies outside a fight: runaways coming back with friends, hunters closing in.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame


func teardown() -> void:
	game.queue_free()


func test_runaway_comes_back_with_friends() -> void:
	var m: Combatant = game.enemies[0]
	m.fled = true
	m.stamina = 3
	game.views[m].visible = false
	var before := game.enemies.size()
	game.returning.append([m, 1])
	game.wait_turn()
	check(not m.fled and m.alive(), "the miner is back")
	check(game.views[m].visible, "and can be seen")
	check(m.stamina >= 12, "partly healed")
	eq(game.enemies.size(), before + 2, "with two more Faithful")
	eq(m.state, "hunting", "and it is hunting Thomas")


func test_hunters_close_in_one_square_a_turn() -> void:
	var m: Combatant = game.enemies[0]
	for e in game.enemies:
		if e != m:
			e.dead = true
	m.state = "hunting"
	var d0 := game.level.find_path(m.cell, game.hero.grid_pos).size()
	game.wait_turn()
	if not game.in_fight():
		eq(game.level.find_path(m.cell, game.hero.grid_pos).size(), d0 - 1, "one square closer")
	else:
		check(true, "it closed in and spotted him")


func test_stairs_keep_what_thomas_learned() -> void:
	game.progress.add_xp(5)
	game.hero_unit.stamina = 10
	game._descend()
	eq(game.depth, 2, "depth 2")
	eq(game.progress.level, 2, "still level 2")
	eq(game.hero_unit.stamina, 10, "still hurt")
	game.new_level(99)
	eq(game.progress.level, 1, "a new life starts again at level 1")
