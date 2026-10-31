extends TestBase
## The HUD (design/ux/hud.md): Stamina always shown, everything on the old hint line reachable with the mouse, the
## tooltip by the cursor, the turn order in fights, and nothing off the screen.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func _on_screen(c: Control) -> bool:
	return Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(Rect2(c.position, c.size))


func test_stamina_is_always_shown_as_a_number_and_a_bar() -> void:
	game._refresh()
	var h := game.hero_unit
	check(game.combat_hud.stamina_label.text.begins_with("%d / %d" % [h.stamina, h.max_stamina]), "exploring: %s" % game.combat_hud.stamina_label.text)
	h.stamina = 5
	game._refresh()
	check(game.combat_hud.stamina_label.text.begins_with("5 / "), "and it follows his wounds")
	check(absf(game.combat_hud.stamina_bar.value - 5.0 / h.max_stamina) < 0.01, "so does the bar")


func test_the_hotbar_does_what_the_hint_line_said() -> void:
	game.combat_hud.explore_pressed.emit("sneak")
	check(game.sneaking, "Sneak crouches him")
	game.combat_hud.explore_pressed.emit("lantern")
	eq(game.lantern, "shuttered", "Lantern shutters it")
	game.combat_hud.explore_pressed.emit("douse")
	eq(game.lantern, "out", "right-clicking the lantern puts it out")
	game.combat_hud.top_buttons.journal.pressed.emit()
	check(game.journal_screen.visible, "Journal opens the journal")
	game.toggle_journal()
	game.combat_hud.top_buttons.skills.pressed.emit()
	check(game.tree_screen.visible, "Skills opens the skill tree")
	game._toggle_tree()
	game.combat_hud.top_buttons.menu.pressed.emit()
	check(game.menu.visible and game.paused(), "Menu opens the menu, and the world waits")
	var before := game.life_seed
	game.menu.press("new_life")
	check(not game.menu.visible and game.life_seed != before, "New life starts one")


func test_esc_opens_and_closes_the_menu() -> void:
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	game._unhandled_input(esc)
	check(game.menu.visible, "Esc opens it")
	game._unhandled_input(esc)
	check(not game.menu.visible, "and closes it")


func test_hovering_an_enemy_names_it_by_the_cursor() -> void:
	game.clear_enemies()
	var c := game.level.start
	var spot := c
	for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
		if game.level.is_walkable(c + d) and game.level.line_of_sight(c, c + d):
			spot = c + d
			break
	var e := game._add_enemy(Bestiary.faithful(), spot)
	game._heads[e] = 9999.0
	game.views[e].look = (Vector2(spot - c)).normalized()   # facing away
	run(game, 0.1)
	var lines := game.hover_tip(game.views[e].position)
	check(lines.size() >= 2 and lines[0] == "Faithful", "it is named: %s" % [lines])
	check(lines.size() >= 3 and lines[2].begins_with("Click:"), "and what a click does")
	eq(game.hover_tip(game.hero.position + Vector2(400, 400)), [], "nothing under the mouse: no tooltip")


func test_the_turn_order_shows_everyone_in_the_fight() -> void:
	game.clear_enemies()
	var c := game.level.start
	var n := 0
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if n < 2 and game.level.is_walkable(c + d):
			game._add_enemy(Bestiary.faithful(), c + d)
			n += 1
	game._start_battle()
	game._refresh()
	var alive := game.battle.units.filter(func(u): return u.alive())
	eq(game.combat_hud.turn_tokens.size(), alive.size(), "a token for everyone still fighting")
	var lit := game.combat_hud.turn_tokens.filter(func(t): return t[1].active)
	check(lit.size() == 1 and lit[0][0] == game.battle.active, "the one acting is lit")


func test_nothing_runs_off_the_screen() -> void:
	game._refresh()
	game._update_hud()
	check(_on_screen(game.combat_hud.hotbar), "exploring, the hotbar fits (%s)" % Rect2(game.combat_hud.hotbar.position, game.combat_hud.hotbar.size))
	game.clear_enemies()
	for d in [Vector2i(1, 0), Vector2i(-1, 0)]:
		if game.level.is_walkable(game.level.start + d):
			game._add_enemy(Bestiary.faithful(), game.level.start + d)
	game._start_battle()
	game.combat_hud.show_fight(true)
	game._refresh()
	check(_on_screen(game.combat_hud.hotbar), "fighting, it fits too (%s)" % Rect2(game.combat_hud.hotbar.position, game.combat_hud.hotbar.size))
	check(not game.hud.visible, "the old line of key hints is gone")
