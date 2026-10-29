extends SceneTree


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/fidelity_corridor.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.level.is_walkable(Vector2i(26, 7)), "arch aperture aligns with clear ground cells")
	assert(not game.level.is_walkable(Vector2i(24, 7)), "arch pier is blocked")
	assert(not game.level.is_walkable(Vector2i(25, 7)), "aperture does not allow clipping the left pier")
	assert(not game.level.is_walkable(Vector2i(18, 11)), "bridge rail overhang is not a walkable lane")
	assert(not game.level.is_walkable(Vector2i(13, 12)), "water stays blocked")
	assert(not game.level.find_path(Vector2i(12, 8), Vector2i(12, 14)).is_empty(), "bridge joins maintenance walks")
	var tiles_before: PackedByteArray = game.level.tiles.duplicate()
	game.view.set("overlays_enabled", false)
	game.view.queue_redraw()
	if "--capture" in OS.get_cmdline_user_args():
		game.get_node("HUD").visible = false
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://assets/tiles/sewers/fidelity-v2/godot-corridor-clean.png")
	game.view.set("overlays_enabled", true)
	game.view.queue_redraw()
	assert(game.level.tiles == tiles_before, "wear overlays preserve movement cells")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://assets/tiles/sewers/fidelity-v2/godot-corridor.png")
	print("FIDELITY CORRIDOR: physical threshold, blocked water and bridge route passed; visual approval not asserted")
	game.queue_free()
	await process_frame
	quit()
