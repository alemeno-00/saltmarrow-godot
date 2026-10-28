extends Game
## A single module-assembled corridor for visual acceptance, with real movement/combat.


func new_level(seed_in: int) -> void:
	super.new_level(seed_in)
	level = SewerLevel.new(40, 22)
	level.seed_value = seed_in
	for y in range(8, 15):
		for x in range(4, 36):
			if y in [10, 11, 12]:level.set_tile(Vector2i(x, y), Level.Tile.WATER)
			else:level.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	# Dry arch threshold behind the rear walk, and one supported channel crossing.
	level.set_tile(Vector2i(26, 7), Level.Tile.FLOOR)
	for y in range(9, 14):
		level.set_tile(Vector2i(19, y), Level.Tile.FLOOR)
	level.start = Vector2i(12, 8)
	level.rooms = [Rect2i(4, 8, 32, 7)]
	level.rebuild_paths()
	view.show_level(level)
	hero.place(level.start)
	hero_unit.cell = level.start
	hero.scale = Vector2.ONE
	clear_enemies()
	_add_enemy(Bestiary.drowned_miner(), Vector2i(21, 8))
	_add_enemy(Bestiary.faithful(), Vector2i(23, 9))
	cam.zoom = Vector2(1.5, 1.5)
	cam.position = Vector2(640, 330)
	_update_hud()


func _spawn_enemies() -> void:
	pass


func _add_enemy(unit: Combatant, cell: Vector2i) -> void:
	unit.cell = cell
	var actor := FidelityEnemy.new()
	actor.style = unit.style
	actors.add_child(actor)
	actor.place(cell)
	actor.facing = -1
	enemies.append(unit)
	views[unit] = actor


func _process(delta: float) -> void:
	super._process(delta)
	# Fixed acceptance framing exposes the complete material/scale relationship.
	cam.position = Vector2(640, 330)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		$HUD.visible = not $HUD.visible
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		view.set("overlays_enabled", not view.get("overlays_enabled"))
		view.queue_redraw()
		return
	super._unhandled_input(event)
