class_name RoomLayout
extends RefCounted
## One room or connector layout, read from its blockout image (scripts/levels/sewers/layouts/<id>.png).
## The blockout is the data: the game builds the room's squares from it and ChatGPT paints over the same image.
## Colours: design/art-briefs/README.md. The images are drawn by tools/blockouts/sewer_layouts.gd.
##
## Each square becomes one character:
##   #  wall top    F  wall face    .  floor    ,  raised walkway    ~  shallow water    P  blocking prop
##   r  railing     D  door         X  special fixture    S  stairs down    L  wall face with a lantern
##   B  prop with a standing light    w  deep sewage    d  door through deep sewage

const DIR := "res://scripts/levels/sewers/layouts/"
const T := 32
const BASE := {
	"#": Color("3a3a42"), "F": Color("6a6a76"), ".": Color("b8b2a4"), ",": Color("d8d0bc"), "~": Color("2f7f9a"),
	"P": Color("7a4f2a"), "r": Color("8e5aa8"), "D": Color("3fae5a"), "X": Color("c0392b"), "S": Color("4b3f6b"),
	"w": Color("5c4b23"), "d": Color("1f6e3a"),
}
const LANTERN := Color("f1c40f")
const BRAZIER := Color("e67e22")

static var _cache := {}

var id := ""
var size := Vector2i.ZERO      # in squares
var cells: Array[String] = []  # row by row
var doors: Array[String] = []  # sides with a door: "n", "e", "s", "w"
var lights: Array[Vector2i] = []
var stairs := Vector2i(-1, -1)


## The layout called `id`, or null if it has no blockout.
static func get_layout(layout_id: String) -> RoomLayout:
	if _cache.has(layout_id):
		return _cache[layout_id]
	var path := DIR + layout_id + ".png"
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var lay := RoomLayout.new()
	lay.id = layout_id
	lay._read(tex.get_image())
	_cache[layout_id] = lay
	return lay


func _read(img: Image) -> void:
	if img.is_compressed():
		img.decompress()
	size = Vector2i(img.get_width() / T, img.get_height() / T)
	cells.clear()
	for y in size.y:
		for x in size.x:
			# the square's colour away from its grid line, and the middle where a light mark sits
			var code := _nearest(img.get_pixel(x * T + 4, y * T + 4))
			var mid := img.get_pixel(x * T + 15, y * T + 14)
			if code == "F" and _close(mid, LANTERN):
				code = "L"
			elif code == "P" and _close(mid, BRAZIER):
				code = "B"
			cells.append(code)
			var c := Vector2i(x, y)
			if code == "L" or code == "B":
				lights.append(c)
			elif code == "S":
				stairs = c
	for side in ["n", "e", "s", "w"]:
		for c in _edge(side):
			if cell(c) == "D" or cell(c) == "d":
				doors.append(side)
				break


static func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.12


static func _nearest(c: Color) -> String:
	var best := "#"
	var best_d := INF
	for k in BASE:
		var b: Color = BASE[k]
		var d := absf(c.r - b.r) + absf(c.g - b.g) + absf(c.b - b.b)
		if d < best_d:
			best_d = d
			best = k
	return best


func cell(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= size.x or c.y >= size.y:
		return "#"
	return cells[c.y * size.x + c.x]


func _edge(side: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	match side:
		"n":
			for x in size.x:
				out.append(Vector2i(x, 0))
		"s":
			for x in size.x:
				out.append(Vector2i(x, size.y - 1))
		"w":
			for y in size.y:
				out.append(Vector2i(0, y))
		"e":
			for y in size.y:
				out.append(Vector2i(size.x - 1, y))
	return out


## Which side a door square belongs to. A room's north door runs two squares deep through the thick wall.
func door_side(c: Vector2i) -> String:
	if c.y == 0 or (size.x > 4 and c.y == 1 and cell(Vector2i(c.x, 0)) == "D"):
		return "n"
	if c.y == size.y - 1:
		return "s"
	if c.x == 0:
		return "w"
	return "e"


## The door sides, as they are once the layout is mirrored left to right.
func sides(mirrored: bool) -> Array[String]:
	if not mirrored:
		return doors
	var out: Array[String] = []
	for s in doors:
		out.append({"e": "w", "w": "e"}.get(s, s))
	return out
