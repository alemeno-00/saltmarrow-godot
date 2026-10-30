class_name TestBase
extends RefCounted

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func eq(a, b, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])


## Run the game's frame logic for `seconds` of game time, 60 frames a second.
## `game` is a Node, not Game, so this file still compiles when game.gd is broken.
func run(game: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		game._process(1.0 / 60.0)
		t += 1.0 / 60.0


## Hold movement keys (input actions) down for `seconds` of game time, then let go.
func hold(game: Node, actions: Array, seconds: float) -> void:
	for a in actions:
		Input.action_press(a)
	run(game, seconds)
	for a in actions:
		Input.action_release(a)


## Loads the main game scene and adds it to the tree. Returns null, with a recorded
## failure, when the scene or its script does not load, so a broken build fails
## loudly in setup instead of erroring on null objects in every test.
## Returns Node, not Game, so this file still compiles when game.gd is broken.
func add_game(tree: SceneTree) -> Node:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		failures.append("scenes/main.tscn did not load")
		return null
	var node := packed.instantiate()
	var script: Script = node.get_script() if node != null else null
	if script == null or not script.can_instantiate():
		failures.append("scenes/main.tscn has no working script (did scripts/game/game.gd fail to parse?)")
		if node != null:
			node.free()
		return null
	if "level_seed" in node:
		node.level_seed = 7   # a fixed first level, so game tests repeat exactly
	tree.root.add_child(node)
	await tree.process_frame
	return node
