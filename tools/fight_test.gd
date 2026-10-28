extends SceneTree
## Plays a whole fight automatically, in a window, and saves pictures along the way.
##   xvfb-run godot --path . -s tools/fight_test.gd -- out_dir [seed]

var game: Game
var out := "."
var shots := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
		DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _frames(5)
	if args.size() > 1:
		game.new_level(int(args[1]))
		await _frames(2)
	# walk toward the enemies until something sees Thomas
	var target: Vector2i = game.enemies[0].cell
	game.walk_to(target)
	var guard := 0
	while not game.in_fight() and guard < 600:
		await process_frame
		guard += 1
	await _shot("1_spotted")
	var turns := 0
	while game.in_fight() and turns < 40:
		await _until_ready()
		if not game.in_fight():
			break
		turns += 1
		var b := game.battle
		var h := game.hero_unit
		if h.prone:
			game._act(b.hero_stand())
			await _until_ready()
		# step out of a telegraphed blow
		var danger := []
		for e in game.enemies:
			danger.append_array(e.telegraph)
		if danger.has(h.cell):
			# prefer a safe square that is still next to an enemy
			var safe := Vector2i(-1, -1)
			for c in game.reach:
				if not danger.has(c):
					if safe.x < 0 or b.enemies_of(h).any(func(e): return Battle.adjacent(e.cell, c)):
						safe = c
			var shifts := b.shift_cells().filter(func(c): return not danger.has(c))
			if not shifts.is_empty():
				game._act(b.hero_shift(shifts[0]))
				await _until_ready()
			elif safe.x >= 0:
				game._combat_click(safe)
				await _until_ready()
		if h.stamina < 8 and h.recoveries > 0 and b.budget.main > 0:
			game._act(b.hero_catch_breath())
			await _until_ready()
		# move next to the nearest enemy
		var foes := b.enemies_of(h)
		foes.sort_custom(func(a, c): return Battle.dist(a.cell, h.cell) < Battle.dist(c.cell, h.cell))
		var foe: Combatant = foes[0]
		if not Battle.adjacent(foe.cell, h.cell):
			var best := Vector2i(-1, -1)
			for c in game.reach:
				if Battle.adjacent(c, foe.cell) and (best.x < 0 or Battle.dist(c, h.cell) < Battle.dist(best, h.cell)):
					best = c
			if best.x < 0:
				var bd := 999
				for c in game.reach:
					if Battle.dist(c, foe.cell) < bd:
						bd = Battle.dist(c, foe.cell)
						best = c
			if best.x >= 0:
				game._combat_click(best)
				await _until_ready()
		if not game.in_fight():
			break
		# best ability we can use
		for i in [4, 3, 1, 2, 0]:
			if i >= h.abilities.size():
				continue
			var ab: Dictionary = h.abilities[i]
			if i == 3 and b.valid_targets(h, ab).size() < 2:
				continue
			if b.cannot_use(h, ab) == "" and not b.valid_targets(h, ab).is_empty():
				game._on_ability_key(i)
				if game.selected >= 0:
					game._combat_click(b.valid_targets(h, ab)[0].cell)
				await _until_ready()
				break
		if turns == 2:
			await _shot("2_fighting")
		if h.stamina < 10 and h.recoveries > 0 and b.budget.main > 0:
			game._act(b.hero_catch_breath())
			await _until_ready()
		if game.in_fight():
			game._end_hero_turn()
			await _frames(3)
			if game.enemies.any(func(e): return not e.telegraph.is_empty()):
				await _until_ready()
				await _shot("3_telegraph")
	await _frames(30)
	await _shot("4_after")
	game.progress.mastery["maces"] = 2
	game._toggle_tree()
	await _frames(3)
	game.tree_screen._on_hover("knee_breaker")
	await _shot("5_tree")
	for l in game.combat_hud.history:
		print("  ", l)
	print("fight over after %d turns: winner=%s, Thomas stamina %d, dead=%s" % [turns, game.battle.winner if game.battle else "?", game.hero_unit.stamina, game.dead])
	quit()


func _until_ready() -> void:
	var g := 0
	while game.busy and g < 2000:
		await process_frame
		g += 1
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(2)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
