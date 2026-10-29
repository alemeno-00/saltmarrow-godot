class_name Lighting
extends Node2D
## The dark and the lights. The world is dimmed nearly to black (Game adds a CanvasModulate of AMBIENT); every
## lantern and brazier square in the level's blockouts gets a warm light that flickers; the Outflow's three painted
## lanterns are lit at their glass. Thomas carries his own lantern (Game adds it to the hero).
##
## The web build's renderer lights one drawn item with at most 15 lights (measured on 4.7.2), so the level and the
## blood are drawn in small chunks (LevelView, Gore), each reached by only the lights near it.

const AMBIENT := Color(0.08, 0.09, 0.12)    # what the dark leaves visible
const LANTERN := Color(1.0, 0.68, 0.32)
const LANTERN_ENERGY := 2.1
const LANTERN_RADIUS := 4.5                  # squares
const BRAZIER := Color(1.0, 0.6, 0.28)
const BRAZIER_ENERGY := 2.4
const HERO_LIGHT := Color(1.0, 0.8, 0.5)
const HERO_ENERGY := 1.3
const HERO_RADIUS := 3.5
const FLICKER := 0.06                        # how far the flame's brightness wanders
const MAX_LIGHTS_PER_ITEM := 15
const TILE := 32
## The Outflow's lantern glass, in pixels from the painted room's top-left (assets/tiles/sewers/outflow/README.md).
const OUTFLOW_GLASS: Array[Vector2] = [Vector2(48, 15), Vector2(241, 15), Vector2(400, 15)]

## ChatGPT's record of every painted room's lantern and brazier glass (room-local pixels, by blockout square).
const ROOMS_MANIFEST := "res://assets/tiles/sewers/rooms/manifest.json"
const ROOMS_ART := "res://assets/tiles/sewers/rooms/"
const WALL_LIGHT_DROP := 10.0   # a wall lantern casts from just below its glass, onto the floor

static var _tex: Texture2D = null
static var _glass := {}         # layout -> {blockout square: glass pixel}; empty until read
static var _glass_read := false

var _lights: Array[PointLight2D] = []
var _time := 0.0


## A soft round light, bright in the middle and fading to nothing at its edge.
static func light_texture() -> Texture2D:
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.25, Color(1, 1, 1, 0.75))
		g.add_point(0.6, Color(1, 1, 1, 0.18))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_tex = t
	return _tex


static func make_light(color: Color, energy: float, radius_squares: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.color = color
	l.energy = energy
	l.texture_scale = radius_squares * TILE * 2.0 / 256.0
	return l


## The painted glass of every lantern and brazier in ChatGPT's room paintings, read once from its manifest
## (exported with the web build: export_presets.cfg include_filter).
static func painted_glass() -> Dictionary:
	if not _glass_read:
		_glass_read = true
		var f := FileAccess.open(ROOMS_MANIFEST, FileAccess.READ)
		if f != null:
			var m = JSON.parse_string(f.get_as_text())
			if m is Dictionary and m.get("assets") is Dictionary:
				for layout in m.assets:
					var spots := {}
					for l in m.assets[layout].get("lights", []):
						spots[Vector2i(int(l.blockout_cell[0]), int(l.blockout_cell[1]))] = Vector2(l.glass_centre_px[0], l.glass_centre_px[1])
					_glass[layout] = spots
	return _glass


## Where a light square's light goes: on its painted glass if its room has a painting that records it,
## otherwise the middle of the square (wall lanterns just below the glass, braziers at the bowl).
static func light_position(level: Level, c: Vector2i) -> Vector2:
	var brazier := level.get_tile(c) == Level.Tile.PROP
	var drop := Vector2.ZERO if brazier else Vector2(0, WALL_LIGHT_DROP)
	for p in level.pieces:
		var r: Rect2i = p.rect
		if p.kind == "outflow" or not r.has_point(c):
			continue
		var spots: Dictionary = painted_glass().get(p.layout, {})
		if spots.is_empty() or not ResourceLoader.exists("%s%s/1.png" % [ROOMS_ART, p.layout]):
			break
		var local := c - r.position
		if p.mirrored:
			local.x = r.size.x - 1 - local.x
		if not spots.has(local):
			break
		var g: Vector2 = spots[local]
		if p.mirrored:
			g.x = r.size.x * TILE - 1 - g.x
		return Vector2(r.position) * TILE + g + drop
	return Vector2(c) * TILE + (Vector2(16, 10) if brazier else Vector2(16, 26))


## Every light in a level as [pixel position, is a brazier]: lanterns and braziers on their painted glass where a
## painting records it, and the Outflow from its painted glass.
static func light_points(level: Level) -> Array:
	var out: Array = []
	for c in level.lights:
		out.append([light_position(level, c), level.get_tile(c) == Level.Tile.PROP])
	if level.outflow.has_area():
		var origin := Vector2(level.outflow.grow(1).position) * TILE
		for g in OUTFLOW_GLASS:
			out.append([origin + g + Vector2(0, 10), false])
	return out


func build(level: Level) -> void:
	for l in _lights:
		l.queue_free()
	_lights.clear()
	for p in light_points(level):
		var l := make_light(BRAZIER if p[1] else LANTERN, BRAZIER_ENERGY if p[1] else LANTERN_ENERGY, LANTERN_RADIUS)
		l.position = p[0]
		add_child(l)
		_lights.append(l)


func light_count() -> int:
	return _lights.size()


func _process(delta: float) -> void:
	# a slow, uneven flicker, different for each flame
	_time += delta
	for i in _lights.size():
		var f := sin(_time * 3.1 + i * 1.7) * 0.5 + sin(_time * 7.3 + i * 2.9) * 0.25
		var base := BRAZIER_ENERGY if _lights[i].color == BRAZIER else LANTERN_ENERGY
		_lights[i].energy = base * (1.0 + FLICKER * f)
