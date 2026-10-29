extends Node2D
## Inspect the generic generator or the dedicated drainage-first sewer assembler.

const CELL := 16
const ORIGIN := Vector2(32, 100)
const FLOOR = preload("res://assets/tiles/sewers/v1_0/tiles/floor_dry.png")
const WATER = preload("res://assets/tiles/sewers/v1_0/tiles/water_0.png")
var level: Level
var seed_value := 1
var textured := false
var route: Array[Vector2i] = []
var info: Label
var details: Label
@export var sewer_mode := false
var water_state := "normal"
var cell_px := CELL


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	info = Label.new()
	info.position = Vector2(32, 16)
	info.add_theme_font_size_override("font_size", 20)
	add_child(info)
	details = Label.new()
	details.position = Vector2(1010, 100)
	details.add_theme_font_size_override("font_size", 15)
	add_child(details)
	regenerate()


func regenerate() -> void:
	cell_px = 14 if sewer_mode else CELL
	if sewer_mode:level = SewerAssembler.new().generate(seed_value, water_state)
	else:
		level = Level.new()
		level.generate(seed_value)
	var destination := _destination()
	route = level.find_path(level.start, destination)
	info.text = "%s | Seed %d | R/Right next  Left previous  S mode  T textures  P route  L/N/H water" % ["SEWER ASSEMBLY" if sewer_mode else "GENERIC TEST", seed_value]
	var seen := level.reachable_from(level.start)
	details.text = "Generic generator\n\n60 x 40 cells\n32px game grid\n50%% overview scale\n\n%d rooms\n%d reachable cells\n%d route steps\n\nWHITE: dry floor\nBLUE: walkable water\nAMBER: closed door\nGREEN: start\nCYAN: route\n\nClick: inspect cell\n\nS: sewer assembler\nOther biome grammars\nare not implemented.\n\nTextures are the old\nMVP preview assets,\nnot concept-quality\nproduction art." % [level.rooms.size(), seen.size(), route.size()]
	if sewer_mode:
		details.text = "SEWER GRAMMAR\nWater: %s\n\n60 x 44 cells\n32px game grid\n\n5 functional modules\n4 matched connections\n2 supported bridges\n%d dry reachable cells\n\nBLUE: blocked water\nWHITE: dry walk\nCYAN: dry AStar route\nGREEN: start\nAMBER: wall fixture\n\nL: low water\nN: normal water\nH: high water\nS: generic comparison\n\nInitial 7 families;\nnot 30 archetypes.\nFixed trunk/branches,\nseeded basin variants.\n\nNo hydraulic sim.\nTextures: old MVP,\nnot final art." % [water_state, seen.size()]
	queue_redraw()


func _destination() -> Vector2i:
	return Vector2i(30, 39) if sewer_mode else level.rooms[-1].get_center()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R, KEY_RIGHT:
				seed_value += 1
				regenerate()
			KEY_LEFT:
				seed_value = maxi(1, seed_value - 1)
				regenerate()
			KEY_T:
				textured = not textured
				queue_redraw()
			KEY_P:
				route = [] if not route.is_empty() else level.find_path(level.start, _destination())
				queue_redraw()
			KEY_S:
				sewer_mode = not sewer_mode
				regenerate()
			KEY_L, KEY_N, KEY_H:
				water_state = {KEY_L: "low", KEY_N: "normal", KEY_H: "high"}[event.keycode]
				if sewer_mode:regenerate()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := Vector2i((get_global_mouse_position() - ORIGIN) / cell_px)
		if level.in_bounds(c):
			info.text = "Seed %d | Cell %s | tile %d | walkable %s | R/Right next, Left previous, T textures, P route" % [seed_value, c, level.get_tile(c), level.is_walkable(c)]


func _draw() -> void:
	if level == null:return
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			var box := Rect2(ORIGIN + Vector2(c) * cell_px, Vector2(cell_px, cell_px))
			var tile := level.get_tile(c)
			var color := Color("11181e")
			match tile:
				Level.Tile.FLOOR:color = Color("a8aaa2")
				Level.Tile.WATER:color = Color("256e8c")
				Level.Tile.DOOR_CLOSED:color = Color("c39245")
				Level.Tile.DOOR_OPEN:color = Color("755b37")
			if textured and tile in [Level.Tile.FLOOR, Level.Tile.WATER]:
				draw_texture_rect(WATER if tile == Level.Tile.WATER else FLOOR, box, false)
			else:draw_rect(box.grow(-0.5), color)
	for cell in route:
		draw_circle(ORIGIN + Vector2(cell) * cell_px + Vector2.ONE * cell_px / 2, 2, Color.CYAN)
	draw_rect(Rect2(ORIGIN + Vector2(level.start) * cell_px, Vector2.ONE * cell_px).grow(-2), Color.GREEN, false, 2)
	for room in level.rooms:
		draw_rect(Rect2(ORIGIN + Vector2(room.position) * cell_px, Vector2(room.size) * cell_px), Color(0.9, 0.7, 0.3, 0.5), false, 1)
	if sewer_mode:
		var sewer := level as SewerLevel
		for fixture in sewer.assembly.dressing:
			if fixture.has("cell"):
				var at := ORIGIN + Vector2(fixture.cell[0], fixture.cell[1]) * cell_px + Vector2.ONE * cell_px / 2
				draw_circle(at, 3 if fixture.kind == "torch" else 2, Color.ORANGE if fixture.kind == "torch" else Color("755b37"))
