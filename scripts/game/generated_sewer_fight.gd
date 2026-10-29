class_name GeneratedSewerFight
extends Game
## The sewer assembler supplies the real movement map; Claude's combat stays unchanged.

@export_enum("low", "normal", "high") var water_state := "normal"


func new_level(seed_in: int) -> void:
	super.new_level(seed_in)
	level = SewerAssembler.new().generate(seed_in, water_state)
	view.show_level(level)
	hero.place(level.start)
	hero_unit.cell = level.start
	hero.sync(hero_unit)
	clear_enemies()
	var spawn := encounter_cells(level)
	assert(spawn.size() == 4, "The intake needs four legal encounter cells")
	_add_enemy(Bestiary.drowned_miner(), spawn[0])
	for i in range(1, 4):_add_enemy(Bestiary.faithful(), spawn[i])
	cam.zoom = Vector2(1.5, 1.5)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = level.width * TILE
	cam.limit_bottom = level.height * TILE
	cam.position = hero.position
	_update_hud()
	_check_spotted.call_deferred()


func _spawn_enemies() -> void:
	# Suppress the generic-room encounter until the sewer map is installed.
	pass


static func encounter_cells(l: Level) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var scores := {}
	for y in l.height:
		for x in l.width:
			var c := Vector2i(x, y)
			var distance := Battle.dist(c, l.start)
			if distance < 3 or distance > mini(7, Battle.SIGHT) or l.get_tile(c) != Level.Tile.FLOOR:continue
			if not l.line_of_sight(c, l.start):continue
			var path := l.find_path(l.start, c)
			if path.size() >= 4 and path.size() <= 10:
				candidates.append(c)
				scores[c] = absi(path.size() - 6) * 10000 + posmod(c.x * 71 + c.y * 113 + l.seed_value * 37, 997)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i): return scores[a] < scores[b])
	var chosen: Array[Vector2i] = []
	for c in candidates:
		if chosen.size() == 4:break
		chosen.append(c)
	return chosen
