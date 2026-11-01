extends TestBase
## The painted-walk guides (tools/pose_guides/walk_guides.gd, ART_JOBS 15-W): Thomas's whole body moves through the
## walk with the body near its standing height; a painting at 4 × shrinks back onto the model's own colours; the
## checker passes a frame that follows the guide and catches a swapped leg, a wandering outline or a different head.

const TOOL := "res://tools/pose_guides/walk_guides.gd"


func _tool() -> GDScript:
	return load(TOOL)


func _guide() -> Image:
	var t := _tool()
	return t.guide(t._img(t.PARTS))


## A sheet as ChatGPT would deliver it: row 1 the model six times, row 2 the walk frames given.
func _sheet(walk: Image) -> Image:
	var t := _tool()
	var model: Image = t._img(t.MODEL)
	var s := Image.create(640, 160, false, Image.FORMAT_RGBA8)
	for i in 6:
		s.blit_rect(model, Rect2i(0, 0, 80, 80), Vector2i(i * 80, 0))
	s.blit_rect(walk, Rect2i(0, 0, 640, 80), Vector2i(0, 80))
	return s


func test_the_body_hardly_rises_or_falls_so_standing_to_walking_has_no_jump() -> void:
	for d in _tool().frame_data():
		var s: Array = d.body_shift
		check(absi(int(s[0])) <= 1 and absi(int(s[1])) <= 1, "frame %d: the body moves a pixel at most (%s)" % [d.frame, s])


func test_the_legs_take_turns_and_the_arms_swing_against_them() -> void:
	var data: Array = _tool().frame_data()
	for d in data:
		check(d.left.planted or d.right.planted, "frame %d: a foot is always on the floor" % d.frame)
	check(data[2].left.planted and not data[2].right.planted, "frame 3: the left stands, the right swings")
	check(data[6].right.planted and not data[6].left.planted, "frame 7: and the other way round")
	check(data[0].left.forward_px > 0 and data[0].left.hand_forward_px < 0, "frame 1: left foot ahead, left arm back")
	check(data[0].right.forward_px < 0 and data[0].right.hand_forward_px > 0, "and the right the other way")


func test_a_4x_painting_shrinks_back_onto_the_models_colours() -> void:
	var t := _tool()
	var g := _guide()
	var big: Image = g.duplicate()
	big.resize(g.get_width() * 4, g.get_height() * 4, Image.INTERPOLATE_NEAREST)
	# a painter's slight colour drift: every pixel nudged
	for y in range(0, big.get_height(), 3):
		for x in range(0, big.get_width(), 2):
			var c := big.get_pixel(x, y)
			if c.a > 0.5:
				big.set_pixel(x, y, Color(minf(c.r + 0.02, 1.0), c.g, maxf(c.b - 0.02, 0.0), 1.0))
	var back: Image = t.shrink(big, t._img(t.MODEL))
	var diff := 0
	for y in g.get_height():
		for x in g.get_width():
			if g.get_pixel(x, y).to_rgba32() != back.get_pixel(x, y).to_rgba32():
				diff += 1
	eq(diff, 0, "shrunk, every pixel is the model's own colour again, in its place")


func test_the_guide_itself_passes_the_check() -> void:
	var r: Dictionary = _tool().check(_sheet(_guide()))
	check(r.ok, "the guide passes:\n%s" % "\n".join(r.lines))


func test_a_swapped_leg_fails() -> void:
	var g := _guide()
	var other := _guide()
	for y in range(56, 80):   # frame 3 gets frame 7's legs: the wrong foot lifted
		for x in 80:
			g.set_pixel(2 * 80 + x, y, other.get_pixel(6 * 80 + x, y))
	check(not _tool().check(_sheet(g)).ok, "the wrong foot lifted is caught")


func test_a_different_head_fails() -> void:
	var g := _guide()
	for y in range(20, 30):   # frame 2's head repainted another colour
		for x in range(36, 45):
			if g.get_pixel(80 + x, y).a > 0.5:
				g.set_pixel(80 + x, y, Color8(120, 160, 90))
	check(not _tool().check(_sheet(g)).ok, "a head that isn't his is caught")


func test_an_outline_that_wanders_fails() -> void:
	var g := _guide()
	var moved := Image.create(640, 80, false, Image.FORMAT_RGBA8)
	moved.blit_rect(g, Rect2i(0, 0, 640, 80), Vector2i.ZERO)
	moved.blit_rect(g, Rect2i(4 * 80, 0, 80, 80), Vector2i(4 * 80 + 6, 0))   # frame 5 painted 6 px off
	check(not _tool().check(_sheet(moved)).ok, "a frame painted out of place is caught")
