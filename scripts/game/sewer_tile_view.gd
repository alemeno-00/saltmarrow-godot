extends LevelView
## Actual generated-cell renderer using prototype PNGs, not a flattened concept picture.

const FLOOR_TEX = preload("res://assets/tiles/sewers/v1_0/tiles/floor_dry.png")
const WALL_TEX = preload("res://assets/tiles/sewers/v1_0/sprites/wall_n.png")
const BRIDGE_TEX = preload("res://assets/tiles/sewers/v1_0/sprites/bridge_v.png")
const OFFSETS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
var bank_textures := {}
var fixtures := {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["torch", "pipe_h", "drain"]:
		fixtures[kind] = load("res://assets/tiles/sewers/v1_0/sprites/%s.png" % kind)


func _bank(c: Vector2i) -> Texture2D:
	var mask := 0
	for i in 8:
		if level.get_tile(c + OFFSETS[i]) != Level.Tile.WATER:mask |= 1 << i
	for pair in [[4, 0, 1], [5, 1, 2], [6, 2, 3], [7, 3, 0]]:
		if mask & (1 << pair[1]) or mask & (1 << pair[2]):mask &= ~(1 << pair[0])
	if not bank_textures.has(mask):
		bank_textures[mask] = load("res://assets/tiles/sewers/v1_0/tiles/bank_%02x.png" % mask)
	return bank_textures[mask]


func _draw() -> void:
	if level == null:return
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			var box := Rect2(Vector2(c) * TILE, Vector2.ONE * TILE)
			match level.get_tile(c):
				Level.Tile.FLOOR, Level.Tile.DOOR_OPEN, Level.Tile.DOOR_CLOSED:
					draw_texture_rect(FLOOR_TEX, box, false)
				Level.Tile.WATER:
					draw_texture_rect(_bank(c), box, false)
				Level.Tile.WALL:
					if OFFSETS.any(func(d): return level.get_tile(c + d) != Level.Tile.WALL):
						draw_texture_rect(FLOOR_TEX, box, false, Color(0.45, 0.45, 0.48))
	# Back-facing wall faces end at their collision cell, above the open floor below.
	for y in level.height - 1:
		for x in level.width:
			var c := Vector2i(x, y)
			if level.get_tile(c) == Level.Tile.WALL and level.get_tile(c + Vector2i.DOWN) != Level.Tile.WALL:
				draw_texture(WALL_TEX, Vector2(c) * TILE - Vector2(0, TILE))
	if not level is SewerLevel:return
	for fixture in (level as SewerLevel).assembly.dressing:
		if fixture.kind == "bridge":
			for y in range(fixture.origin[1], fixture.origin[1] + fixture.footprint[1]):
				for x in range(fixture.origin[0], fixture.origin[0] + fixture.footprint[0]):
					draw_texture_rect_region(BRIDGE_TEX, Rect2(x * TILE, y * TILE, TILE, TILE), Rect2(0, 16, 32, 32))
		elif fixture.kind in ["torch", "pipe", "drain"]:
			var kind: String = "pipe_h" if fixture.kind == "pipe" else fixture.kind
			var point := Vector2(fixture.cell[0], fixture.cell[1]) * TILE
			draw_texture(fixtures[kind], point - Vector2(0, 16 if kind == "torch" else 0))
