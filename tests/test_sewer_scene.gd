extends SceneTree
## End-to-end scene smoke test; optional real renderer screenshots with -- --capture.

var failures: Array[String] = []


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
	print(("PASS " if ok else "FAIL ") + message)


func settle(g: Game) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while g.busy and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	check(not g.busy, "combat animation completes within 15 seconds")


func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/tiles/sewers/playable/" + name + ".png")


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://scenes/sewer_fight.tscn")
	var g: Game = packed.instantiate()
	root.add_child(g)
	await process_frame
	await process_frame
	await settle(g)
	check(g.enemies.size() == 4, "scene spawns one miner and three Faithful")
	check(g.in_fight(), "enemy sight starts Claude's Battle")
	check(g.battle.is_hero_turn(), "enemy initiative resolves to a playable hero turn")
	check(g.view.get_script().resource_path.ends_with("sewer_view.gd"), "scene uses the imported corridor art renderer")
	check(not g.level.is_walkable(Vector2i(20, 14)), "deep channel is blocked")
	check(not g.level.is_walkable(Vector2i(10, 5)), "rear masonry is blocked")
	var route := g.level.find_path(Vector2i(12, 9), Vector2i(12, 18))
	check(not route.is_empty(), "rear and front maintenance walks connect over the bridge")
	check(route.any(func(c): return c.x in [24, 25] and c.y == 14), "cross-channel path uses the timber crossing")
	await capture("fight-start")
	var moved := false
	var attacked := false
	for round_index in 4:
		var nearest: Combatant = null
		for e in g.enemies:
			if e.alive() and (nearest == null or Battle.dist(e.cell, g.hero_unit.cell) < Battle.dist(nearest.cell, g.hero_unit.cell)):
				nearest = e
		if nearest == null:
			break
		for step_index in 5:
			if Battle.dist(g.hero_unit.cell, nearest.cell) <= 1:
				break
			var p := g.level.find_path(g.hero_unit.cell, nearest.cell)
			if p.is_empty():break
			var before := g.hero_unit.cell
			g.try_step(p[0] - before)
			await settle(g)
			moved = moved or g.hero_unit.cell != before
		if Battle.dist(g.hero_unit.cell, nearest.cell) <= 1 and g._can_act():
			var stamina_before := nearest.stamina
			g.battle.forced_rolls = [[8, 8]]
			g.selected = -1
			g._combat_click(nearest.cell)
			await settle(g)
			attacked = nearest.stamina < stamina_before or not nearest.alive()
			if attacked:break
		g._end_hero_turn()
		await settle(g)
	check(moved, "Thomas moves using the inherited combat movement path")
	check(attacked, "click-to-strike resolves damage through Claude's combat and playback")
	await capture("fight-after-strike")
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_R
	event.physical_keycode = KEY_R
	g.hero_unit.stamina = 1
	var old_hero := g.hero_unit
	g._unhandled_input(event)
	await process_frame
	await settle(g)
	check(g.hero_unit != old_hero and g.enemies.size() == 4 and g.hero_unit.stamina == g.hero_unit.max_stamina, "R restarts the encounter with fresh actors")
	print("SEWER SCENE: %d failures" % failures.size())
	g.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
