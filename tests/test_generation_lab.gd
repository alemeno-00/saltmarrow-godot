extends SceneTree
## Exercises viewer controls and optionally captures its real Godot viewport.


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1280, 800)
	var lab = load("res://scenes/generation_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	var first: PackedByteArray = lab.level.tiles.duplicate()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_R
	lab._unhandled_input(key)
	assert(lab.seed_value == 2 and lab.level.tiles != first, "R produces a different seed")
	key.keycode = KEY_LEFT
	lab._unhandled_input(key)
	assert(lab.seed_value == 1 and lab.level.tiles == first, "previous seed reproduces the original map")
	key.keycode = KEY_T
	lab._unhandled_input(key)
	assert(lab.textured, "texture switch works")
	lab.textured = false
	for s in [1, 7, 42]:
		lab.seed_value = s
		lab.regenerate()
		await process_frame
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://assets/tiles/sewers/generation-test/seed-%d.png" % s)
	print("GENERATION LAB: seed advance, deterministic return, texture switch and three sample seeds passed")
	lab.queue_free()
	await process_frame
	quit()
