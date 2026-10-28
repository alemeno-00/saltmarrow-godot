extends SceneTree
## Saves a picture of the running game:  xvfb-run godot --path . -s tools/screenshot.gd -- out.png

func _initialize() -> void:
	var out := "screenshot.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var game: Game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 10:
		await process_frame
	game.walk_to(game.level.rooms[1].get_center())
	for i in 40:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("saved ", out)
	quit()
