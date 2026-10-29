extends SceneTree
## Real scene, registered layers, matching ports, all-floor reachability and captures.

var failures: Array[String] = []


func check(ok: bool, message: String) -> void:
	if not ok:failures.append(message)
	print(("PASS " if ok else "FAIL ") + message)


func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(SewerSections.ROOT + "previews/" + name + ".png")
	check(result == OK, "engine screenshot saved: " + name)


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1600, 900)
	var game: Game = load("res://scenes/sewer_sections_review.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for arrangement in 2:
		game.set("arrangement", arrangement)
		game.new_level(1)
		await process_frame
		check(game.level is SewerLevel, "arrangement %d uses blocked deep water" % arrangement)
		var reached := {game.level.start: true}
		var frontier: Array[Vector2i] = [game.level.start]
		while not frontier.is_empty():
			var c: Vector2i = frontier.pop_back()
			for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var next: Vector2i = c + d
				if game.level.is_walkable(next) and not reached.has(next):
					reached[next] = true
					frontier.append(next)
		var all_reachable := true
		var water_blocked := true
		for y in game.level.height:
			for x in game.level.width:
				var c := Vector2i(x, y)
				if game.level.is_walkable(c) and not reached.has(c):all_reachable = false
				if game.level.get_tile(c) == Level.Tile.WATER and game.level.is_walkable(c):water_blocked = false
		check(all_reachable, "all dry cells connect across arrangement %d" % arrangement)
		check(water_blocked, "all water cells remain blocked")
		var sections: Array = (game.level as SewerLevel).assembly.sections
		for index in range(1, sections.size()):
			var x := int(sections[index].cell_origin[0])
			for y in range(10, 18):
				check(game.level.get_tile(Vector2i(x-1,y)) == game.level.get_tile(Vector2i(x,y)), "port profile %d row %d matches" % [index,y])
		game.set("overview", true)
		game.cam.position = Vector2(game.level.width, game.level.height) * 16
		game.cam.zoom = Vector2(0.4, 0.4)
		game.get_node("HUD").visible = false
		await process_frame
		await capture("arrangement-%s" % ("a" if arrangement == 0 else "b"))
		# Exercise the existing exploration input path and verify actual movement.
		var before := game.hero_unit.cell
		game.try_step(Vector2i.RIGHT)
		check(game.hero_unit.cell == before + Vector2i.RIGHT, "existing movement steps on the authored floor")
		var walked := true
		for target in [Vector2i(game.level.width - 3, 11), Vector2i(game.level.width - 3, 17), Vector2i(2, 17)]:
			var route := game.level.find_path(game.hero_unit.cell, target)
			if route.is_empty():walked = false
			for next in route:
				if not game.try_step(next - game.hero_unit.cell):walked = false
			if game.hero_unit.cell != target:walked = false
		check(walked, "actual exploration traverses both joins and returns on the lower walk")
		game.hero.place(game.level.start)
		game.hero_unit.cell = game.level.start
		game.set("overview", false)
		game.cam.zoom = Vector2(0.75, 0.75)
		for section in sections:
			var data: Dictionary = SewerSections.manifest().sections[section.id]
			game.cam.position = Vector2(section.cell_origin[0] * 32 + data.size[0] / 2, 448)
			# Keep camera fixed for the image without bypassing the actual renderer.
			game.set_process(false)
			await process_frame
			await capture("%s-detail" % section.id)
		game.set_process(true)
	game.queue_free()
	await process_frame
	print("SEWER SECTIONS: %d failures; visual acceptance remains user-reviewed" % failures.size())
	quit(0 if failures.is_empty() else 1)
