class_name CoverProp
extends Node2D
## Something standing in a room, drawn with ChatGPT's art from assets/props/sewers/ (job 14) and sorted among the
## creatures by its base, so someone standing behind it is hidden by it:
## - a crate or barrel (low cover for sneaking; a cache if it holds something): closed, then opened;
## - a satchel on a drowned miner, in a drained basin (a cache): closed, then searched; two squares wide;
## - the sluice valve on its standpipe: four frames, turning;
## - an iron grate across a tunnel (`grate_ns` across a north-south tunnel, `grate_ew` across an east-west one):
##   shut, then open, each a row of two frames.

const TILE := 32
const ART := "res://assets/props/sewers/%s.png"
const BASE := 10.0   # px below the square's middle where its base is (the sort line, as a creature's feet)
## kind -> frame size
const FRAME := {"crate": Vector2(32, 32), "barrel": Vector2(32, 32), "satchel": Vector2(64, 32), "valve": Vector2(32, 32),
	"grate_ns": Vector2(64, 32), "grate_ew": Vector2(32, 64)}
const ART_NAME := {"satchel": "satchel_body"}
const TURN_TIME := 1.6   # s the valve turns for

static var _tex := {}

var kind := "crate"
var opened := false      # a searched cache, an open grate
var _turning := 0.0


static func spawn(parent: Node, c: Vector2i, what: String, at := Vector2.INF) -> CoverProp:
	var p := CoverProp.new()
	p.kind = what
	p.position = (MovementRules.centre(c) if at == Vector2.INF else at) + Vector2(0, BASE)
	parent.add_child(p)
	return p


## Show it opened (a cache searched, a grate unlocked).
func open() -> void:
	opened = true
	queue_redraw()


## The valve: turn it.
func turn() -> void:
	_turning = TURN_TIME


func _process(delta: float) -> void:
	if _turning > 0.0:
		_turning = maxf(0.0, _turning - delta)
		queue_redraw()


func _draw() -> void:
	var size: Vector2 = FRAME.get(kind, Vector2(TILE, TILE))
	var top := Vector2(-size.x / 2.0, -size.y / 2.0 - BASE)
	var tex := _art(kind)
	if tex == null:
		draw_rect(Rect2(top + Vector2(5, 8), size - Vector2(10, 10)), Color(0.32, 0.22, 0.13))
		draw_rect(Rect2(top + Vector2(5, 8), size - Vector2(10, 10)), Color(0.15, 0.1, 0.06), false, 1.0)
		return
	var src := Rect2(Vector2.ZERO, size)
	match kind:
		"valve":
			src.position.x = size.x * (int((TURN_TIME - _turning) * 8.0) % 4 if _turning > 0.0 else 0)
		"grate_ns", "grate_ew":
			src.position.y = size.y if opened else 0.0
		_:
			src.position.x = size.x if opened else 0.0
	draw_texture_rect_region(Grounding.lit(tex), Rect2(top, size), src)


static func _art(what: String) -> Texture2D:
	if not _tex.has(what):
		var path := ART % ART_NAME.get(what, what)
		_tex[what] = load(path) if ResourceLoader.exists(path) else null
	return _tex[what]
