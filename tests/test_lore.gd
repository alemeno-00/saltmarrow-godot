extends TestBase
## Lore and the journal, room contents part 2 (design/quick-specs/room-contents-2026-10-30.md; texts in
## scripts/data/lore.gd): drops placed by rule, letters in story order and worded for the backstory, miners who lie
## differently from life to life, a journal that survives death, and all of it worked with the mouse.

var tree: SceneTree
var game: Game


func setup(t: SceneTree) -> void:
	tree = t
	game = await add_game(tree)


func teardown() -> void:
	if game != null:
		game.queue_free()


func test_drops_lie_on_open_floor_in_their_own_rooms() -> void:
	for s in range(1, 301):
		var l := Level.new()
		l.generate(s)
		var lore_rooms := 0
		var rooms_used := {}
		for i in l.pieces.size():
			if l.pieces[i].kind == "lore":
				lore_rooms += 1
		for c in l.lore:
			check(l.get_tile(c) == Level.Tile.FLOOR, "seed %d: on dry floor" % s)
			check(not l.caches.has(c) and c != l.start, "seed %d: not on a cache or the start" % s)
			var room := l.piece_at(c)
			check(room >= 0 and not rooms_used.has(room), "seed %d: one drop to a room" % s)
			rooms_used[room] = true
			var r: Rect2i = l.pieces[room].rect
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var e := Vector2i(x, y)
					var edge := x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1
					if edge and l.is_walkable(e):
						check(maxi(absi(e.x - c.x), absi(e.y - c.y)) > RoomContents.DOOR_CLEAR, "seed %d: clear of the doorway at %s" % [s, e])
			if l.pieces[room].kind == "lore":
				eq(l.lore[c].kind, "letter", "seed %d: the lore room holds a letter" % s)
		var others := l.lore.size() - lore_rooms
		check(others >= 0 and others <= RoomContents.LORE.y, "seed %d: 1-2 drops besides the lore room's (got %d)" % [s, others])


func test_the_same_seed_gives_the_same_drops() -> void:
	var a := Level.new()
	a.generate(31)
	var b := Level.new()
	b.generate(31)
	eq(a.lore, b.lore, "seed 31 twice")


func test_every_find_has_words_and_the_letters_differ_by_backstory() -> void:
	for kind in ["letter", "tag", "chapel"]:
		for id in Lore.ids(kind):
			var p := Lore.page(id, "fury", 1)
			check(p[0] != "" and p[1] != "", "%s has a title and text" % id)
	eq(Lore.LETTERS.fury.size(), Lore.LETTERS.shadow.size(), "both backstories have every letter")
	check(Lore.page("letter_6", "fury", 1)[1] != Lore.page("letter_6", "shadow", 1)[1], "a Shadow's letter is worded differently")


func test_a_miner_lies_the_same_way_all_life_and_differently_in_others() -> void:
	eq(Lore.page("tag_7", "fury", 42), Lore.page("tag_7", "shadow", 42), "the same life, the same body")
	var looks := {}
	for life in range(1, 40):
		looks[Lore.tag_look(7, life)] = true
	eq(looks.size(), 2, "across lives, both of his looks turn up")
	check(Lore.page("tag_7", "fury", 1)[1].contains("JORY PELLOW"), "the tag gives his number and name")


## Start a level that has a drop of `kind`; returns its square.
func _level_with(kind: String) -> Vector2i:
	for s in range(1, 300):
		var l := Level.new()
		l.generate(s)
		var cells: Array = l.lore.keys()
		cells.sort()   # the order the game hands out letters in
		for c in cells:
			if l.lore[c].kind == kind:
				game.new_level(s)
				game.clear_enemies()
				return c
	failures.append("no level has a %s" % kind)
	return Vector2i(-1, -1)


func _put(c: Vector2i) -> void:
	game.hero.place(c)
	game.hero.glide_free(MovementRules.centre(c), 0.0)
	game.hero_unit.pos = MovementRules.centre(c)
	game.path.clear()
	game._vel = Vector2.ZERO


func test_reading_puts_it_in_the_journal_which_outlives_him() -> void:
	var c := _level_with("letter")
	eq(game.level.lore[c].id, "letter_1", "the first letter he finds is the first she wrote")
	eq(game.read_lore(c), "read", "he reads it")
	check(game.journal_screen.visible and game.journal_screen.page_text().begins_with("Tom"), "the page opens")
	check(game.paused(), "and the world waits while he reads")
	game.journal_screen.close()
	check(game.journal.has("letter_1"), "it is in the journal")
	eq(game.read_lore(c), "reread", "reading it again adds nothing")
	game.journal_screen.close()
	# he dies, and a new life begins
	game.dead = true
	game.new_level(999)
	check(game.journal.has("letter_1"), "a new life keeps the journal")
	check(Journal.open(TEST_JOURNAL).has("letter_1"), "and so does the file it is kept in")


func test_letters_come_in_order_across_lives() -> void:
	game.journal.add("letter_1", "t", "x")
	game.journal.add("letter_2", "t", "x")
	var c := _level_with("letter")
	eq(game.level.lore[c].id, "letter_3", "with two read, the next found is the third")


func test_a_shadow_reads_his_own_letters() -> void:
	var c := _level_with("letter")
	game.choose_backstory("shadow")
	game.read_lore(c)
	eq(game.journal_screen.page_text(), Lore.LETTERS.shadow[0], "worded for the Shadow")
	game.journal_screen.close()


func test_hover_names_it_and_a_click_walks_over_and_reads() -> void:
	var c := _level_with("tag")
	var at := MovementRules.centre(c)
	var thing := game.thing_at(at)
	eq(thing.get("name", ""), "A dead miner", "hovering picks him out by name")
	var opts := game.context_options(at)
	check(opts.any(func(o): return o[0] == "Look at him"), "right-click offers to look at him")
	# from across the room, a left-click walks him over and he looks
	var far := Vector2i(-1, -1)
	var r: Rect2i = game.level.pieces[game.level.piece_at(c)].rect
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var e := Vector2i(x, y)
			if game.level.is_walkable(e) and Vector2(e - c).length() >= 3.0 and game.level.find_path(e, c).size() > 0:
				far = e
	check(far.x >= 0, "somewhere across the room to start from")
	if far.x < 0:
		return
	_put(far)
	game.creep_or_walk(at)
	for i in 600:
		if game.journal_screen.visible:
			break
		run(game, 1.0 / 60.0)
	check(game.journal_screen.visible, "he walked over and is looking")
	check(game.journal.has(game.level.lore[c].id), "and the miner is in the journal")
	check(game.lore_name(c).ends_with("(read)"), "after which the floor says so")
	game.journal_screen.close()


func test_j_opens_the_journal() -> void:
	game.journal.add("letter_1", "Ellen's letter (1 of 6)", "Tom —")
	game.toggle_journal()
	check(game.journal_screen.visible and game.journal_screen.mode == "journal", "J opens it")
	eq(game.journal_screen.page_title(), "Ellen's letter (1 of 6)", "on the newest entry")
	game.toggle_journal()
	check(not game.journal_screen.visible, "and closes it")
