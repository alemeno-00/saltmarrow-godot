extends Game
## Isolated art/combat integration test. Reuses Game/Battle without changing their rules.


func new_level(seed_in: int) -> void:
	super.new_level(seed_in)
	level = sewer_level(seed_in)
	view.show_level(level)
	hero.place(level.start)
	hero_unit.cell = level.start
	hero.sync(hero_unit)
	clear_enemies()
	_add_enemy(Bestiary.drowned_miner(), Vector2i(18, 9))
	_add_enemy(Bestiary.faithful(), Vector2i(20, 10))
	_add_enemy(Bestiary.faithful(), Vector2i(22, 9))
	_add_enemy(Bestiary.faithful(), Vector2i(23, 10))
	cam.zoom = Vector2(1.5, 1.5)
	cam.position = hero.position
	_update_hud()
	_check_spotted.call_deferred()


func _spawn_enemies() -> void:
	# Game.new_level calls this hook before the authored sewer map is installed.
	pass


static func sewer_level(seed_in: int = 1) -> Level:
	var l := Level.new(56, 28)
	l.seed_value = seed_in
	# Ground cells are registered to the full-resolution illustration. Decorative masonry,
	# pipework, water and off-room pixels are blocked. This is a fixed test room, not procgen.
	for y in [9, 10]:
		for x in range(4, 47):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	for x in range(4, 47):
		l.set_tile(Vector2i(x, 18), Level.Tile.FLOOR)
	for y in range(10, 19):
		for x in [24, 25]:
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	# The inset grate is load-bearing and remains walkable.
	l.start = Vector2i(12, 9)
	l.rooms.append(Rect2i(4, 9, 43, 2))
	l.rooms.append(Rect2i(4, 18, 43, 1))
	l.rebuild_paths()
	return l
