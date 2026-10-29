class_name SewerSections
extends RefCounted
## Three authored map sections. Only their order changes; geometry is never rotated.

const ROOT := "res://assets/tiles/sewers/sections-v1/"
const ORDERS := [["corridor", "junction", "cistern"], ["cistern", "corridor", "junction"]]


static func manifest() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))


static func build(arrangement: int) -> SewerLevel:
	var data := manifest()
	var order: Array = ORDERS[posmod(arrangement, ORDERS.size())]
	var total_width := 0
	for id in order:total_width += int(data.sections[id].cells[0])
	var level := SewerLevel.new(total_width, int(data.height_cells))
	level.seed_value = arrangement
	var placed: Array = []
	var offset := 0
	for i in order.size():
		var id: String = order[i]
		var module: Dictionary = data.sections[id]
		var size := Vector2i(module.cells[0], module.cells[1])
		for y in size.y:
			var row: String = module.ground[y]
			for x in size.x:
				var tile := Level.Tile.WALL
				if row[x] == ".":tile = Level.Tile.FLOOR
				elif row[x] == "~":tile = Level.Tile.WATER
				level.set_tile(Vector2i(offset + x, y), tile)
		placed.append({"id": id, "cell_origin": [offset, 0], "rotation": 0})
		offset += size.x
	level.start = Vector2i(2, data.start_row)
	level.rooms = [Rect2i(0, 0, level.width, level.height)]
	level.assembly = {"approach": "authored large sections", "arrangement": posmod(arrangement, 2), "sections": placed}
	level.rebuild_paths()
	return level
