extends TestBase
## The skeleton (scripts/game/rig.gd, rig_pose.gd): the walk alternates its legs and plants its feet, parts go where
## their joints are and turn with their bones, the coat hangs over the legs and the near arm over the body, the
## right drawn direction is picked (the west side mirrored), and the rig only does the moving animations.

const F_SOUTH := Vector2(0, -1)
const F_EAST := Vector2(1, 0)


func _part(pls: Array, name: String) -> Dictionary:
	for p in pls:
		if p.part == name:
			return p
	return {}


func _order(pls: Array, name: String) -> int:
	for i in pls.size():
		if pls[i].part == name:
			return i
	return -1


func test_the_walk_puts_one_foot_forward_then_the_other() -> void:
	var a := RigPose.walk(0.0)
	var b := RigPose.walk(0.5)
	check(a.l_ankle.z > 0 and a.r_ankle.z < 0, "at the start the left foot is ahead")
	check(b.r_ankle.z > 0 and b.l_ankle.z < 0, "half way the right foot is ahead")
	var mid := RigPose.walk(0.25)
	check(mid.r_ankle.y > a.r_ankle.y + 2.0, "and in between the swinging foot lifts")
	check(RigPose.walk(0.125).hip.y < RigPose.walk(0.375).hip.y, "the body dips after each step and rises after")


func test_a_planted_foot_moves_back_under_the_body_as_he_goes() -> void:
	var a := RigPose.walk(0.0)
	var b := RigPose.walk(0.25)
	check(b.l_ankle.z < a.l_ankle.z and b.l_ankle.y == a.l_ankle.y, "the left foot, planted, slides back relative to the hip (he moves over it)")


func test_sneaking_is_lower_and_shorter() -> void:
	check(RigPose.walk(0.0, "sneak").hip.y < RigPose.walk(0.0).hip.y - 3.0, "crouched")
	check(RigPose.walk(0.0, "sneak").l_ankle.z < RigPose.walk(0.0).l_ankle.z, "short steps")
	check(RigPose.walk(0.0, "limp").l_ankle.z < RigPose.walk(0.0).l_ankle.z, "a limp shortens the bad leg's step")


func test_parts_go_where_their_joints_are() -> void:
	var pose := RigPose.idle(0.0)
	var pls := Rig.placements(pose, F_SOUTH, Vector2(40, 72))
	eq(pls.size(), Rig.PARTS.size(), "every part is placed")
	var thigh := _part(pls, "thigh_l")
	var hip := RigPose.project(pose.l_hip, F_SOUTH, Vector2(40, 72))
	check(thigh.at.distance_to(Vector2(hip.x, hip.y)) < 0.01, "a thigh pivots at its hip")
	check(absf(thigh.angle) < 0.15, "standing, a leg hangs nearly straight down from it")
	var head := _part(pls, "head")
	check(absf(head.angle) < 0.15, "and the head stands up from the neck")


func test_a_leg_swinging_forward_turns_its_thigh() -> void:
	var pls := Rig.placements(RigPose.walk(0.0), F_EAST)
	var left := _part(pls, "thigh_l")    # forward, toward the east
	var right := _part(pls, "thigh_r")   # behind
	check(left.angle < -0.2, "seen from the side, the forward thigh swings toward where he faces (%.2f)" % left.angle)
	check(right.angle > 0.03, "and the back one the other way (%.2f)" % right.angle)


func test_the_coat_covers_the_legs_and_the_head_is_last() -> void:
	var pls := Rig.placements(RigPose.walk(0.3), F_SOUTH)
	for leg in Rig.LEGS:
		check(_order(pls, leg) < _order(pls, "skirt"), "%s is under the coat" % leg)
	check(_order(pls, "head") == pls.size() - 1, "the head is drawn last")
	var side := Rig.placements(RigPose.idle(0.0), F_EAST)
	# facing east, his left side is away from the camera, his right toward it
	check(_order(side, "upper_arm_l") < _order(side, "torso"), "the far arm is behind the body")
	check(_order(side, "upper_arm_r") > _order(side, "torso"), "the near arm is in front of it")


func test_the_right_direction_is_picked_and_the_west_mirrored() -> void:
	var r := Rig.new()
	for d in Rig.DIRS:
		r.sheets[d] = ImageTexture.create_from_image(Image.create(264, 24, false, Image.FORMAT_RGBA8))
	eq(r.pick(Vector2.DOWN), ["s", false], "south")
	eq(r.pick(Vector2.UP), ["n", false], "north")
	eq(r.pick(Vector2.LEFT), ["e", true], "west is east mirrored")
	eq(r.pick(Vector2(-1, 1)), ["se", true], "south-west is south-east mirrored")
	r.sheets.erase("se")
	check(r.pick(Vector2(1, 0.9))[0] in ["s", "e"], "a missing direction borrows the nearest")


func test_only_the_moving_animations_are_rigged() -> void:
	for a in ["idle", "walk", "sneak", "wounded_walk"]:
		check(not Rig.pose_for(a, 0.3).is_empty(), "%s is rigged" % a)
	for a in ["mace_strike", "hurt", "death"]:
		check(Rig.pose_for(a, 0.3).is_empty(), "%s stays painted" % a)
	check(Rig.pose_for("sneak", 0.0, false).hip.y < RigPose.HIP_Y - 3.0, "crouched and still, he stays crouched")


func test_wading_hides_the_parts_under_the_water() -> void:
	eq(Rig.under_water(0.0), [], "dry: everything shows")
	eq(Rig.under_water(Grounding.WADE_DEPTH), ["shin_l", "shin_r"], "shallows: the shins are under")
	check(Rig.under_water(Grounding.DEEP_DEPTH).has("thigh_l") and Rig.under_water(Grounding.DEEP_DEPTH).has("skirt"), "sewage: to the waist")


func test_no_rig_until_the_art_arrives() -> void:
	check(Rig.load_from("res://assets/characters/nobody/rig/") == null, "a folder with no sheets gives no rig: the old art stays")


func test_until_a_direction_is_painted_the_old_art_shows() -> void:
	var r := Rig.new()
	r.sheets["s"] = ImageTexture.create_from_image(Image.create(264, 24, false, Image.FORMAT_RGBA8))
	check(r.covers(Vector2.DOWN), "facing the camera, the painted parts")
	check(r.covers(Vector2(0.2, 1)), "and a little off it")
	check(not r.covers(Vector2.RIGHT), "walking east, not the front view sliding sideways")
	check(not r.covers(Vector2(1, 1)), "nor south-east")
	r.sheets["e"] = r.sheets["s"]
	check(r.covers(Vector2.LEFT), "once the east side is painted, west is it mirrored")


func test_the_view_falls_back_to_the_painted_sheet_for_other_directions() -> void:
	var v := ActorView.new()
	v.rig = Rig.new()
	v.rig.sheets["s"] = ImageTexture.create_from_image(Image.create(264, 24, false, Image.FORMAT_RGBA8))
	v._anim = "walk"
	v.look = Vector2.RIGHT
	check(not v._draw_rig(Vector2.ZERO), "walking east, the rig steps aside for the old art")
	v.free()


# ---------------------------------------------------------------- moving like a body (RigMotion)

const DT := 1.0 / 60.0
const SPEED := 74.7   # px/s: his walking speed (MovementRules.WALK_SPEED)


## Walk a motion east at `speed` for `frames` frames; returns the last pose.
func _walk(m: RigMotion, frames: int, speed := SPEED, kind := "walk") -> Dictionary:
	var p := {}
	for i in frames:
		p = m.step(DT, Vector2(speed, 0), Vector2.RIGHT, kind)
	return p


func test_a_planted_foot_stays_put_on_the_floor() -> void:
	for kind in ["walk", "sneak"]:
		var speed := SPEED if kind == "walk" else SPEED * 0.5
		var m := RigMotion.new()
		_walk(m, 60, speed, kind)        # well under way
		var x := 0.0                      # how far he has come since
		var worst := 0.0
		var prev := INF
		for i in 90:
			var p := m.step(DT, Vector2(speed, 0), Vector2.RIGHT, kind)
			x += speed * DT
			var on_floor: float = RigPose.project(p.l_ankle, F_EAST).x + x
			if p.l_ankle.y == RigPose.ANKLE_Y and prev != INF:
				worst = maxf(worst, absf(on_floor - prev))
			prev = on_floor if p.l_ankle.y == RigPose.ANKLE_Y else INF
		check(worst < 0.05, "%s: the left foot, while down, doesn't slide over the floor (%.2f px a frame)" % [kind, worst])


func test_he_carries_his_weight_over_the_standing_leg() -> void:
	check(RigPose.walk(0.25).hip.x < -0.5, "the hips over the left foot as it takes his weight")
	check(RigPose.walk(0.75).hip.x > 0.5, "and over the right")
	var p := RigPose.walk(0.0)
	check(p.l_hip.z > p.r_hip.z, "the left hip comes forward with the left leg")
	check(p.l_shoulder.z < p.r_shoulder.z, "and the shoulders turn against it")


func test_standing_and_walking_ease_into_each_other() -> void:
	var m := RigMotion.new()
	_walk(m, 60)
	var walking := m.step(DT, Vector2.ZERO, Vector2.RIGHT)
	check(m.walking > 0.5, "a frame after stopping he is still mostly in his stride")
	for i in 30:
		m.step(DT, Vector2.ZERO, Vector2.RIGHT)
	eq(m.walking, 0.0, "half a second later he stands")
	check(walking.hip.y < RigPose.HIP_Y - 0.5, "walking, his knees stay bent")


func test_he_leans_into_setting_off_and_back_when_he_stops() -> void:
	var m := RigMotion.new()
	m.step(DT, Vector2.ZERO, Vector2.RIGHT)
	_walk(m, 6)
	check(m.lean > 0.5, "setting off, he leans forward (%.2f)" % m.lean)
	_walk(m, 90)
	check(absf(m.lean) < 0.2, "at a steady walk he straightens (%.2f)" % m.lean)
	for i in 6:
		m.step(DT, Vector2.ZERO, Vector2.RIGHT)
	check(m.lean < -0.5, "stopping, he rocks back (%.2f)" % m.lean)


func test_the_coat_and_hands_trail_then_settle() -> void:
	var m := RigMotion.new()
	m.step(DT, Vector2.ZERO, Vector2.RIGHT)
	_walk(m, 5)
	check(m._off["hem"].z < -0.5, "setting off, the coat swings back behind him (%.2f)" % m._off["hem"].z)
	check(m._off["hem"].length() > m._off["l_elbow"].length(), "more than his elbows do")
	_walk(m, 120)
	check(m._off["hem"].length() < 0.2, "and at a steady walk it hangs again")
	for i in 5:
		m.step(DT, Vector2.ZERO, Vector2.RIGHT)
	check(m._off["hem"].z > 0.5, "stopping, it swings on ahead (%.2f)" % m._off["hem"].z)


func test_he_walks_on_the_new_parts_and_f8_compares_the_old_art() -> void:
	var game: Game = await add_game(Engine.get_main_loop() as SceneTree)
	check(game.hero.rig_parts != null and game.hero.rig_parts.sheets.has("s"), "the south parts sheet is in")
	eq(game.hero.rig, game.hero.rig_parts, "and he is drawn with it")
	check(game.hero.rig.covers(Vector2.DOWN) and not game.hero.rig.covers(Vector2.RIGHT), "facing south only; the rest keep the old art for now")
	game.hero.show_rig(false)
	check(game.hero.rig == null, "F8: the old painted art, to compare")
	game.hero.show_rig(true)
	check(game.hero.rig == game.hero.rig_parts, "and back")
	game.queue_free()


func test_the_cut_rebuilds_the_approved_model() -> void:
	var tool: GDScript = load("res://tools/rig/rig_template.gd")
	var base := "res://assets/characters/thomas/rig/"
	for pair in [["production/model-s.png", "s.png"], ["production/model-s_n.png", "s_n.png"]]:
		var model := Image.load_from_file(ProjectSettings.globalize_path(base + pair[0]))
		var parts := Image.load_from_file(ProjectSettings.globalize_path(base + pair[1]))
		check(model != null and parts != null, "%s and %s are there" % pair)
		if model == null or parts == null:
			continue
		model.convert(Image.FORMAT_RGBA8)
		parts.convert(Image.FORMAT_RGBA8)
		eq(tool.check(model, parts).size(), 0, "%s, put back together, is %s exactly" % [pair[1], pair[0]])


# ---------------------------------------------------------------- cutting a whole model into parts (job 15-R)

const BIND_ANCHORS := {
	"head": Vector2i(40, 30), "torso": Vector2i(40, 50), "skirt": Vector2i(40, 50),
	"upper_arm_r": Vector2i(33, 32), "upper_arm_l": Vector2i(47, 32), "forearm_r": Vector2i(33, 40), "forearm_l": Vector2i(47, 40),
	"thigh_r": Vector2i(36, 50), "thigh_l": Vector2i(44, 50), "shin_r": Vector2i(36, 59), "shin_l": Vector2i(44, 59),
}


func test_standing_as_painted_every_part_sits_unturned_on_a_whole_pixel() -> void:
	for pl in Rig.placements(RigPose.bind(), F_SOUTH, Vector2(40, 72)):
		check(absf(pl.angle) < 0.0001, "%s is not turned in the bind pose (%.4f)" % [pl.part, pl.angle])
		var at: Vector2 = pl.at
		check(at.distance_to(at.round()) < 0.001, "%s's pivot is on a whole pixel (%s)" % [pl.part, at])
	eq(Rig.bind_anchors(), BIND_ANCHORS, "the pivots fall on the joints measured on the approved model")


func test_the_torso_holds_the_scarf_and_the_hip_kit() -> void:
	var torso := Rig.cut_rect("torso")
	# the approved model (PR #55): the scarf's end reaches row 51, the satchel and lantern rows 43-50, x 41-48
	check(torso.has_point(Vector2i(36, 51)) and torso.has_point(Vector2i(37, 51)), "the scarf's end at row 51")
	check(torso.has_point(Vector2i(48, 43)) and torso.has_point(Vector2i(41, 49)), "the satchel and the lantern")
	check(torso.has_point(Vector2i(40, 30)), "and up to the shoulders")


func test_a_model_cut_by_the_bind_squares_goes_back_together_exactly() -> void:
	# a stand-in model: each part's square painted its own colour where no earlier part claimed it
	var model := Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var parts := Image.create(24 * 11, 24, false, Image.FORMAT_RGBA8)
	var i := 0
	for name in Rig.PARTS:
		var r := Rig.cut_rect(name)
		var c := Color.from_hsv(i / 11.0, 0.6, 0.8)
		i += 1
		for y in range(r.position.y, mini(r.end.y, 72)):
			for x in range(r.position.x + 6, r.end.x - 6):
				if model.get_pixel(x, y).a < 0.5:
					model.set_pixel(x, y, c)
					parts.set_pixel(Rig.PARTS[name][0] * 24 + x - r.position.x, y - r.position.y, c)
	var tool: GDScript = load("res://tools/rig/rig_template.gd")
	eq(tool.check(model, parts).size(), 0, "rebuilt in the bind pose, not one pixel differs")
	parts.set_pixel(Rig.PARTS["torso"][0] * 24 + 12, 20, Color.BLACK)
	check(tool.check(model, parts).size() > 0, "and the check notices a pixel out of place")


func test_the_legs_always_reach_the_feet() -> void:
	for kind in ["walk", "sneak", "limp"]:
		for i in 32:
			var p := RigPose.walk(i / 32.0, kind)
			for s in ["l", "r"]:
				var d: float = (p[s + "_ankle"] - p[s + "_hip"]).length()
				check(d <= RigPose.THIGH + RigPose.SHIN + 0.01, "%s %d/32: the %s leg reaches its foot (%.2f)" % [kind, i, s, d])
