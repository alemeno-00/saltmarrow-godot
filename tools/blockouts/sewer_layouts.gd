extends SceneTree
## Draws the Sewers room-kit blockouts from the text layouts below:
##   godot --headless --path . -s tools/blockouts/sewer_layouts.gd
## Writes one PNG per layout to scripts/levels/sewers/layouts/. The game reads those images as the rooms'
## layouts, and ChatGPT paints over the same images (design/art-briefs/README.md). Edit the text here, then
## run this again; never edit the PNGs by hand.
##
## One character per 32 x 32 square:
##   #  wall top        F  wall face        .  floor          ,  raised walkway   ~  shallow water
##   P  blocking prop   r  railing          D  door           X  special fixture  S  stairs down
##   L  wall face with a lantern            B  prop with a standing light (brazier)
##   w  deep sewage (waist deep)            d  door through deep sewage
##
## Door standard (design/quick-specs/sewer-room-kit-2026-10-29.md): doors are 2 squares wide, in squares 5-6 of
## a side for rooms (the side's middle block, the later one when there are two), squares 1-2 for connectors.
## North walls of rooms are two squares thick. Rooms have doors on every side; the generator walls off unused ones.

const OUT := "res://scripts/levels/sewers/layouts/"
const T := 32
const COLOURS := {
	"#": Color("3a3a42"), "F": Color("6a6a76"), ".": Color("b8b2a4"), ",": Color("d8d0bc"), "~": Color("2f7f9a"),
	"P": Color("7a4f2a"), "r": Color("8e5aa8"), "D": Color("3fae5a"), "X": Color("c0392b"), "S": Color("4b3f6b"),
	"L": Color("6a6a76"), "B": Color("7a4f2a"), "w": Color("5c4b23"), "d": Color("1f6e3a"),
}
const MARKS := {"L": Color("f1c40f"), "B": Color("e67e22")}

const ROOMS := {
	"entry": [
		"FLXXFDDF",
		"FFXXFDDF",
		"#......#",
		"#......#",
		"#......#",
		"D......D",
		"D......D",
		"#####DD#",
	],
	"stairs": [
		"FFFLFDDF",
		"FFFFFDDF",
		"#......#",
		"#......#",
		"#...S..#",
		"D......D",
		"D......D",
		"#####DD#",
	],
	"lore_a": [
		"FFXXFDDF",
		"FFXXFDDF",
		"#B.....#",
		"#......#",
		"#.....B#",
		"D......D",
		"D......D",
		"#####DD#",
	],
	"lore_b": [
		"FFFLFDDF",
		"FFFFFDDF",
		"#PP....#",
		"#P.....#",
		"#......#",
		"D......D",
		"D......D",
		"#####DD#",
	],
	"junction_a": [
		"FLFFFDDFFFLF",
		"FFFFFDDFFFFF",
		"#..........#",
		"#..P....P..#",
		"#..........#",
		"D..........D",
		"D..........D",
		"#..........#",
		"#..B....B..#",
		"#..........#",
		"#..........#",
		"#####DD#####",
	],
	"junction_b": [
		"FFFLFDDFLFFF",
		"FFFFFDDFFFFF",
		"#,,,,,,,,,,#",
		"#,........,#",
		"#,.~~~~~~.,#",
		"D,.~~~~~~.,D",
		"D,.~~~~~~.,D",
		"#,.~~~~~~.,#",
		"#,........,#",
		"#,.B....B.,#",
		"#,,,,,,,,,,#",
		"#####DD#####",
	],
	"junction_c": [
		"FLFFFDDFFFLF",
		"FFFFFDDFFFFF",
		"#PP......PP#",
		"#PP......PP#",
		"#..........#",
		"D...rrrr...D",
		"D...r~~r...D",
		"#...r~~r...#",
		"#...r..r...#",
		"#B........B#",
		"#..........#",
		"#####DD#####",
	],
	"chamber_a": [
		"FLFFFDDFFFLF",
		"FFFFFDDFFFFF",
		"#..........#",
		"#.P......P.#",
		"#..........#",
		"D..........D",
		"D..........D",
		"#####DD#####",
	],
	"chamber_b": [
		"FFFLFDDFLFFF",
		"FFFFFDDFFFFF",
		"#..........#",
		"#~~~~..~~~~#",
		"#~~~~..~~~~#",
		"D..........D",
		"D..........D",
		"#####DD#####",
	],
	"chamber_c": [
		"FLFFFDDF",
		"FFFFFDDF",
		"#......#",
		"#.P....#",
		"#......#",
		"D......D",
		"D......D",
		"#......#",
		"#....B.#",
		"#......#",
		"#......#",
		"#####DD#",
	],
	"flooded_a": [
		"FLFFFDDFFFLF",
		"FFFFFDDFFFFF",
		"#,,,,,,,,,,#",
		"#,~~~~~~~~,#",
		"#,~~~~~~~~,#",
		"D,~~~~~~~~,D",
		"D,~~~~~~~~,D",
		"#,~~~~~~~~,#",
		"#,~~~~~~~~,#",
		"#,~B~~~~B~,#",
		"#,,,,,,,,,,#",
		"#####DD#####",
	],
	"flooded_b": [
		"FFFLFDDFLFFF",
		"FFFFFDDFFFFF",
		"#..........#",
		"#...~~~~...#",
		"#..~~~~~~..#",
		"D.~~~~~~~~.D",
		"D.~~~~~~~~.D",
		"#..~~~~~~..#",
		"#...~~~~...#",
		"#B........B#",
		"#..........#",
		"#####DD#####",
	],
}


## A 4 x 4 connector with doors on the given sides ("n", "e", "s", "w"): a 2-square walkway between walls.
static func connector(sides: String) -> Array[String]:
	var g: Array = []
	for y in 4:
		var row: Array[String] = []
		for x in 4:
			row.append("#")
		g.append(row)
	for y in [1, 2]:
		for x in [1, 2]:
			g[y][x] = "."
	if "n" in sides:
		g[0][1] = "D"
		g[0][2] = "D"
		g[1][1] = "."
	else:
		for x in 4:
			g[0][x] = "F"
	if "s" in sides:
		g[3][1] = "D"
		g[3][2] = "D"
	if "w" in sides:
		g[1][0] = "D"
		g[2][0] = "D"
	if "e" in sides:
		g[1][3] = "D"
		g[2][3] = "D"
	var out: Array[String] = []
	for row in g:
		out.append("".join(row))
	return out


## A 4 x 4 block of a long sewage tunnel (design/quick-specs/deep-sewage-tunnels-2026-10-30.md): the 2-square
## walkway is waist-deep sewage, or, with `ledge` ("w", "e" for a north-south tunnel; "n", "s" for an east-west one),
## one side is a narrow raised ledge above the other. Straight only: a tunnel is a run of these.
static func sewage(axis: String, ledge := "") -> Array[String]:
	var g: Array = []
	for row in connector(axis):
		var cells: Array[String] = []
		for ch in row:
			cells.append(ch)
		g.append(cells)
	for y in 4:
		for x in 4:
			var lane := x if axis == "ns" else y   # which column (or row) of the walkway
			var in_way: bool = (lane == 1 or lane == 2)
			if not in_way or not (g[y][x] == "." or g[y][x] == "D"):
				continue
			var on_ledge: bool = (ledge == "w" and x == 1) or (ledge == "e" and x == 2) or (ledge == "n" and y == 1) or (ledge == "s" and y == 2)
			if on_ledge:
				g[y][x] = "D" if g[y][x] == "D" else ","
			else:
				g[y][x] = "d" if g[y][x] == "D" else "w"
	var out: Array[String] = []
	for row in g:
		out.append("".join(row))
	return out


## Every sewage tunnel block: plain, and with a ledge on either side.
static func sewage_names() -> Array:
	return [["ns", ""], ["ns", "w"], ["ns", "e"], ["ew", ""], ["ew", "n"], ["ew", "s"]]


## Every connector shape: straight, bend, T, crossing and dead end, in each orientation.
static func connector_names() -> Array[String]:
	return ["ew", "ns", "ne", "nw", "es", "sw", "new", "nes", "esw", "nsw", "nesw", "n", "e", "s", "w"] as Array[String]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id in ROOMS:
		_write(id, ROOMS[id])
	for sides in connector_names():
		_write("connector_" + sides, connector(sides))
	for s in sewage_names():
		_write("sewage_" + s[0] + ("_" + s[1] if s[1] != "" else ""), sewage(s[0], s[1]))
	quit()


func _write(id: String, rows: Array) -> void:
	var h := rows.size()
	var w: int = rows[0].length()
	var img := Image.create(w * T, h * T, false, Image.FORMAT_RGBA8)
	for y in h:
		assert(rows[y].length() == w, "%s row %d is %d wide, not %d" % [id, y, rows[y].length(), w])
		for x in w:
			var ch: String = rows[y][x]
			img.fill_rect(Rect2i(x * T, y * T, T, T), COLOURS[ch])
			if MARKS.has(ch):
				img.fill_rect(Rect2i(x * T + 12, y * T + 10, 8, 10), MARKS[ch])
			# a faint grid line on the left and top of each square, as a guide for painting
			img.fill_rect(Rect2i(x * T, y * T, T, 1), COLOURS[ch].darkened(0.25))
			img.fill_rect(Rect2i(x * T, y * T, 1, T), COLOURS[ch].darkened(0.25))
	img.save_png(OUT + id + ".png")
	print("wrote %s (%d x %d)" % [id, w, h])
