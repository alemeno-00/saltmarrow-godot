extends TestBase
## The start and end of a run (design/game-brief.md, MVP item 7): the title when the game opens, the death screen
## (how he died, how far he got, what carries over), and the win once Garrick's tag is taken. Mouse first, with R and
## J still working.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func test_the_game_opens_on_its_title_and_wake_starts_the_life() -> void:
	var g: Game = load("res://scenes/main.tscn").instantiate()
	g.level_seed = 7
	g.journal_path = TEST_JOURNAL
	g.show_title = true
	g.ask_backstory = true
	tree.root.add_child(g)
	await tree.process_frame
	check(g.run_screen.visible and g.run_screen.mode == "title", "the title is up")
	check(not g.backstory_screen.visible, "who he was is asked only once he wakes")
	check(g.paused(), "and nothing moves behind it")
	g._on_wake()
	check(not g.run_screen.visible, "Wake closes the title")
	check(g.backstory_screen.visible, "and asks who Thomas was")
	g.queue_free()


## A fight that Thomas loses to `killer`.
func _die_to(killer: Combatant) -> void:
	game.clear_enemies()
	var e := game._add_enemy(killer, game.level.start + Vector2i(1, 0))
	game._start_battle()
	game.battle.active = e
	game.hero_unit.stamina = -99
	game.hero_unit.dead = true
	game.battle.over = true   # as the battle leaves it when he falls
	game._finish("enemies")


func test_dying_shows_how_and_what_carries_over() -> void:
	game.journal.add("letter_1", "t", "x")
	game.kills_this_life = 3
	_die_to(Bestiary.drowned_miner())
	check(game.dead, "he is dead")
	check(game.run_screen.visible and game.run_screen.mode == "dead", "the death screen is up")
	var s := game.life_stats()
	eq(s.cause, "Killed by a Drowned Miner", "it says what killed him")
	eq(s.depth, 1, "how deep he got")
	eq(s.kills, 3, "how many he killed")
	eq(s.found_all, 1, "and that the journal keeps what he read")
	check(game.run_screen._body.text.contains("1 of the pages") or game.run_screen._body.text.contains("all 1"), "the screen says the journal carries over")


func test_wake_again_begins_a_new_life() -> void:
	_die_to(Bestiary.faithful())
	eq(game.life_stats().cause, "Killed by one of the Faithful", "killed by the Faithful")
	var seed_before := game.life_seed
	game._on_wake()
	check(not game.dead, "he lives again")
	check(not game.run_screen.visible, "the death screen is gone")
	check(game.life_seed != seed_before, "in a new world")
	eq(game.kills_this_life, 0, "with this life's count started fresh")


func test_r_also_wakes_him() -> void:
	_die_to(Bestiary.faithful())
	var ev := InputEventKey.new()
	ev.keycode = KEY_R
	ev.pressed = true
	game._unhandled_input(ev)
	check(not game.dead and not game.run_screen.visible, "R wakes him from the death screen")


func test_taking_garricks_tag_wins_and_keeps_it() -> void:
	game.tag_cell = game.hero.grid_pos
	game._win()
	check(game.won, "the run is won")
	check(game.run_screen.visible and game.run_screen.mode == "won", "the win screen is up")
	check(game.journal.has("tag_1"), "Garrick's tag goes into the journal")
	game._on_wake()
	check(not game.won and not game.run_screen.visible, "Begin again starts a new life")


func test_the_journal_opens_over_the_death_screen() -> void:
	_die_to(Bestiary.faithful())
	game.toggle_journal()
	check(game.journal_screen.visible, "the journal opens from the death screen")
	check(game.journal_screen.get_index() > game.run_screen.get_index(), "drawn over it")
	game.toggle_journal()
	check(game.run_screen.visible, "and closing it goes back to the death screen")
