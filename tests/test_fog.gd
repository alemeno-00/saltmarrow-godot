extends TestBase
## Fog of war (scripts/core/fog.gd): unexplored squares are black, explored ones out of sight are remembered and
## dimmed with no creatures shown in them, and only what Thomas can see shows who is there. Anyone in a fight with
## him stays shown.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


## Two rooms side by side, a wall between them at x = 10 with a closed door at (10, 5).
func _two_rooms() -> Level:
	var l := Level.new(21, 11)
	for y in range(1, 10):
		for x in range(1, 20):
			if x != 10:
				l.set_tile(Vector2i(x, y), Level.Tile.FLOOR)
	l.set_tile(Vector2i(10, 5), Level.Tile.DOOR_CLOSED)
	l.start = Vector2i(3, 5)
	l.rebuild_paths()
	return l


func test_he_sees_his_room_and_its_walls_but_not_through_them() -> void:
	var l := _two_rooms()
	var f := Fog.new(l.width, l.height)
	f.update(l, Vector2i(3, 5))
	check(f.sees(Vector2i(8, 2)), "across his own room")
	check(f.sees(Vector2i(10, 3)), "the wall that ends it")
	check(f.sees(Vector2i(10, 5)), "and the closed door in it")
	check(not f.sees(Vector2i(14, 5)), "but not the room beyond")
	check(not f.knows(Vector2i(14, 5)), "which stays unexplored, black")


func test_what_he_has_seen_is_remembered_when_he_looks_away() -> void:
	var l := _two_rooms()
	var f := Fog.new(l.width, l.height)
	f.update(l, Vector2i(3, 5))
	l.set_tile(Vector2i(10, 5), Level.Tile.DOOR_OPEN)
	f.update(l, Vector2i(12, 5))
	check(f.sees(Vector2i(16, 5)), "through the door, the second room")
	check(not f.sees(Vector2i(3, 2)), "the first room's corner is out of sight now")
	check(f.knows(Vector2i(3, 2)), "but remembered")


func test_sight_has_a_limit() -> void:
	var l := Level.new(40, 5)
	for x in range(1, 39):
		l.set_tile(Vector2i(x, 2), Level.Tile.FLOOR)
	var f := Fog.new(l.width, l.height)
	f.update(l, Vector2i(1, 2))
	check(f.sees(Vector2i(1 + Fog.SIGHT, 2)), "as far as he can see")
	check(not f.sees(Vector2i(2 + Fog.SIGHT, 2)), "and no further")


func test_a_door_opening_is_seen_without_him_moving() -> void:
	var l := _two_rooms()
	var f := Fog.new(l.width, l.height)
	f.update(l, Vector2i(9, 5))
	l.set_tile(Vector2i(10, 5), Level.Tile.DOOR_OPEN)
	f.update(l, Vector2i(9, 5))
	check(not f.sees(Vector2i(14, 5)), "standing still, it isn't worked out again")
	f.update(l, Vector2i(9, 5), true)
	check(f.sees(Vector2i(14, 5)), "until it is told something changed")


func _in_game(l: Level) -> void:
	game.clear_enemies()
	game.level = l
	game.view.show_level(l)
	Grounding.level = l
	Grounding.lights.clear()
	game.hero.place(l.start)
	game.hero.glide_free(MovementRules.centre(l.start), 0.0)
	game.hero_unit.pos = MovementRules.centre(l.start)


func test_a_creature_out_of_sight_is_not_shown() -> void:
	var l := _two_rooms()
	_in_game(l)
	var near := game._add_enemy(Bestiary.faithful(), Vector2i(7, 3))
	var far := game._add_enemy(Bestiary.faithful(), Vector2i(15, 5))
	game._heads[near] = 9999.0
	game._heads[far] = 9999.0
	game.views[near].look = Vector2.UP
	game.views[far].look = Vector2.UP
	run(game, 0.5)
	check(game.can_see(near), "the one in his room is shown")
	check(not game.can_see(far), "the one behind the wall is not")
	check(game.views[far].modulate.a < 0.05, "it is drawn faded out")
	check(not game.fog.knows(Vector2i(15, 5)), "and its room is black")


func test_everyone_in_the_fight_is_shown() -> void:
	var l := _two_rooms()
	_in_game(l)
	var far := game._add_enemy(Bestiary.faithful(), Vector2i(15, 5))
	game._heads[far] = 9999.0
	run(game, 0.1)
	check(not game.can_see(far), "out of sight, hidden")
	far.state = "hunting"
	game._start_battle()
	check(game.in_fight() and game.battle.units.has(far), "it joins the fight")
	check(game.can_see(far), "and in the fight it is shown")
