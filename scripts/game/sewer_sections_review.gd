extends Game
## Isolated walk-through; keeps core combat and the other character workflow untouched.

var arrangement := 0
var overview := true


func new_level(seed_in: int) -> void:
	super.new_level(seed_in)
	level = SewerSections.build(arrangement)
	view.show_level(level)
	hero.place(level.start)
	hero_unit.cell = level.start
	hero.scale = Vector2.ONE
	clear_enemies()
	cam.position = Vector2(level.width, level.height) * 16
	cam.zoom = Vector2(0.4, 0.4) if overview else Vector2(1.7, 1.7)
	_update_hud()


func _spawn_enemies() -> void:
	pass


func _update_hud() -> void:
	super._update_hud()
	hud.text = "SEWER SECTIONS — %s  |  1 / 2: arrangement  •  Tab: overview / follow  •  M: collision  •  arrows / click: walk" % ("A" if arrangement == 0 else "B")


func _process(delta: float) -> void:
	super._process(delta)
	if overview:cam.position = Vector2(level.width, level.height) * 16


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_1, KEY_2]:
			arrangement = 0 if event.keycode == KEY_1 else 1
			new_level(level_seed)
			return
		if event.keycode == KEY_TAB:
			overview = not overview
			cam.zoom = Vector2(0.4, 0.4) if overview else Vector2(1.7, 1.7)
			return
		if event.keycode == KEY_M:
			view.set("debug_mask", not view.get("debug_mask"))
			view.queue_redraw()
			return
	super._unhandled_input(event)
