extends SceneTree


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1280, 800)
	var lab = load("res://scenes/sewer_generation.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	assert(lab.level is SewerLevel)
	var first: PackedByteArray = lab.level.tiles.duplicate()
	for state in SewerAssembler.STATES:
		lab.water_state = state
		lab.regenerate()
		assert(not lab.route.is_empty(), "dry route survives every water state")
		for cell in lab.route:assert(lab.level.get_tile(cell) == Level.Tile.FLOOR)
		await process_frame
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://assets/tiles/sewers/assembly-test/" + state + ".png")
	lab.water_state = "normal"
	lab.regenerate()
	assert(lab.level.tiles == first)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_S
	lab._unhandled_input(key)
	assert(not lab.sewer_mode and not lab.level is SewerLevel)
	lab._unhandled_input(key)
	assert(lab.sewer_mode and lab.level.tiles == first)
	var mutation := Vector2i(20, 19)
	lab.level.set_tile(mutation, Level.Tile.WATER)
	assert(not lab.level.is_walkable(mutation))
	assert(lab.level.find_path(lab.level.start, mutation).is_empty(), "runtime water mutation updates AStar collision")
	print("SEWER LAB: three states, dry routes, mode comparison, deterministic return and water mutation passed")
	lab.queue_free()
	await process_frame
	quit()
