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
	game.patrol_step()
	var d1 := game.level.find_path(leader.cell, first).size()
	check(d1 == d0 - 1 or d0 <= 1, "the leader takes one step toward its waypoint (%d to %d)" % [d0, d1])
	var reached := {}
	for i in 200:
		game.patrol_step()
		reached[leader.route_i] = true
	check(reached.size() >= 2, "it reaches its waypoints and moves on (%d waypoints reached)" % reached.size())


func test_followers_keep_up() -> void:
	game.new_level(202)
	var leader := game.patrol_leader()
	for i in 30:
		game.patrol_step()
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
