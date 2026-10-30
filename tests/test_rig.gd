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
	check(right.angle > 0.1, "and the back one the other way (%.2f)" % right.angle)


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
