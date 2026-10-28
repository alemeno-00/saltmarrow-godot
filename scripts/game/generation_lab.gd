extends Node2D
## Read-only visual inspection of Claude's existing generator. No alternate generation rules.

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
	level = Level.new()
	level.generate(seed_value)
	route = level.find_path(level.start, level.rooms[-1].get_center())
	info.text = "GENERATOR TEST  |  Seed %d  |  R / Right: next   Left: previous   T: textures   P: route" % seed_value
	var seen := level.reachable_from(level.start)
	details.text = "Generic generator\n\n60 x 40 cells\n32px game grid\n50%% overview scale\n\n%d rooms\n%d reachable cells\n%d route steps\n\nWHITE: dry floor\nBLUE: walkable water\nAMBER: closed door\nGREEN: start\nCYAN: route\n\nClick: inspect cell\n\nNo biome selector:\nsix biome grammars\nare not implemented.\n\nTextures are the old\nMVP preview assets,\nnot concept-quality\nproduction art." % [level.rooms.size(), seen.size(), route.size()]
	queue_redraw()


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
				route = [] if not route.is_empty() else level.find_path(level.start, level.rooms[-1].get_center())
				queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := Vector2i((get_global_mouse_position() - ORIGIN) / CELL)
		if level.in_bounds(c):
			info.text = "Seed %d | Cell %s | tile %d | walkable %s | R/Right next, Left previous, T textures, P route" % [seed_value, c, level.get_tile(c), level.is_walkable(c)]


func _draw() -> void:
	if level == null:return
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			var box := Rect2(ORIGIN + Vector2(c) * CELL, Vector2(CELL, CELL))
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
		draw_circle(ORIGIN + Vector2(cell) * CELL + Vector2.ONE * CELL / 2, 2, Color.CYAN)
	draw_rect(Rect2(ORIGIN + Vector2(level.start) * CELL, Vector2.ONE * CELL).grow(-2), Color.GREEN, false, 2)
	for room in level.rooms:
		draw_rect(Rect2(ORIGIN + Vector2(room.position) * CELL, Vector2(room.size) * CELL), Color(0.9, 0.7, 0.3, 0.5), false, 1)
