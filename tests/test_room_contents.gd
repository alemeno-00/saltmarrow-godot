extends TestBase
## Room contents, part 1: more enemy groups, and one patrol per level.
## Spec: design/quick-specs/room-contents-2026-10-30.md

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


## Rooms that may hold a waiting group, and how many of them do.
func _group_rooms() -> Vector2i:
	var eligible := 0
	var filled := 0
	for p in game.level.pieces:
		if not p.kind in ["junction", "chamber", "flooded"]:
			continue
		var c: Vector2i = p.rect.get_center()
		if not game.level.is_walkable(c) or game.level.find_path(game.level.start, c).size() < Game.START_DISTANCE:
			continue
		eligible += 1
		if game.enemies.any(func(e): return e.state == "idle" and (p.rect as Rect2i).has_point(e.cell)):
			filled += 1
	return Vector2i(filled, eligible)


func test_most_rooms_hold_a_group() -> void:
	var filled := 0
	var eligible := 0
	for life in range(100, 160):
		game.new_level(life)
		var g := _group_rooms()
		filled += g.x
		eligible += g.y
	var share := float(filled) / eligible
	check(share > Game.GROUP_CHANCE - 0.1 and share < Game.GROUP_CHANCE + 0.1, "about 75%% of rooms hold a group (%.2f)" % share)


func test_each_level_has_one_patrol() -> void:
	for life in range(200, 210):
		game.new_level(life)
		var groups := {}
		for e in game.enemies:
			if e.state == "patrolling":
				groups[e.group] = true
		eq(groups.size(), 1, "life %d: one patrol" % life)
		var leader := game.patrol_leader()
		check(leader != null, "life %d: the patrol has a leader" % life)
		if leader == null:
			continue
		check(leader.route.size() >= 2 and leader.route.size() <= 4, "life %d: it walks between 2 and 4 rooms (%d)" % [life, leader.route.size()])
		var entry: Rect2i = game.level.pieces[0].rect
		for w in leader.route:
			check(game.level.is_walkable(w), "life %d: waypoint %s is walkable" % [life, w])
			check(not entry.has_point(w), "life %d: the patrol never stops in the entry" % life)


func test_the_patrol_walks_its_route() -> void:
	game.new_level(201)
	var leader := game.patrol_leader()
	var first: Vector2i = leader.route[leader.route_i]
	var d0 := game.level.find_path(leader.cell, first).size()
	for i in 10:
		game.patrol_tick(0.1)
	var d1 := game.level.find_path(leader.cell, first).size()
	check(d1 < d0 or d0 <= 1, "in a second the leader walks toward its waypoint (%d to %d squares)" % [d0, d1])
	var reached := {}
	for i in 2000:
		game.patrol_tick(0.1)
		reached[leader.route_i] = true
	check(reached.size() >= 2, "it reaches its waypoints and moves on (%d waypoints reached)" % reached.size())


func test_followers_keep_up() -> void:
	game.new_level(202)
	var leader := game.patrol_leader()
	for i in 300:
		game.patrol_tick(0.1)
	for e in game.enemies:
		if e.group == leader.group and e != leader:
			check(Battle.dist(e.cell, leader.cell) <= 4, "a follower stays close to the leader (%d away)" % Battle.dist(e.cell, leader.cell))


func test_the_patrol_spots_thomas() -> void:
	game.new_level(203)
	var leader := game.patrol_leader()
	for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
		var c: Vector2i = leader.cell + d
		if game.level.get_tile(c) == Level.Tile.FLOOR and game._enemy_at(c) == null and game.level.line_of_sight(c, leader.cell):
			game.hero.place(c)
			game.hero_unit.cell = c
			break
	game._check_spotted()
	check(game.in_fight(), "seeing Thomas starts a fight")
	check(game.battle.units.has(leader), "and the patrol is in it")


func test_a_far_off_patrol_stays_out_of_someone_elses_fight() -> void:
	game.new_level(201)
	var leader := game.patrol_leader()
	for e in game.enemies:
		if e.group == leader.group or e.kind == "solo" or e.state != "idle":
			continue
		for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
			var c: Vector2i = e.cell + d
			var far := MovementRules.centre(c).distance_to(game.views[leader].position) > MovementRules.px(MovementRules.SIGHT) + 64.0
			if far and game.level.get_tile(c) == Level.Tile.FLOOR and game._enemy_at(c) == null and game.level.line_of_sight(c, e.cell):
				game.hero.place(c)
				game.hero_unit.cell = c
				game._check_spotted()
				check(game.in_fight(), "the group starts a fight")
				check(not game.battle.units.has(leader), "the patrol, out of sight across the level, is not in it")
				return
	check(false, "found a group to test with")


func test_the_patrol_walks_smooth_lines_not_square_to_square() -> void:
	game.new_level(201)
	var leader := game.patrol_leader()
	game.patrol_tick(0.1)
	var goal: Vector2i = leader.route[leader.route_i]
	var squares := game.level.find_path(leader.cell, goal).size()
	var points: int = (game._routes[leader].path as Array).size()
	check(squares > 3, "the first waypoint is some way off (%d squares)" % squares)
	check(points < squares / 2, "its route cuts across in a few straight lines (%d points for %d squares)" % [points, squares])
