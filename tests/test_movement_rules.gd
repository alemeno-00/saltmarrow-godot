extends TestBase
## The free-movement maths on its own (MovementRules): units, speeding up and stopping, sliding out of walls and
## bodies, clear lines for cutting corners, and the hit-feel numbers.


## A 6×5 room of floor inside a ring of wall.
func _box() -> Level:
	var l := Level.new(6, 5)
	for y in range(1, 4):
		for x in range(1, 5):
			l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.rebuild_paths()
	return l


func test_a_square_is_one_and_a_half_metres() -> void:
	eq(MovementRules.px(MovementRules.METRES_PER_SQUARE), float(MovementRules.TILE), "1.5 m is one 32 px square")
	eq(MovementRules.cell_of(Vector2(47.9, 32.0)), Vector2i(1, 1), "a point is in the square it falls in")
	eq(MovementRules.centre(Vector2i(1, 1)), Vector2(48, 48), "and a square's middle is half a square in")


func test_steering_reaches_top_speed_and_stops_in_time() -> void:
	var top := 64.0
	var v := Vector2.ZERO
	for i in 6:   # 0.1 s at 60 frames a second
		v = MovementRules.steer(v, Vector2.RIGHT, top, 1.0 / 60.0)
	check(absf(v.x - top) < 0.01, "top speed after the speed-up time (%.2f)" % v.x)
	for i in 5:   # 0.083 s
		v = MovementRules.steer(v, Vector2.ZERO, top, 1.0 / 60.0)
	eq(v, Vector2.ZERO, "standing still after the stopping time")


func test_sliding_stops_at_a_wall_and_keeps_the_rest() -> void:
	var l := _box()
	var r := 7.0
	var p := MovementRules.slide(l, Vector2(140, 60), Vector2(40, -10), r)
	check(absf(p.x - (5 * 32 - r)) < 0.01, "the east wall stops him a body's width short (x %.2f)" % p.x)
	check(absf(p.y - 50.0) < 0.01, "the motion along the wall is kept (y %.2f)" % p.y)


func test_a_big_step_does_not_pass_through_a_wall() -> void:
	var l := _box()
	var p := MovementRules.slide(l, Vector2(140, 60), Vector2(200, 0), 7.0)
	check(p.x < 5 * 32, "a long step in one frame still stops at the wall (x %.1f)" % p.x)


func test_bodies_push_apart() -> void:
	var l := _box()
	var other := Vector2(100, 60)
	var p := MovementRules.push_out(l, Vector2(96, 60), 7.0, [[other, 8.0]])
	check(absf(p.distance_to(other) - 15.0) < 0.01, "two bodies end up just touching (%.2f apart)" % p.distance_to(other))


func test_a_centre_inside_a_wall_leaves_by_the_nearest_side() -> void:
	var l := _box()
	var p := MovementRules.push_out(l, Vector2(162, 60), 7.0)
	eq(p, Vector2(160 - 7.0, 60), "pushed back out of the wall's near side")


func test_clear_walk_sees_past_corners_only_when_clear() -> void:
	var l := _box()
	check(MovementRules.clear_walk(l, Vector2(48, 48), Vector2(144, 112), 7.0), "across the open room is clear")
	l.set_tile(Vector2i(3, 2), Level.Tile.WALL)
	check(not MovementRules.clear_walk(l, Vector2(48, 80), Vector2(144, 80), 7.0), "a pillar in the way is not")


func test_stronger_hits_freeze_longer() -> void:
	check(Game.hitstop_for(1) < Game.hitstop_for(2) and Game.hitstop_for(2) < Game.hitstop_for(3), "weak < solid < strong")
	eq(Game.hitstop_for(3), 0.12, "a strong hit holds 120 ms")
	check(Game.heavy_blow(Bestiary.garrick(), {"cost": 0, "tiers": []}), "a boss's blows are heavy")
	check(not Game.heavy_blow(Bestiary.faithful(), {"cost": 0, "tiers": [{"dmg": 2}]}), "a plain jab is not")
