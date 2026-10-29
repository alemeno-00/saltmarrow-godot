extends SceneTree

const COUNT := 1000


func _initialize() -> void:
	await process_frame
	var failures: Array = []
	var unique := {}
	var geometry := {}
	for seed_value in range(1, COUNT + 1):
		for state in SewerAssembler.STATES:
			var l := SewerAssembler.new().generate(seed_value, state)
			var again := SewerAssembler.new().generate(seed_value, state)
			var issues: Array = []
			if l.tiles != again.tiles or l.assembly != again.assembly:issues.append("not deterministic")
			var dry := 0
			for y in l.height:
				for x in l.width:
					var c := Vector2i(x, y)
					if l.is_walkable(c):dry += 1
					if l.get_tile(c) == Level.Tile.WATER and l.is_walkable(c):issues.append("deep water walkable")
					if (x == 0 or y == 0 or x == l.width - 1 or y == l.height - 1) and l.get_tile(c) != Level.Tile.WALL:issues.append("open boundary")
			if not l.is_walkable(l.start):issues.append("blocked start")
			if l.reachable_from(l.start).size() != dry:issues.append("dry cells disconnected")
			var water := {}
			for a in l.assembly.water_below:water[Vector2i(a[0], a[1])] = true
			var seen := {}
			var queue: Array = [water.keys()[0]]
			while not queue.is_empty():
				var c: Vector2i = queue.pop_back()
				if seen.has(c):continue
				seen[c] = true
				for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if water.has(c + d) and not seen.has(c + d):queue.append(c + d)
			if seen.size() != water.size():issues.append("drainage disconnected")
			for link in l.assembly.connections:
				if link.width != 7 or link.waterline != state:issues.append("incompatible port")
				var pa: Dictionary = {}
				var pb: Dictionary = {}
				for m in l.assembly.modules:
					for port in m.ports:
						if m.id == link.a and port.side == link.a_side:pa = port
						if m.id == link.b and port.side == link.b_side:pb = port
				if pa.is_empty() or pb.is_empty():issues.append("missing port")
				elif pa.width != pb.width or pa.waterline != pb.waterline or pa.wall_face_px != pb.wall_face_px or pa.bank_height_px != pb.bank_height_px:issues.append("port contracts disagree")
				else:
					var axis: Vector2i = SewerAssembler.OFFSETS[pa.side]
					var reverse: Vector2i = SewerAssembler.OFFSETS[pb.side]
					if axis != -reverse:issues.append("ports do not face each other")
					var a := Vector2i(pa.cell[0], pa.cell[1])
					var b := Vector2i(pb.cell[0], pb.cell[1])
					if axis.x == 0 and a.x != b.x or axis.y == 0 and a.y != b.y:issues.append("port centers not aligned")
					var lateral := Vector2i(-axis.y, axis.x)
					for endpoint in [a, b]:
						if not water.has(endpoint):issues.append("port has no drainage")
						for lane in [-3, 3]:
							if not l.is_walkable(endpoint + lateral * lane):issues.append("port dry bank blocked")
			for fixture in l.assembly.dressing:
				if fixture.kind in ["torch", "pipe"]:
					var at := Vector2i(fixture.cell[0], fixture.cell[1])
					if not l.is_walkable(at):issues.append("fixture off dry maintenance route")
					if not [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(func(d): return l.get_tile(at + d) == Level.Tile.WALL):issues.append("fixture not mounted beside wall")
				if fixture.kind == "cracked_masonry" and l.get_tile(Vector2i(fixture.cell[0], fixture.cell[1])) != Level.Tile.WALL:issues.append("cosmetic damage altered collision")
				if fixture.kind == "bridge":
					for y in range(fixture.origin[1], fixture.origin[1] + fixture.footprint[1]):
						for x in range(fixture.origin[0], fixture.origin[0] + fixture.footprint[0]):
							if not l.is_walkable(Vector2i(x, y)):issues.append("bridge deck blocked")
			var restored := SewerAssembler.restore(JSON.parse_string(JSON.stringify(l.to_dict())))
			if restored.tiles != l.tiles or restored.reachable_from(restored.start).size() != dry:issues.append("sewer save/load changes collision")
			unique[JSON.stringify(l.assembly).sha256_text()] = true
			geometry[l.tiles.hex_encode().sha256_text()] = true
			if not issues.is_empty():failures.append({"seed": seed_value, "state": state, "issues": issues})
		if seed_value % 100 == 0:
			print("Sewer audit %d/%d seeds, all three water states" % [seed_value, COUNT])
			await process_frame
	var report := {"seed_count": COUNT, "water_states": SewerAssembler.STATES, "assemblies_tested": COUNT * 3,
		"unique_assemblies": unique.size(), "unique_tile_layouts": geometry.size(), "failures": failures, "engine": Engine.get_version_info().string,
		"scope": "dry navigation, water-under connectivity, sealed bounds, ports, fixtures, determinism, sewer serialization; no hydraulic simulation or art fidelity certification"}
	var file := FileAccess.open("res://assets/tiles/sewers/assembly-test/audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("SEWER AUDIT: %d cases, %d failures" % [COUNT * 3, failures.size()])
	if not failures.is_empty():print(JSON.stringify(failures.slice(0, 5)))
	quit(0 if failures.is_empty() else 1)
