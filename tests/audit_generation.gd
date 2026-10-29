extends SceneTree
## Runs the actual Level generator in Godot. Does not pretend generic rooms are biome grammars.

const SEEDS := 1000
const REPORT := "res://assets/tiles/sewers/generation-test/audit.json"


func _initialize() -> void:
	await process_frame
	var failures: Array = []
	var fingerprints := {}
	var samples: Array = []
	var minimum_rooms := 100
	var maximum_rooms := 0
	var minimum_walk := 100000
	var maximum_walk := 0
	var started := Time.get_ticks_msec()
	for seed_value in range(1, SEEDS + 1):
		var l := Level.new()
		l.generate(seed_value)
		var duplicate := Level.new()
		duplicate.generate(seed_value)
		var problems: Array[String] = []
		if l.tiles != duplicate.tiles or l.start != duplicate.start or l.rooms != duplicate.rooms:
			problems.append("same-seed generation differs")
		if not l.is_walkable(l.start):problems.append("start is blocked")
		if l.rooms.size() < 6:problems.append("fewer than six rooms")
		var walk := 0
		var water := 0
		var doors := 0
		for y in l.height:
			for x in l.width:
				var c := Vector2i(x, y)
				var tile := l.get_tile(c)
				if tile < Level.Tile.WALL or tile > Level.Tile.WATER:problems.append("invalid tile")
				if l.is_walkable(c):walk += 1
				if tile == Level.Tile.WATER:water += 1
				if tile == Level.Tile.DOOR_CLOSED:doors += 1
				if (x == 0 or y == 0 or x == l.width - 1 or y == l.height - 1) and tile != Level.Tile.WALL:
					problems.append("outer boundary open")
		var reachable := l.reachable_from(l.start)
		if reachable.size() != walk:problems.append("unreachable walkable cells")
		for i in l.rooms.size():
			var room: Rect2i = l.rooms[i]
			if not Rect2i(1, 1, l.width - 2, l.height - 2).encloses(room):problems.append("room outside bounds")
			for j in range(i + 1, l.rooms.size()):
				if room.grow(2).intersects(l.rooms[j]):problems.append("room spacing violation")
			var target := room.get_center()
			var path := l.find_path(l.start, target)
			if target != l.start and path.is_empty():problems.append("room center unreachable")
			var previous := l.start
			for step in path:
				if not l.can_step(previous, step - previous):problems.append("illegal path step")
				previous = step
		var restored := Level.from_dict(JSON.parse_string(JSON.stringify(l.to_dict())))
		if restored.tiles != l.tiles or restored.start != l.start:problems.append("save/load tile roundtrip differs")
		if restored.reachable_from(restored.start).size() != walk:problems.append("save/load path graph differs")
		fingerprints[l.tiles.hex_encode().sha256_text()] = true
		minimum_rooms = mini(minimum_rooms, l.rooms.size())
		maximum_rooms = maxi(maximum_rooms, l.rooms.size())
		minimum_walk = mini(minimum_walk, walk)
		maximum_walk = maxi(maximum_walk, walk)
		if seed_value <= 12 or not problems.is_empty():
			samples.append({"seed": seed_value, "rooms": l.rooms.size(), "walkable": walk, "water": water, "doors": doors})
		if not problems.is_empty():failures.append({"seed": seed_value, "problems": problems})
		if seed_value % 100 == 0:
			print("Audited %d / %d seeds" % [seed_value, SEEDS])
			await process_frame
	var report := {"engine": Engine.get_version_info().string, "seed_first": 1, "seed_last": SEEDS,
		"map_cells": [60, 40], "failures": failures, "unique_layouts": fingerprints.size(),
		"rooms_range": [minimum_rooms, maximum_rooms], "walkable_range": [minimum_walk, maximum_walk],
		"elapsed_ms": Time.get_ticks_msec() - started, "sample_seeds": samples,
		"scope": "Generic Level.generate only. Water/closed doors are walkable under current rules. Six biome grammars, 30 archetypes each, dry-only connectivity, art fidelity, combat balance and flooding states are not implemented or certified by this audit."}
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("GENERATION AUDIT: %d seeds, %d unique, %d failed" % [SEEDS, fingerprints.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
