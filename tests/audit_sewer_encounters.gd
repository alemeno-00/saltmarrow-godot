extends SceneTree


func _initialize() -> void:
	await process_frame
	var failures: Array = []
	for seed_value in range(1, 101):
		for state in SewerAssembler.STATES:
			var l := SewerAssembler.new().generate(seed_value, state)
			var spawns := GeneratedSewerFight.encounter_cells(l)
			var used := {l.start: true}
			var problems: Array = []
			if spawns.size() != 4:problems.append("wrong enemy count")
			for c in spawns:
				if used.has(c):problems.append("overlapping spawn")
				used[c] = true
				if l.get_tile(c) != Level.Tile.FLOOR:problems.append("enemy in water or wall")
				if l.find_path(l.start, c).is_empty():problems.append("unreachable enemy")
				if not l.line_of_sight(c, l.start) or Battle.dist(c, l.start) > Battle.SIGHT:problems.append("encounter does not trigger")
			if spawns != GeneratedSewerFight.encounter_cells(l):problems.append("spawns not deterministic")
			if not problems.is_empty():failures.append({"seed": seed_value, "state": state, "problems": problems})
		if seed_value % 20 == 0:await process_frame
	var file := FileAccess.open("res://assets/tiles/sewers/generated-fight/audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"cases": 300, "failures": failures,
		"scope": "deterministic four-enemy placement, dry cells, no overlaps, reachability and sight-trigger eligibility; encounter balance not certified"}, "\t") + "\n")
	print("GENERATED ENCOUNTERS: 300 cases, %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
