class_name UiStyle
extends RefCounted
## The one place the UI's look comes from (design/ux/hud.md, "Look"): the house palette, and ChatGPT's UI kit
## (ART_JOBS job 20) loaded from `assets/ui/` by exact path. Until a file arrives, a flat placeholder in the same
## palette stands in, so the art drops in with no other code changes.

const SLATE := Color(0.07, 0.08, 0.1, 0.94)       # panels: dark wet slate
const SLATE_LIGHT := Color(0.13, 0.14, 0.16, 0.96)
const BRASS := Color(0.55, 0.45, 0.28)           # the worn brass edge
const BRASS_DIM := Color(0.32, 0.28, 0.22)
const AMBER := Color(1.0, 0.8, 0.45)              # active, chosen
const PEARL := Color(0.82, 0.86, 0.9)             # touched by the star
const HARM := Color(0.72, 0.24, 0.2)              # stamina, wounds
const INK := Color(0.9, 0.85, 0.75)
const DIM := Color(0.6, 0.57, 0.52)

const FRAMES := "res://assets/ui/frames/"
const ICONS := "res://assets/ui/icons/"
const PORTRAITS := "res://assets/ui/portraits/"

static var _cache := {}


## A texture from the UI kit, or null until it arrives.
static func tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## An ability's (or an exploring action's) icon: assets/ui/icons/abilities/<id>.png.
static func ability_icon(id: String) -> Texture2D:
	return tex(ICONS + "abilities/%s.png" % id)


## A condition's icon: assets/ui/icons/conditions/<name>.png.
static func condition_icon(name: String) -> Texture2D:
	return tex(ICONS + "conditions/%s.png" % name)


## A face for the turn order: assets/ui/portraits/<style>.png.
static func portrait(style: String) -> Texture2D:
	return tex(PORTRAITS + "%s.png" % style)


## A frame from the kit, drawn to stretch, or a flat stand-in.
static func frame(name: String, margin: int, fill: Color, edge: Color, edge_px := 1) -> StyleBox:
	var t := tex(FRAMES + name + ".png")
	if t != null:
		var sb := StyleBoxTexture.new()
		sb.texture = t
		sb.set_texture_margin_all(margin)
		sb.set_content_margin_all(margin)
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		return sb
	var f := StyleBoxFlat.new()
	f.bg_color = fill
	f.border_color = edge
	f.set_border_width_all(edge_px)
	f.set_corner_radius_all(2)
	f.set_content_margin_all(margin)
	return f


static func panel() -> StyleBox:
	return frame("panel", 10, SLATE, BRASS)


static func panel_small() -> StyleBox:
	return frame("panel_small", 6, SLATE_LIGHT, BRASS)


## Dress a slot (ability or belt): empty, under the mouse, chosen, can't be used.
static func style_slot(b: Button) -> void:
	b.add_theme_stylebox_override("normal", frame("slot", 4, SLATE_LIGHT, BRASS_DIM))
	b.add_theme_stylebox_override("hover", frame("slot_hover", 4, SLATE_LIGHT, AMBER))
	b.add_theme_stylebox_override("pressed", frame("slot_active", 4, SLATE_LIGHT, AMBER, 2))
	b.add_theme_stylebox_override("disabled", frame("slot_disabled", 4, Color(0.05, 0.05, 0.06, 0.9), Color(0.2, 0.19, 0.18)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_text_colours(b)


## Dress a text button (Journal, Menu, Wake...).
static func style_button(b: Button, end_turn := false) -> void:
	var n := "button_end_turn" if end_turn else "button"
	var m := 10 if end_turn else 6
	var edge := AMBER if end_turn else BRASS
	b.add_theme_stylebox_override("normal", frame(n, m, SLATE_LIGHT, edge))
	b.add_theme_stylebox_override("hover", frame(n + "_hover", m, Color(0.18, 0.17, 0.16, 0.96), AMBER))
	b.add_theme_stylebox_override("pressed", frame(n + "_pressed", m, Color(0.24, 0.2, 0.14, 0.96), AMBER, 2))
	b.add_theme_stylebox_override("disabled", frame("button_disabled", m, Color(0.05, 0.05, 0.06, 0.9), Color(0.2, 0.19, 0.18)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_text_colours(b, end_turn)


static func _text_colours(b: Button, amber := false) -> void:
	b.add_theme_color_override("font_color", AMBER if amber else INK)
	b.add_theme_color_override("font_hover_color", AMBER)
	b.add_theme_color_override("font_pressed_color", AMBER)
	b.add_theme_color_override("font_disabled_color", Color(0.38, 0.36, 0.33))
