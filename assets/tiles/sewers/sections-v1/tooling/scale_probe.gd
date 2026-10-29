extends SceneTree
## Read-only comparison of the sprite workstream's candidate in the actual sewer.
## Pass -- --sprite=/absolute/path.png; no candidate asset is copied into this branch.

class ScaleActor extends Hero:
	var body: Texture2D
	var display_scale := 1.0

	func _draw_body() -> void:
		var size := Vector2(64, 64) * display_scale
		var origin := Vector2(32, 56) * display_scale
		draw_texture_rect(body, Rect2(Vector2(0, 12) - origin, size), false)


func _initialize() -> void:
	await process_frame
	var sprite_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sprite="):sprite_path = arg.trim_prefix("--sprite=")
	if sprite_path.is_empty():
		push_error("Pass -- --sprite=/absolute/path/to/standing-candidate.png")
		quit(1)
		return
	var source := Image.load_from_file(sprite_path)
	assert(source != null and source.get_size() == Vector2i(64, 64))
	root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/sewer_sections_review.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.get_node("HUD").visible = false
	var old := game.hero
	game.actors.remove_child(old)
	old.queue_free()
	var actor := ScaleActor.new()
	actor.body = ImageTexture.create_from_image(source)
	game.actors.add_child(actor)
	game.hero = actor
	actor.place(Vector2i(44, 11))
	game.hero_unit.cell = actor.grid_pos
	game.cam.position = Vector2(1424, 320)
	game.cam.zoom = Vector2(1.25, 1.25)
	for scale_in in [1.0, 1.25]:
		actor.display_scale = scale_in
		actor.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var suffix := "native" if scale_in == 1.0 else "review-scale"
		var result := root.get_texture().get_image().save_png(SewerSections.ROOT + "previews/sprite-" + suffix + ".png")
		assert(result == OK)
	print("SPRITE SCALE PROBE: two real engine captures, same camera and foot position; visual approval pending")
	game.queue_free()
	await process_frame
	quit()
