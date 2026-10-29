extends LevelView
## Acceptance corridor: newly generated material families, assembled at native pixel sizes.

const ROOT := "res://assets/tiles/sewers/fidelity-v2/"
var floors: Array[Texture2D] = []
var waters: Array[Texture2D] = []
var walls: Array[Texture2D] = []
var pieces := {}
var paving: Array[Texture2D] = []
var wear := {}
var overlays_enabled := true
var torch: Texture2D = preload("res://assets/tiles/sewers/fidelity-v2/props/torch.png")
var bridge: Texture2D = preload("res://assets/tiles/sewers/fidelity-v2/props/bridge.png")
var drain: Texture2D = preload("res://assets/tiles/sewers/fidelity-v2/props/drain.png")


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in 12:floors.append(load(ROOT + "terrain/floor_%02d.png" % i))
	for i in 4:waters.append(load(ROOT + "terrain/water_big_%d.png" % i))
	for i in 3:walls.append(load(ROOT + "masonry/deep_wall_%d.png" % i))
	for name in ["paving_0", "paving_1", "paving_2", "paving_3", "paving_4", "paving_5", "paving_small", "paving_medium"]:
		paving.append(load(ROOT + "assemblies/" + name + ".png"))
	for name in ["cracks", "damp", "salt", "moss", "chips", "silt", "repair", "seep"]:
		wear[name] = load(ROOT + "overlays/" + name + ".png")
	for name in ["deep_arch", "deep_pipe", "deep_pier", "bank_n", "arch", "pipe_wall", "pier"]:pieces[name] = load(ROOT + "masonry/" + name + ".png")
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.64, 0.70, 0.74)
	add_child(ambient)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	for at in [Vector2(8, 7.1), Vector2(22, 7.1), Vector2(34.5, 9), Vector2(12, 16)]:
		var light := PointLight2D.new()
		light.position = at * TILE
		light.texture = texture
		light.color = Color(1, 0.57, 0.20)
		light.energy = 0.85
		add_child(light)


func _draw() -> void:
	if level == null or floors.is_empty():return
	for y in level.height:
		for x in level.width:
			var tile := level.get_tile(Vector2i(x, y))
			var at := Vector2(x, y) * TILE
			if tile == Level.Tile.FLOOR:draw_texture(floors[posmod(x * 7 + y * 11, 12)], at)
			elif tile == Level.Tile.WATER:
				var variant := posmod((x / 2) * 13 + (y / 2) * 3, 4)
				draw_texture_rect_region(waters[variant], Rect2(at, Vector2(32, 32)), Rect2((x % 2) * 32, (y % 2) * 32, 32, 32), Color(0.75, 0.85, 0.85))
				if level.get_tile(Vector2i(x, y - 1)) == Level.Tile.FLOOR:
					draw_texture(pieces.bank_n, at)
				if level.get_tile(Vector2i(x, y + 1)) == Level.Tile.FLOOR:
					draw_texture_rect_region(floors[0], Rect2(at + Vector2(0, 26), Vector2(32, 6)), Rect2(0, 0, 32, 6))
	# Each surface spans 2–4 movement cells; the slabs are independent of the grid.
	_draw_walk(8, [0, 7, 6, 2, 1, 5, 7, 4, 3])
	_draw_walk(13, [5, 1, 7, 6, 0, 4, 2, 7, 3])
	if overlays_enabled:
		_draw_wear()
	var x := 4
	while x < 36:
		if x == 24:
			draw_texture(pieces.deep_arch, Vector2(x * TILE, 4 * TILE))
		else:
			draw_texture(walls[posmod(x / 4, 3)], Vector2(x * TILE, 4 * TILE))
		x += 4
	for column in [8, 22, 34]:draw_texture(pieces.deep_pipe, Vector2(column * TILE, 4 * TILE))
	for column in [12, 20, 31]:
		draw_colored_polygon(PackedVector2Array([Vector2(column*32,256),Vector2(column*32+32,256),Vector2(column*32+36,264),Vector2(column*32+4,264)]),Color(0,0,0,0.3))
		draw_texture(pieces.deep_pier, Vector2(column * TILE, 4 * TILE))
	for column in range(4, 36, 4):draw_texture(walls[posmod(column / 4 + 1, 3)], Vector2(column * TILE, 15 * TILE))
	# Side caps are deliberately separate; a complete curved-end kit is still required.
	for y in range(8, 15):
		for column in [3, 36]:draw_texture(pieces.pier, Vector2(column * TILE, y * TILE - 32))
	draw_texture(bridge, Vector2(18.5 * TILE, 9 * TILE))
	draw_texture(drain, Vector2(13 * TILE, 10.5 * TILE))
	for at in [Vector2(8, 7.1), Vector2(22, 7.1), Vector2(34.5, 9), Vector2(12, 16)]:
		draw_texture(torch, at * TILE - Vector2(16, 40))


func _draw_walk(row: int, sequence: Array) -> void:
	var column := 4
	for index in sequence:
		if column >= 36:break
		var texture := paving[index]
		var width: int = mini(texture.get_width(), (36 - column) * TILE)
		draw_texture_rect_region(texture, Rect2(column * TILE, row * TILE, width, 64), Rect2(0, 0, width, 64))
		column += width / TILE
	# A sequence can end early; continue with a full assembly rather than leave a gap.
	while column < 36:
		var width: int = mini(128, (36 - column) * TILE)
		draw_texture_rect_region(paving[0], Rect2(column * TILE, row * TILE, width, 64), Rect2(0, 0, width, 64))
		column += width / TILE


func _draw_wear() -> void:
	# Wear follows architecture: seepage at walls, damp below pipes, silt at drainage.
	# These overlays never modify the movement or collision mask.
	for mark in [
		["seep", Vector2(7.5, 8), 0.50], ["damp", Vector2(8, 8.2), 0.48],
		["salt", Vector2(11.8, 8), 0.28], ["cracks", Vector2(15, 8), 0.45],
		["moss", Vector2(20.5, 8), 0.40], ["damp", Vector2(22, 8), 0.48],
		["repair", Vector2(27, 8), 0.65], ["chips", Vector2(31, 8), 0.65],
		["moss", Vector2(6, 13), 0.40], ["silt", Vector2(12, 13), 0.45],
		["cracks", Vector2(16, 13), 0.45], ["repair", Vector2(22, 13), 0.65],
		["salt", Vector2(28, 13), 0.28], ["seep", Vector2(32, 14), 0.50]
	]:
		draw_texture(wear[mark[0]], mark[1] * TILE, Color(1, 1, 1, mark[2]))
