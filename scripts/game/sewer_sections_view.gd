extends LevelView
## Whole-section ground/back-wall paintings plus separately composited foregrounds.

var surfaces := {}
var foregrounds := {}
var foreground_root: Node2D
var debug_mask := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for id in ["corridor", "junction", "cistern"]:
		surfaces[id] = load(SewerSections.ROOT + id + "/ground.png")
		foregrounds[id] = load(SewerSections.ROOT + id + "/foreground.png")
	foreground_root = Node2D.new()
	foreground_root.name = "SectionForeground"
	foreground_root.z_index = 20
	add_child(foreground_root)


func show_level(l: Level) -> void:
	super.show_level(l)
	if foreground_root == null or not l is SewerLevel:return
	for child in foreground_root.get_children():
		foreground_root.remove_child(child)
		child.queue_free()
	for section in (l as SewerLevel).assembly.sections:
		var sprite := Sprite2D.new()
		sprite.texture = foregrounds[section.id]
		sprite.centered = false
		sprite.position = Vector2(section.cell_origin[0], section.cell_origin[1]) * TILE
		foreground_root.add_child(sprite)


func _draw() -> void:
	if not level is SewerLevel:return
	for section in (level as SewerLevel).assembly.sections:
		draw_texture(surfaces[section.id], Vector2(section.cell_origin[0], section.cell_origin[1]) * TILE)
	if debug_mask:
		for y in level.height:
			for x in level.width:
				var cell := Vector2i(x, y)
				var color := Color(0.2, 1, 0.4, 0.25) if level.is_walkable(cell) else Color(1, 0.1, 0.1, 0.16)
				if level.get_tile(cell) == Level.Tile.WATER:color = Color(0.1, 0.5, 1, 0.35)
				draw_rect(Rect2(Vector2(cell) * TILE, Vector2(TILE, TILE)), color)
