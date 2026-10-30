class_name CoverProp
extends Node2D
## A crate or barrel standing in a room (a COVER square): ChatGPT's art from assets/props/sewers/ (job 14), the first
## frame (closed). It sits among the creatures, sorted by its base, so someone standing behind it is hidden by it.
## Low cover for sneaking: design/quick-specs/sneaking-2026-10-30.md.

const TILE := 32
const ART := "res://assets/props/sewers/%s.png"
const BASE := 10.0   # px below the square's middle where its base is (the sort line, as a creature's feet)

static var _tex := {}

var kind := "crate"


static func spawn(parent: Node, c: Vector2i, what: String) -> CoverProp:
	var p := CoverProp.new()
	p.kind = what
	p.position = MovementRules.centre(c) + Vector2(0, BASE)
	parent.add_child(p)
	return p


func _draw() -> void:
	var tex := _art(kind)
	var top := Vector2(-TILE / 2.0, -TILE / 2.0 - BASE)
	if tex != null:
		# the sheet is two 32 x 32 frames: closed, opened
		draw_texture_rect_region(Grounding.lit(tex), Rect2(top, Vector2(TILE, TILE)), Rect2(0, 0, TILE, TILE))
	else:
		draw_rect(Rect2(top + Vector2(5, 8), Vector2(22, 22)), Color(0.32, 0.22, 0.13))
		draw_rect(Rect2(top + Vector2(5, 8), Vector2(22, 22)), Color(0.15, 0.1, 0.06), false, 1.0)


static func _art(what: String) -> Texture2D:
	if not _tex.has(what):
		var path := ART % what
		_tex[what] = load(path) if ResourceLoader.exists(path) else null
	return _tex[what]
