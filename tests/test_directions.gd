extends TestBase
## Characters drawn in five directions (art job 15, design/art-briefs/animation/BRIEF.md): the game picks the sheet
## for the way a character faces, mirrors the west side, falls back to the nearest drawn direction while some are
## missing, and to the old right-facing sheet for rows the new art doesn't have yet. Uses stand-in sheets.


## A stand-in sheet the size of a real one, frame `f`.
func _fake(f: Vector2) -> Sheet:
	var s := Sheet.new()
	var img := Image.create(int(f.x) * 8, int(f.y) * 5, false, Image.FORMAT_RGBA8)
	s.texture = ImageTexture.create_from_image(img)
	return s


## Directional stand-ins for the given directions, with the job 15 rows and frame size.
func _dirs(which: Array) -> Dictionary:
	var out := {}
	for d in which:
		var s := _fake(Sheet.DIR_FRAME)
		s.frame = Sheet.DIR_FRAME
		s.root = Sheet.DIR_ROOT
		s._add("idle", 1, 6, 6)
		s._add("walk", 2, 8, 10)
		out[d] = s
	return out


func _view(which: Array) -> ActorView:
	var v := ActorView.new()
	v.sheet = _fake(Sheet.FRAME)
	v.sheet._add("walk", 2, 6, 8)
	v.sheet._add("hurt", 4, 3, 10, false)
	v.dir_sheets = _dirs(which)
	return v


func test_eight_ways_round_from_five_drawings() -> void:
	eq(ActorView.octant(Vector2.RIGHT), ["e", false], "east")
	eq(ActorView.octant(Vector2(1, 1)), ["se", false], "south-east (down the screen is south)")
	eq(ActorView.octant(Vector2.DOWN), ["s", false], "south")
	eq(ActorView.octant(Vector2(-1, 1)), ["se", true], "south-west is south-east mirrored")
	eq(ActorView.octant(Vector2.LEFT), ["e", true], "west is east mirrored")
	eq(ActorView.octant(Vector2(-1, -1)), ["ne", true], "north-west is north-east mirrored")
	eq(ActorView.octant(Vector2.UP), ["n", false], "north")
	eq(ActorView.octant(Vector2(1, -1)), ["ne", false], "north-east")


func test_it_draws_the_sheet_for_the_way_it_faces() -> void:
	var v := _view(Sheet.DIRECTIONS)
	v.look = Vector2.UP
	var pick := v.art_for("walk")
	check(pick[0] == v.dir_sheets["n"] and not pick[1], "walking up the screen shows his back")
	v.look = Vector2(-1, 0.9)
	pick = v.art_for("walk")
	check(pick[0] == v.dir_sheets["se"] and pick[1], "walking down-left is the south-east drawing, mirrored")
	eq((pick[0] as Sheet).frame_rect("walk", 0.0).size, Sheet.DIR_FRAME, "with the new 80 x 80 frames")
	v.free()


func test_missing_directions_use_the_nearest_drawn_one() -> void:
	var v := _view(["s", "e", "n"])   # the first delivery: S, E and N walks
	v.look = Vector2(1, 0.8)          # south-east, not drawn yet
	var pick := v.art_for("walk")
	check(pick[0] == v.dir_sheets["e"] or pick[0] == v.dir_sheets["s"], "south-east borrows east or south")
	v.look = Vector2(-1, -0.2)        # nearly west
	pick = v.art_for("walk")
	check(pick[0] == v.dir_sheets["e"] and pick[1], "west is east mirrored")
	v.free()


func test_rows_the_new_art_lacks_come_from_the_old_sheet() -> void:
	var v := _view(Sheet.DIRECTIONS)
	v.look = Vector2.LEFT
	v.facing = -1
	var pick := v.art_for("hurt")
	check(pick[0] == v.sheet and pick[1], "no hurt row in the new sheets yet: the right-facing one, mirrored")
	eq((pick[0] as Sheet).frame_rect("hurt", 0.0).size, Sheet.FRAME, "at its old 64 x 64 size")
	v.free()


func test_without_new_art_nothing_changes() -> void:
	var v := _view([])
	v.facing = 1
	var pick := v.art_for("walk")
	check(pick[0] == v.sheet and not pick[1], "no directional sheets yet: the old one, as before")
	v.free()


func test_moving_turns_the_way_it_faces() -> void:
	var v := ActorView.new()
	v.position = Vector2(100, 100)
	v.glide_free(Vector2(100, 90), 1.0)
	check(v.look.distance_to(Vector2.UP) < 0.01, "walking up the screen faces north")
	v.face_point(Vector2(140, 130))
	check(v.look.distance_to(Vector2(40, 40).normalized()) < 0.01, "and facing a target turns it that way")
	v.free()
