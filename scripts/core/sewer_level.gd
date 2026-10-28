class_name SewerLevel
extends Level
## Deep sewer water is not a movement surface. Bridges remain FLOOR with water below.

var assembly: Dictionary = {}
var water_state := "normal"


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and get_tile(c) in [Tile.FLOOR, Tile.DOOR_CLOSED, Tile.DOOR_OPEN]


func set_tile(c: Vector2i, tile: int) -> void:
	super.set_tile(c, tile)
	if _astar.region.has_point(c):_astar.set_point_solid(c, not is_walkable(c))


func to_dict() -> Dictionary:
	var data := super.to_dict()
	data["biome"] = "sewers"
	data["water_state"] = water_state
	data["assembly"] = assembly
	return data
