class_name SewerAssembler
extends RefCounted
## Drainage-first sewer grammar. Fixed port geometry; seeded module and dressing variation.

const PORT_WIDTH := 7
const STATES := ["low", "normal", "high"]
const OFFSETS := {"N": Vector2i.UP, "E": Vector2i.RIGHT, "S": Vector2i.DOWN, "W": Vector2i.LEFT}
var level: SewerLevel
var rng := RandomNumberGenerator.new()
var water_below := {}
var modules: Array = []
var connections: Array = []
var dressing: Array = []
var channel_half := 1


func generate(seed_value: int, state := "normal") -> SewerLevel:
	assert(state in STATES, "Unknown water state")
	rng.seed = seed_value
	level = SewerLevel.new(60, 44)
	level.seed_value = seed_value
	level.water_state = state
	channel_half = {"low": 0, "normal": 1, "high": 2}[state]
	water_below = {}; modules = []; connections = []; dressing = []
	# A municipal trunk with two terminal basins and one perpendicular service branch.
	_module("intake", "cistern", Vector2i(rng.randi_range(9, 11), 22), ["E"], rng.randi_range(0, 2))
	_module("hub", "rounded_junction", Vector2i(30, 22), ["N", "E", "S", "W"], rng.randi_range(0, 2))
	_module("outlet", "sluice" if rng.randf() < 0.5 else "settling_basin", Vector2i(rng.randi_range(49, 51), 22), ["W"], rng.randi_range(0, 2))
	_module("upstream", "settling_basin" if rng.randf() < 0.5 else "outfall", Vector2i(30, rng.randi_range(7, 9)), ["S"], rng.randi_range(0, 2))
	_module("service", "pump_chamber" if rng.randf() < 0.5 else "maintenance", Vector2i(30, rng.randi_range(35, 36)), ["N"], rng.randi_range(0, 2))
	_link(0, "E", 1, "W")
	_link(1, "E", 2, "W")
	_link(1, "N", 3, "S")
	_link(1, "S", 4, "N")
	# Crossings have explicit water-under metadata, so drainage survives under a dry route.
	_bridge(Rect2i(19, 19, 2, 7), "trunk_crossing")
	_bridge(Rect2i(27, 14, 7, 2), "service_crossing")
	level.start = Vector2i(5, 22)
	for m in modules:
		var p := Vector2i(m.origin[0], m.origin[1])
		level.rooms.append(Rect2i(p, Vector2i(13, 13)))
		var clear: Array = []
		var solid: Array = []
		for y in 13:
			for x in 13:
				if level.is_walkable(p + Vector2i(x, y)):clear.append([x, y])
				else:solid.append([x, y])
		m["clear_cells"] = clear
		m["solid_cells"] = solid
	level.rebuild_paths()
	_decorate()
	var below: Array = []
	for c in water_below:below.append([c.x, c.y])
	level.assembly = {"biome": "sewers", "grid_px": 32, "modules": modules, "connections": connections,
		"dressing": dressing, "water_below": below, "port_width": PORT_WIDTH,
		"waterline": state, "hazard_policy": "water blocked; bridges and maintenance paths dry",
		"archetype_status": "7 initial module families with seeded geometry/dressing; not a 30-archetype library"}
	return level


func _wet(c: Vector2i) -> void:
	level.set_tile(c, Level.Tile.WATER)
	water_below[c] = true


func _module(id: String, kind: String, center: Vector2i, ports: Array, variant: int) -> void:
	var radius := 6.0
	var pool_radius := 2.0 + channel_half * 0.65 + variant * 0.18
	for y in range(-6, 7):
		for x in range(-6, 7):
			var local := Vector2(x, y)
			var inside := local.length() <= radius
			if kind in ["sluice", "maintenance", "pump_chamber"]:
				inside = abs(x) <= 5 and abs(y) <= 4 and not (abs(x) == 5 and abs(y) == 4)
			elif kind == "settling_basin":
				inside = Vector2(x / 1.15, y / (0.85 + variant * 0.06)).length() <= radius - 0.5
			elif kind == "outfall":
				inside = Vector2(x, y * 1.15).length() <= radius
			if not inside:continue
			var c := center + Vector2i(x, y)
			level.set_tile(c, Level.Tile.FLOOR)
			var pool := local.length() <= pool_radius
			if kind == "sluice":pool = abs(y) <= channel_half and abs(x) <= 4
			if kind in ["maintenance", "pump_chamber"]:pool = abs(x) <= channel_half and abs(y) <= 1 + variant % 2
			if pool:_wet(c)
	# Mouths are standardized: 7 cells = outer dry walks plus a level-dependent channel.
	var port_records: Array = []
	for side in ports:
		var axis: Vector2i = OFFSETS[side]
		var lateral := Vector2i(-axis.y, axis.x)
		for distance in range(0, 7):
			for lane in range(-3, 4):
				var c := center + axis * distance + lateral * lane
				if abs(lane) <= channel_half:_wet(c)
				elif distance >= 3 and not water_below.has(c):level.set_tile(c, Level.Tile.FLOOR)
		var mouth := center + axis * 6
		port_records.append({"side": side, "cell": [mouth.x, mouth.y], "width": PORT_WIDTH,
			"waterline": level.water_state, "wall_face_px": 48, "bank_height_px": 8})
	modules.append({"id": id, "archetype": kind, "variant": variant,
		"purpose": {"cistern": "collect and inspect trunk flow", "rounded_junction": "combine trunk and branch drains",
		"sluice": "regulate outflow; dry bypass retained", "settling_basin": "collect sediment before discharge",
		"outfall": "receive upstream drainage", "pump_chamber": "access sump and lifting fittings",
		"maintenance": "service branch drain"}[kind],
		"origin": [center.x - 6, center.y - 6], "footprint": [13, 13], "anchor": [6, 6],
		"ports": port_records, "allowed_transforms": ["identity"], "collision": "derived from actual dry-cell mask"})


func _port(index: int, side: String) -> Dictionary:
	for port in modules[index].ports:
		if port.side == side:return port
	return {}


func _link(a: int, side_a: String, b: int, side_b: String) -> void:
	var pa := _port(a, side_a)
	var pb := _port(b, side_b)
	assert(not pa.is_empty() and not pb.is_empty())
	assert(pa.width == pb.width and pa.waterline == pb.waterline)
	var c := Vector2i(pa.cell[0], pa.cell[1])
	var end := Vector2i(pb.cell[0], pb.cell[1])
	var step := Vector2i(signi(end.x - c.x), signi(end.y - c.y))
	assert(step.x == 0 or step.y == 0, "Ports require an aligned connector")
	var lateral := Vector2i(-step.y, step.x)
	while true:
		for lane in range(-3, 4):
			var p := c + lateral * lane
			if abs(lane) <= channel_half:_wet(p)
			else:level.set_tile(p, Level.Tile.FLOOR)
		if c == end:break
		c += step
	connections.append({"a": modules[a].id, "a_side": side_a, "b": modules[b].id, "b_side": side_b,
		"from": pa.cell, "to": pb.cell, "width": PORT_WIDTH, "waterline": level.water_state,
		"wall_face_px": pa.wall_face_px, "bank_height_px": pa.bank_height_px})


func _bridge(rect: Rect2i, id: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):level.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	dressing.append({"kind": "bridge", "id": id, "origin": [rect.position.x, rect.position.y],
		"footprint": [rect.size.x, rect.size.y], "blocking": false, "supports": "both dry banks"})


func _decorate() -> void:
	# Wall-adjacent fixtures cannot obstruct the guaranteed dry network.
	for m in modules:
		var candidates: Array[Vector2i] = []
		for y in range(m.origin[1], m.origin[1] + 13):
			for x in range(m.origin[0], m.origin[0] + 13):
				var c := Vector2i(x, y)
				if level.get_tile(c) != Level.Tile.FLOOR:continue
				if [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(func(d): return level.get_tile(c + d) == Level.Tile.WALL):candidates.append(c)
		if not candidates.is_empty():
			var c: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
			dressing.append({"kind": "torch", "module": m.id, "cell": [c.x, c.y], "blocking": false, "mount": "adjacent masonry"})
			var pipe: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
			dressing.append({"kind": "pipe", "module": m.id, "cell": [pipe.x, pipe.y], "blocking": false, "mount": "adjacent masonry"})
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var wall: Vector2i = c + d
				if level.get_tile(wall) == Level.Tile.WALL:
					dressing.append({"kind": "cracked_masonry", "module": m.id, "cell": [wall.x, wall.y], "blocking": true,
						"policy": "cosmetic damage; collision unchanged"})
					break
		var center := Vector2i(m.origin[0] + 6, m.origin[1] + 6)
		dressing.append({"kind": "drain", "module": m.id, "cell": [center.x, center.y], "blocking": false, "purpose": "collection point"})
		if m.archetype == "sluice":
			dressing.append({"kind": "sluice", "module": m.id, "cell": [center.x, center.y], "blocking": false,
				"state": "open", "note": "visual gate marker; hydraulics not simulated"})


static func restore(data: Dictionary) -> SewerLevel:
	var l := SewerLevel.new(int(data.w), int(data.h))
	l.tiles = Marshalls.base64_to_raw(data.tiles)
	l.seed_value = int(data.seed)
	l.start = Vector2i(int(data.start[0]), int(data.start[1]))
	l.water_state = data.water_state
	l.assembly = data.assembly
	for m in l.assembly.modules:l.rooms.append(Rect2i(int(m.origin[0]), int(m.origin[1]), 13, 13))
	l.rebuild_paths()
	return l
