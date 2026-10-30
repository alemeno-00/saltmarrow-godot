class_name Game
extends Node2D
## Exploring a level with Thomas, and fighting when something sees him.
##
## Exploring (free movement, design/quick-specs/free-movement-2026-10-30.md): keys, arrows or a stick move Thomas
## freely in any direction; he slides along walls and opens doors he walks into. Clicking a square walks him there
## along a smoothed route; any key stops him. Distances and speeds are in metres (MovementRules).
##
## Fighting (Draw Steel turns): click a lit square to move, click an enemy next to you to strike,
## 1-5 for abilities, F (or Shift-click) for a careful step that draws no free strikes, Q to stand, B to catch your breath, Enter to end the turn. R starts a new level.
##
## K opens the skill tree. Stairs lead deeper; Thomas keeps everything he has learned. R starts a new life.
##
## Outside a fight the world runs in real time: the patrol walks, hunters and searchers move, and an enemy that ran
## away comes back after a while, with friends. Fights are still on squares: when one starts, everyone slides onto
## the nearest free square (until fights move to metres).

const TILE := 32
const BOTTOM_DEPTH := 3       # the Outflow and Garrick are on this level; beating him wins the run
const START_DISTANCE := 17    # enemy groups wait at least this many steps from the start (their members 15+)
const GROUP_CHANCE := 0.75    # chance a junction or chamber holds a group (room-contents spec, part 1)
const PATROLS := 1            # patrols per level
const PATROL_ROOMS := Vector2i(2, 4)   # a patrol walks between this many rooms
const PATROL_GROUP := 1000 + 1         # group id of the patrol (Garrick's band is 1000)
const STAIRS_GUARD_CHANCE := 0.5

@export var level_seed: int = 0   # 0: a random first life; tests set a fixed seed
@export var ask_backstory := true # each new life starts by choosing who Thomas was; tests skip it (Fury)
var life_seed := 0                  # this life's seed; every depth's level comes from it (depth_seed)

var level: Level
var path: Array[Vector2] = []    # a clicked route: the points still to walk through
var fights := 0                  # fights so far this level (each fight's dice seed)
var dust_made := 0               # dust kicked up by sharp turns (tests read this)

var hero_unit: Combatant
var enemies: Array[Combatant] = []
var views := {}          # Combatant -> ActorView
var battle: Battle = null
var busy := false        # events are playing; input waits
var selected := -1       # the ability chosen, waiting for a target
var stepping := false    # F pressed: the next click is a careful step
var dead := false
var progress: Progress
var depth := 1
var veteran := false     # F9: test as a high-level Thomas
var tree_screen: TreeScreen
var backstory_screen: BackstoryScreen
var returning: Array = []   # [Combatant, seconds left] for enemies that ran and will come back
var tag_cell := Vector2i(-1, -1)   # where Garrick's tally tag lies, once he is dead
var won := false
var sneaking := false    # C: crouched, slow and quiet (design/quick-specs/sneaking-2026-10-30.md)
var lantern := "lit"     # Thomas's lantern: lit, shuttered (dimmed) or out
var hero_lantern: PointLight2D
var noises := 0          # times something heard him (tests read this)
var _relight := 0.0      # seconds left striking a light
var aiming_throw := false   # T: the next click throws a dagger (Daggers: Throw)
var _ambush: Combatant = null   # the unaware enemy Thomas is creeping up to strike
var _heads := {}         # Combatant -> seconds until an idle enemy next turns its head
var _watching := {}      # lurker -> seconds Thomas has been watching its spot
var _props := {}         # square -> CoverProp: crates, barrels, satchels, the valve, the grate
var _draining: Array[Vector2i] = []   # water squares still to drain, row by row
var context_menu: PopupMenu            # right-click: what can be done with what is under the mouse
var _context_actions: Array[Callable] = []
var _then := Callable()                # something to do once he has walked up to it (search, turn, unlock)
var _then_at := Vector2i(-1, -1)
var _drain_timer := 0.0

var _hover := Vector2i(-1, -1)
var _hover_px := Vector2.INF
var _hover_from := Vector2.INF
var _vel := Vector2.ZERO     # Thomas's velocity while exploring, px/s
var _stuck := 0.0
var _dust_cool := 0.0
var _routes := {}            # Combatant -> {goal, path, age}: where a roaming creature is heading
var _shake := 0.0
var _focus = null        # where the camera looks during a crit, or null for Thomas
var _rng := RandomNumberGenerator.new()


func hover_cell() -> Vector2i:
	return _hover


@onready var view: LevelView = $LevelView
@onready var gore: Gore = $Gore
@onready var actors: Node2D = $Actors
@onready var hero: Hero = $Actors/Hero
@onready var cam: Camera2D = $Camera
@onready var hud: Label = $HUD/Info
@onready var combat_hud: CombatHud = $HUD/CombatHud
@onready var overlay: Node2D = $Overlay
var lighting: Lighting
var darkness: CanvasModulate
var world_ui: CanvasLayer   # follows the camera but isn't dimmed: fight markers, hit flashes
var ripples_made := 0       # ripples and splashes so far (tests read this)


func _ready() -> void:
	combat_hud.ability_pressed.connect(_on_ability_key)
	combat_hud.stand_pressed.connect(func(): _act(battle.hero_stand()) if _can_act() else null)
	combat_hud.breath_pressed.connect(func(): _act(battle.hero_catch_breath()) if _can_act() else null)
	combat_hud.end_turn_pressed.connect(_end_hero_turn)
	combat_hud.step_pressed.connect(_toggle_step)
	# the dark: the world is dimmed; lanterns, braziers and Thomas's own lantern light it
	darkness = CanvasModulate.new()
	darkness.color = Lighting.AMBIENT
	add_child(darkness)
	lighting = Lighting.new()
	add_child(lighting)
	hero_lantern = Lighting.make_light(Lighting.HERO_LIGHT, Lighting.HERO_ENERGY, Lighting.HERO_RADIUS)
	hero_lantern.position = Vector2(0, 4)
	hero.add_child(hero_lantern)
	hero.stepped.connect(_on_stepped)
	actors.y_sort_enabled = true   # creatures and crates drawn in order of their feet, so behind means behind
	world_ui = CanvasLayer.new()
	world_ui.follow_viewport_enabled = true
	add_child(world_ui)
	overlay.game = self
	overlay.reparent(world_ui)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	tree_screen = TreeScreen.new()
	layer.add_child(tree_screen)
	tree_screen.changed.connect(_apply_progress)
	context_menu = PopupMenu.new()
	layer.add_child(context_menu)
	context_menu.id_pressed.connect(func(i): if i < _context_actions.size() and _context_actions[i].is_valid(): _context_actions[i].call())
	combat_hud.belt_pressed.connect(use_belt)
	backstory_screen = BackstoryScreen.new()
	layer.add_child(backstory_screen)
	backstory_screen.chosen.connect(choose_backstory)
	new_level(level_seed if level_seed != 0 else randi())


## A fresh level. With `keep`, Thomas goes on down with everything he has; without it, a new life.
func new_level(seed_in: int, keep := false) -> void:
	Engine.time_scale = 1.0
	var next_depth := depth + 1 if keep and hero_unit != null and not dead else 1
	if next_depth == 1:
		life_seed = seed_in
	level = Level.new()
	level.generate(depth_seed(life_seed, next_depth), next_depth >= BOTTOM_DEPTH)
	tag_cell = Vector2i(-1, -1)
	won = false
	view.show_level(level)
	lighting.build(level)
	hero.place(level.start)
	if keep and hero_unit != null and not dead:
		depth += 1
		hero_unit.prone = false
		hero_unit.dazed = 0
		hero_unit.slowed = 0
		hero_unit.resolve = 0
		hero_unit.telegraph.clear()
	else:
		depth = 1
		progress = Progress.veteran(10) if veteran else Progress.fury()
		hero_unit = Bestiary.thomas(progress)
		if ask_backstory and not veteran:
			backstory_screen.open()
	hero_unit.cell = level.start
	hero.sync(hero_unit)
	gore.clear_all()
	_place_cover_props()
	clear_enemies()
	combat_hud.set_belt(progress.belt)
	_spawn_enemies()
	battle = null
	busy = false
	dead = false
	selected = -1
	returning.clear()
	combat_hud.set_abilities(hero_unit.abilities)
	combat_hud.show_fight(false)
	combat_hud.clear_log()
	combat_hud.refresh(hero_unit, null, true)
	cam.position = hero.position
	path.clear()
	fights = 0
	_vel = Vector2.ZERO
	_routes.clear()
	_heads.clear()
	_ambush = null
	_relight = 0.0
	sneaking = false
	set_lantern("lit")
	_update_hud()


func clear_enemies() -> void:
	for c in actors.get_children():
		if c != hero and not c is CoverProp:
			c.queue_free()
	enemies.clear()
	views = {hero_unit: hero}


## The first fight: a Drowned Miner and three Faithful, waiting a couple of rooms from the start.
## Groups waiting in every third room, starting two rooms from the start. Deeper levels hold more.
## One patrol per level: a Drowned Miner leading two Faithful between 2-4 connected rooms, back and forth, walking
## in real time while Thomas explores. It spots him like anyone else.
func _spawn_patrol(pick: RandomNumberGenerator) -> void:
	var near := {}
	for i in level.pieces.size():
		var p: Dictionary = level.pieces[i]
		if p.kind == "connector" or p.parent < 0:
			continue
		near.get_or_add(i, []).append(p.parent)
		near.get_or_add(p.parent, []).append(i)
	var starts: Array = []
	for i in level.pieces.size():
		if _patrol_room(i) and level.find_path(level.start, level.pieces[i].rect.get_center()).size() >= START_DISTANCE:
			starts.append(i)
	for _try in 12:
		if starts.is_empty():
			return
		var rooms: Array = [starts[pick.randi_range(0, starts.size() - 1)]]
		var want := pick.randi_range(PATROL_ROOMS.x, PATROL_ROOMS.y)
		while rooms.size() < want:
			var nexts: Array = near.get(rooms[-1], []).filter(func(j): return _patrol_room(j) and not rooms.has(j))
			if nexts.is_empty():
				break
			rooms.append(nexts[pick.randi_range(0, nexts.size() - 1)])
		if rooms.size() < PATROL_ROOMS.x:
			continue
		var route: Array[Vector2i] = []
		for j in rooms:
			route.append(level.pieces[j].rect.get_center())
		var spots := _free_floor_near(route[0], 3)
		if spots.size() < 3:
			continue
		var leader := _add_enemy(Bestiary.drowned_miner(), spots[0])
		leader.group = PATROL_GROUP
		leader.state = "patrolling"
		leader.route = route
		leader.route_i = 1
		for k in [1, 2]:
			var f := _add_enemy(Bestiary.faithful(), spots[k])
			f.group = PATROL_GROUP
			f.state = "patrolling"
		return


func _patrol_room(i: int) -> bool:
	var p: Dictionary = level.pieces[i]
	return p.kind in ["junction", "chamber", "flooded", "lore", "stairs"] and level.is_walkable(p.rect.get_center())


## Free floor squares around `c`, nearest first.
func _free_floor_near(c: Vector2i, count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r in 3:
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				var q := c + Vector2i(x, y)
				if out.size() < count and maxi(absi(x), absi(y)) == r and level.get_tile(q) == Level.Tile.FLOOR and _enemy_at(q) == null and q != hero.grid_pos and not out.has(q):
					out.append(q)
	return out


## The patrol's leader, or null.
func patrol_leader() -> Combatant:
	for e in enemies:
		if e.alive() and e.state == "patrolling" and not e.route.is_empty():
			return e
	return null


## The patrol walking for `delta` seconds: the leader toward its waypoint (turning back at the ends), the others
## after it, stopping a little short of it.
func patrol_tick(delta: float) -> void:
	for leader in enemies:
		if not leader.alive() or leader.state != "patrolling" or leader.route.is_empty():
			continue
		if Battle.dist(leader.cell, leader.route[leader.route_i]) <= 1:
			if leader.route_i + leader.route_dir < 0 or leader.route_i + leader.route_dir >= leader.route.size():
				leader.route_dir = -leader.route_dir
			leader.route_i += leader.route_dir
		_roam(leader, leader.route[leader.route_i], MovementRules.PATROL_SPEED, delta)
		for f in enemies:
			if f != leader and f.alive() and f.state == "patrolling" and f.group == leader.group:
				var gap: float = views[f].position.distance_to(views[leader].position)
				if gap > MovementRules.FOLLOW_GAP * TILE:
					# a follower that has fallen behind hurries to catch up
					_roam(f, leader.cell, MovementRules.PATROL_SPEED * (1.6 if gap > TILE * 4 else 1.15), delta)


## Move a creature toward a square for `delta` seconds at `speed` m/s, along a route that goes round walls and cuts
## corners. It waits rather than walk into Thomas or another creature. Its route is worked out again when its goal
## moves.
func _roam(e: Combatant, goal: Vector2i, speed: float, delta: float) -> void:
	var v: ActorView = views[e]
	var radius := MovementRules.px(MovementRules.ENEMY_RADIUS)
	var r: Dictionary = _routes.get_or_add(e, {"goal": Vector2i(-9999, -9999), "path": [], "age": INF})
	r.age += delta
	if (r.goal != goal and r.age >= MovementRules.REPATH_EVERY) or ((r.path as Array).is_empty() and e.cell != goal):
		r.goal = goal
		r.age = 0.0
		# round the creatures standing near it (those further off will have moved by the time it gets there)
		r.path = Array(MovementRules.route(level, v.position, MovementRules.centre(goal), radius, _bodies_near(e, v.position, 3)))
	var p: Array = r.path
	if p.is_empty():
		return
	var step := MovementRules.px(speed) * delta
	step *= MovementRules.slow_in(level, e.cell, e.wades)
	var target: Vector2 = p[0]
	var to := v.position.move_toward(target, step)
	# someone is in the way: find a way round them; stuck for long, squeeze past the others (never through Thomas).
	# Only steps that bring it closer to someone count, so two that already overlap can walk apart.
	var from := v.position
	var in_way := _bodies_near(e, to).filter(func(b): return (b[0] as Vector2).distance_to(to) < (b[0] as Vector2).distance_to(from))
	if r.get("blocked", 0.0) >= 0.5:
		in_way = in_way.filter(func(b): return b[0] == hero.position)
	if MovementRules.overlaps(to, radius, in_way):
		r.blocked = r.get("blocked", 0.0) + delta
		r.age = MovementRules.REPATH_EVERY
		r.goal = Vector2i(-9999, -9999)
		return
	r.blocked = 0.0
	if to.distance_to(target) < 0.5:
		p.pop_front()
	v.glide_free(to, speed / MovementRules.WALK_SPEED)
	e.pos = to


## The nearest point to `p` where a body of radius `r` can stand: `p` itself on open floor, or the closest spot in
## an open square within two squares (a click on a wall walks up to it). INF if there is none.
func open_spot_near(p: Vector2, r: float) -> Vector2:
	var c := MovementRules.cell_of(p)
	if level.is_walkable(c):
		return MovementRules.push_out(level, p, r)
	var best := Vector2.INF
	for y in range(-2, 3):
		for x in range(-2, 3):
			var q := c + Vector2i(x, y)
			if not level.is_walkable(q):
				continue
			var box := Rect2(Vector2(q * TILE), Vector2(TILE, TILE)).grow(-r)
			var spot := MovementRules.push_out(level, p.clamp(box.position, box.end), r)
			if spot.distance_to(p) < best.distance_to(p):
				best = spot
	return best


## Thomas and the other creatures near a point, as [centre, radius], for a roaming creature not to walk into.
func _bodies_near(me: Combatant, at: Vector2, squares := 2) -> Array:
	var out: Array = []
	var radius := MovementRules.px(MovementRules.ENEMY_RADIUS)
	if hero.position.distance_to(at) < TILE * squares:
		out.append([hero.position, MovementRules.px(MovementRules.HERO_RADIUS)])
	for e in enemies:
		if e != me and e.alive() and not e.fled and views[e].position.distance_to(at) < TILE * squares:
			out.append([views[e].position, radius])
	return out


## Anyone stepping into water sends a ripple out across it.
func _on_stepped(_from: Vector2i, to: Vector2i) -> void:
	if level != null and level.is_wet(to):
		_ripple(to, false)


func _ripple(c: Vector2i, splash: bool) -> void:
	ripples_made += 1
	Ripple.spawn(gore, ActorView.cell_to_px(c) + Vector2(0, 9), splash)


## A level's seed: depth 1 uses the life's seed, deeper levels a mix of it and the depth. A new life (a new seed)
## gets a whole new world; the same life always gets the same levels.
static func depth_seed(life: int, d: int) -> int:
	return life if d <= 1 else hash([life, d])


## Groups wait in junctions and chambers (and half the time in the stairs room), never in the entry and never near
## the start. Garrick waits in the Outflow.
func _spawn_enemies() -> void:
	var group := 0
	var pick := RandomNumberGenerator.new()
	pick.seed = hash([level.seed_value, "enemies"])
	if level.outflow.has_area():
		_add_enemy(Bestiary.garrick(), level.outflow.get_center()).group = 1000
	for p in level.pieces:
		if not p.kind in ["junction", "chamber", "flooded", "stairs"]:
			continue
		if pick.randf() >= (STAIRS_GUARD_CHANCE if p.kind == "stairs" else GROUP_CHANCE):
			continue
		var c: Vector2i = p.rect.get_center()
		if not level.is_walkable(c) or level.find_path(level.start, c).size() < START_DISTANCE:
			continue
		var miner := group % 2 == 0
		var want := 3 if miner else 3 + depth
		if miner:
			_add_enemy(Bestiary.drowned_miner(), c).group = group
		var placed := 0
		for d in [Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(-2, -1), Vector2i(2, -1), Vector2i(1, 2), Vector2i(-1, 2), Vector2i(0, -2), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 0)]:
			if placed >= want:
				break
			var q: Vector2i = c + d
			# floor or shallow water: in a flooded room the Faithful stand in the water
			var t := level.get_tile(q)
			if (t == Level.Tile.FLOOR or t == Level.Tile.WATER) and _enemy_at(q) == null:
				_add_enemy(Bestiary.faithful(), q).group = group
				placed += 1
		group += 1
	for _n in PATROLS:
		_spawn_patrol(pick)
	# lurkers: a Drowned Miner lying under the sewage in the middle stretch of each sewage tunnel
	for i in level.sewage.size():
		var r: Rect2i = level.sewage[i]
		var deep: Array[Vector2i] = []
		# the middle stretch: a block in from each end, along the tunnel (not across it)
		var mid := Rect2i(r.position + Vector2i(4, 0), r.size - Vector2i(8, 0)) if r.size.x > r.size.y else Rect2i(r.position + Vector2i(0, 4), r.size - Vector2i(0, 8))
		for y in range(mid.position.y, mid.end.y):
			for x in range(mid.position.x, mid.end.x):
				var c := Vector2i(x, y)
				if level.get_tile(c) == Level.Tile.DEEP and _enemy_at(c) == null and level.find_path(level.start, c).size() >= START_DISTANCE:
					deep.append(c)
		for _k in StealthRules.LURKERS_PER_TUNNEL:
			if deep.is_empty():
				break
			var c: Vector2i = deep.pop_at(pick.randi_range(0, deep.size() - 1))
			var l := _add_enemy(Bestiary.lurker(), c)
			l.group = 2000 + i
			views[l].visible = false


## After learning something: rebuild Thomas's abilities, passives and stats.
func _apply_progress() -> void:
	var ratio := float(hero_unit.stamina) / float(hero_unit.max_stamina)
	hero_unit.max_stamina = progress.max_stamina()
	hero_unit.stamina = maxi(hero_unit.stamina, roundi(ratio * hero_unit.max_stamina)) if hero_unit.stamina > 0 else hero_unit.stamina
	hero_unit.might = int(progress.stats.might)
	hero_unit.agility = int(progress.stats.agility)
	hero_unit.basic = Abilities.basic_for(progress.backstory)
	hero_unit.abilities = progress.abilities()
	hero_unit.perks = progress.perks()
	combat_hud.set_abilities(hero_unit.abilities)
	_refresh()


func _add_enemy(u: Combatant, c: Vector2i) -> Combatant:
	u.cell = c
	var v := EnemyView.new()
	v.style = u.style
	v.stepped.connect(_on_stepped)
	actors.add_child(v)
	v.place(c)
	v.facing = -1
	v.look = Vector2.LEFT
	enemies.append(u)
	views[u] = v
	return u


func _enemy_at(c: Vector2i) -> Combatant:
	for e in enemies:
		if e.alive() and e.cell == c:
			return e
	return null


func in_fight() -> bool:
	return battle != null and not battle.over


## Where the movement keys or stick point right now, length 0..1 (keys give a full-length 8-way direction).
func held_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## In a fight, the keys walk Thomas smoothly, spending his metres as he goes (the mouse is the main way to move,
## as in Baldur's Gate 3).
func _tick_fight_keys(delta: float) -> void:
	var wish := held_vector()
	if wish == Vector2.ZERO or not _can_act() or paused():
		return
	var step := wish.limit_length(1.0) * MovementRules.px(MovementRules.WALK_SPEED) * delta
	var ev := battle.hero_nudge(hero_unit.pos + step)
	if ev.is_empty():
		return
	if ev.all(func(x): return x.t == "move" or x.t == "door"):
		if ev.any(func(x): return x.t == "door"):
			view.queue_redraw()
		hero.glide_free(hero_unit.pos, wish.length())
		_refresh()
	else:
		_act(ev)   # a free strike as he pulls away: play it out


## Thomas moving freely for `delta` seconds: the keys (or a stick) steer him, or he follows a clicked route. He
## speeds up and stops quickly, slides along walls, opens doors he walks into, and is slower in water.
func _tick_explore(delta: float) -> void:
	if in_fight() or dead or won or busy or level == null:
		_vel = Vector2.ZERO
		return
	var wish := held_vector() if not paused() else Vector2.ZERO
	if wish != Vector2.ZERO:
		path.clear()
		_ambush = null
	elif not path.is_empty():
		wish = _path_wish()
	if _relight > 0.0:
		# striking a light: he stands still until it catches
		wish = Vector2.ZERO
		path.clear()
		_relight -= delta
		if _relight <= 0.0:
			set_lantern("lit")
			_make_noise(StealthRules.NOISE_RELIGHT)
	var top := MovementRules.px(MovementRules.WALK_SPEED)
	top *= MovementRules.slow_in(level, hero.grid_pos, hero_unit.wades)
	if sneaking:
		top *= StealthRules.SNEAK_SPEED
	var before := _vel
	_vel = MovementRules.steer(_vel, wish, top, delta)
	_turn_dust(before, wish, top, delta)
	if _vel.length_squared() < 0.01 or delta <= 0.0:
		_vel = Vector2.ZERO
		return
	var r := MovementRules.px(MovementRules.HERO_RADIUS)
	var from := hero.position
	var to := MovementRules.slide(level, from, _vel * delta, r, _bodies())
	# a wall or a body took some of the motion: keep only what was used, so he doesn't keep pushing into it
	_vel = (to - from) / delta
	if not path.is_empty() and from.distance_to(to) < 0.2:
		_stuck += delta
		if _stuck > MovementRules.STUCK_AFTER:
			path.clear()
	else:
		_stuck = 0.0
	_open_doors(to, r)
	hero.glide_free(to, _vel.length() / MovementRules.px(MovementRules.WALK_SPEED))
	hero_unit.pos = to
	_make_noise(StealthRules.noise_radius(sneaking, level.is_wet(hero.grid_pos)))
	if _then.is_valid() and hero.position.distance_to(MovementRules.centre(_then_at)) <= Items.REACH * TILE:
		var then := _then
		_then = Callable()
		stop_walking()
		then.call()
	if _ambush != null and _ambush.alive() and not in_fight():
		_ambush.pos = views[_ambush].position
		if Battle.in_reach(hero_unit, _ambush):
			_start_battle(_ambush)
			return
	if level.get_tile(hero.grid_pos) == Level.Tile.STAIRS:
		_descend()
	elif hero.grid_pos == tag_cell:
		_win()


## Which way the clicked route leads from here, easing off into the last point so he stops on it.
func _path_wish() -> Vector2:
	var p := hero.position
	var d := path[0] - p
	while d.length() <= MovementRules.ARRIVE:
		path.remove_at(0)
		if path.is_empty():
			return Vector2.ZERO
		d = path[0] - p
	if path.size() > 1:
		return d.normalized()
	var braking := MovementRules.px(MovementRules.WALK_SPEED) * MovementRules.STOP_TIME
	return d.normalized() * clampf(d.length() / maxf(braking, 1.0), 0.2, 1.0)


## The creatures Thomas can bump into, as [centre, radius].
func _bodies() -> Array:
	var out: Array = []
	for e in enemies:
		if e.alive() and not e.fled and views[e].visible and views[e].position.distance_to(hero.position) < TILE * 2:
			out.append([views[e].position, MovementRules.px(MovementRules.ENEMY_RADIUS)])
	return out


func _open_doors(p: Vector2, r: float) -> void:
	for c in MovementRules.cells_touched(p, r + 1.0):
		if level.get_tile(c) == Level.Tile.DOOR_CLOSED:
			level.set_tile(c, Level.Tile.DOOR_OPEN)
			view.queue_redraw()


## A sharp turn at speed kicks up a little grit behind him.
func _turn_dust(before: Vector2, wish: Vector2, top: float, delta: float) -> void:
	_dust_cool -= delta
	if _dust_cool > 0.0 or wish == Vector2.ZERO or before.length() < MovementRules.TURN_DUST_SPEED * top:
		return
	if absf(rad_to_deg(before.angle_to(wish))) >= MovementRules.TURN_DUST_ANGLE:
		_dust_cool = MovementRules.TURN_DUST_COOLDOWN
		dust_made += 1
		Dust.spawn(gore, hero.position + Vector2(0, 10), -before)


func _after_him(e: Combatant) -> bool:
	return e.state == "hunting" or e.state == "searching"


## A fight starts where everyone stands: their fight positions are where their bodies are now.
func _take_positions() -> void:
	hero_unit.pos = hero.position
	for e in enemies:
		if e.alive() and not e.fled:
			e.pos = views[e].position
	_routes.clear()
	_vel = Vector2.ZERO


## Garrick's tally tag is in Thomas's hand: the run is won.
func _win() -> void:
	stop_walking()
	won = true
	tag_cell = Vector2i(-1, -1)
	view.queue_redraw()
	combat_hud.show_banner("Garrick's brass tally tag, still on its cord. The First Shift is over.\nYou have won this run.   Press R to begin again.", 99999.0)
	_update_hud()


func _descend() -> void:
	stop_walking()
	new_level(life_seed, true)
	combat_hud.show_banner("Deeper.   Depth %d" % depth, 2.0)


## Start walking to the middle of a square. Returns false if it can't be reached.
func walk_to(target: Vector2i) -> bool:
	return walk_to_point(MovementRules.centre(target))


## Start walking to exactly this point, along a route that goes round walls and cuts corners. Returns false if it
## can't be reached.
func walk_to_point(target: Vector2) -> bool:
	var r := MovementRules.px(MovementRules.HERO_RADIUS)
	var dest := open_spot_near(target, r)
	if dest == Vector2.INF:
		return false
	var route := MovementRules.route(level, hero.position, dest, r)
	if route.is_empty():
		return false
	path = route
	_stuck = 0.0
	return true


func stop_walking() -> void:
	path.clear()
	if not _then.is_valid() or hero.position.distance_to(MovementRules.centre(_then_at)) > Items.REACH * TILE:
		_then = Callable()
	overlay.queue_redraw()


## Outside a fight the world runs in real time: the patrol walks its route, hunters close in on Thomas, searchers go
## to where they last saw him, and runaways come back after a while. Anyone who sees him starts a fight. The world
## holds still while the skill tree is open.
func _tick_world(delta: float) -> void:
	if in_fight() or dead or won or level == null or paused():
		return
	for e in enemies:
		if not e.alive() or e.fled:
			continue
		if e.state == "lurking":
			_tick_lurker(e, delta)
			if in_fight():
				return
			continue
		if _after_him(e):
			var goal := hero.grid_pos if e.state == "hunting" else e.target
			_roam(e, goal, MovementRules.HUNT_SPEED, delta)
			if e.state == "searching" and e.cell == e.target:
				e.state = "idle"
		elif e.state == "suspicious" or e.state == "investigating":
			_tick_suspicion(e, delta)
		elif e.state == "idle":
			_look_about(e, delta)
	patrol_tick(delta)
	for r in returning.duplicate():
		r[1] -= delta
		if r[1] <= 0.0:
			returning.erase(r)
			_bring_back(r[0])
	_check_spotted(delta)


## A runaway returns from somewhere Thomas can't see, partly healed, with two more Faithful.
func _bring_back(u: Combatant) -> void:
	var best := Vector2i(-1, -1)
	var best_d := -1
	for room in level.rooms:
		var c := room.get_center()
		var d := Battle.dist(c, hero.grid_pos)
		if level.get_tile(c) == Level.Tile.FLOOR and _enemy_at(c) == null and not level.line_of_sight(c, hero.grid_pos) and d > best_d:
			best_d = d
			best = c
	if best.x < 0:
		return
	u.fled = false
	u.fleeing = false
	u.stamina = maxi(u.stamina, int(u.max_stamina * 0.6))
	u.prone = false
	u.dazed = 0
	u.slowed = 0
	u.telegraph.clear()
	u.cell = best
	u.state = "hunting"
	var v: ActorView = views[u]
	v.visible = true
	v.modulate.a = 1.0
	v.place(best)
	v.sync(u)
	var added := 0
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		if added >= 2:
			break
		var p: Vector2i = best + d
		if level.get_tile(p) == Level.Tile.FLOOR and _enemy_at(p) == null:
			var f := Bestiary.faithful()
			f.state = "hunting"
			f.group = u.group
			_add_enemy(f, p)
			added += 1
	combat_hud.show_banner("Somewhere behind you, bare feet on stone.", 2.2)


## The game waits while a menu is open: the skill tree, or choosing a backstory.
func paused() -> bool:
	return tree_screen.visible or backstory_screen.visible


## A new life begins as the chosen backstory: Fury (maces) or Shadow (daggers).
func choose_backstory(b: String) -> void:
	var at := hero.position
	views.erase(hero_unit)
	progress = Progress.for_backstory(b)
	hero_unit = Bestiary.thomas(progress)
	hero_unit.pos = at
	views[hero_unit] = hero
	hero.sync(hero_unit)
	combat_hud.set_abilities(hero_unit.abilities)
	combat_hud.refresh(hero_unit, null, true)
	combat_hud.set_belt(progress.belt)
	combat_hud.show_banner("Thomas Wren, %s." % ("who fights angry" if b == "fury" else "who kills quietly"), 2.0)
	_update_hud()


## The level's crates, barrels, satchels, valve and grate, drawn among the creatures.
func _place_cover_props() -> void:
	for c in actors.get_children():
		if c is CoverProp:
			c.queue_free()
	_props.clear()
	_draining.clear()
	for c in level.cover:
		_props[c] = CoverProp.spawn(actors, c, level.cover[c])
	for c in level.caches:
		var cache: Dictionary = level.caches[c]
		if cache.kind == "satchel" and not cache.get("drowned", false):
			_props[c] = CoverProp.spawn(actors, c, "satchel")
	if level.valve.x >= 0:
		_props[level.valve] = CoverProp.spawn(actors, level.valve, "valve")
	if not level.grate.is_empty():
		var mid := (MovementRules.centre(level.grate[0]) + MovementRules.centre(level.grate[-1])) / 2.0
		_props[level.grate[0]] = CoverProp.spawn(actors, level.grate[0], "grate_" + level.grate_across, mid)


## E, exploring: search the nearest cache within reach, turn the valve, or unlock the grate. Returns what happened:
## "searched", "full", "empty", "valve", "drained", "unlocked", "locked" or "" (nothing within reach).
func interact() -> String:
	var best := Vector2i(-1, -1)
	var best_d := Items.REACH * TILE
	var targets: Array[Vector2i] = []
	for c in level.caches:
		var cache: Dictionary = level.caches[c]
		if not cache.opened and not cache.get("drowned", false):
			targets.append(c)
	if level.valve.x >= 0:
		targets.append(level.valve)
	for g in level.grate:
		targets.append(g)
	for c in targets:
		var d := hero.position.distance_to(MovementRules.centre(c))
		if d <= best_d:
			best_d = d
			best = c
	if best.x < 0:
		return ""
	if best == level.valve:
		return _turn_valve()
	if level.grate.has(best):
		return _unlock_grate()
	return _search(best)


## Search a cache: its item goes on the belt (a full belt leaves it there). Rummaging makes a little noise.
func _search(c: Vector2i) -> String:
	var cache: Dictionary = level.caches[c]
	_make_noise(Items.SEARCH_NOISE)
	var what: String = {"crate": "the crate", "barrel": "the barrel", "satchel": "the drowned man's satchel"}.get(cache.kind, "it")
	if not progress.add_to_belt(cache.item):
		combat_hud.show_banner("In %s: %s. His belt is full; he leaves it." % [what, Items.NAMES[cache.item].to_lower()], 2.0)
		return "full"
	cache.opened = true
	if _props.has(c):
		_props[c].open()
	combat_hud.show_banner("In %s: %s." % [what, Items.NAMES[cache.item].to_lower()], 1.8)
	combat_hud.set_belt(progress.belt)
	return "searched"


## The sluice valve: turning it drains the flooded room it feeds, row by row.
func _turn_valve() -> String:
	if level.drain.is_empty():
		combat_hud.show_banner("The valve is turned as far as it goes.", 1.4)
		return "drained"
	if _props.has(level.valve):
		_props[level.valve].turn()
	_draining = level.drain.duplicate()
	_draining.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	level.drain.clear()
	_drain_timer = 0.0
	_make_noise(StealthRules.NOISE_WALK)
	combat_hud.show_banner("The valve groans round. Somewhere, water drains away.", 2.2)
	return "valve"


## Water running out of the basin a row at a time; when it is gone, what lay under it can be reached.
func _tick_drain(delta: float) -> void:
	if _draining.is_empty():
		return
	_drain_timer -= delta
	if _drain_timer > 0.0:
		return
	_drain_timer = 0.35
	var row: int = _draining[0].y
	while not _draining.is_empty() and _draining[0].y == row:
		var c: Vector2i = _draining.pop_front()
		level.set_tile(c, Level.Tile.FLOOR)
		level.drained[c] = true
	view.queue_redraw()
	if _draining.is_empty():
		for c in level.caches:
			var cache: Dictionary = level.caches[c]
			if cache.get("drowned", false):
				cache.drowned = false
				_props[c] = CoverProp.spawn(actors, c, "satchel")


## The locked grate: the key from this level's caches opens it (and is used up).
func _unlock_grate() -> String:
	if level.get_tile(level.grate[0]) == Level.Tile.GRATE_OPEN:
		return ""
	if not progress.belt.has("grate_key"):
		combat_hud.show_banner("Locked. The key must be somewhere on this level.", 1.8)
		return "locked"
	progress.belt.erase("grate_key")
	for g in level.grate:
		level.set_tile(g, Level.Tile.GRATE_OPEN)
	if _props.has(level.grate[0]):
		_props[level.grate[0]].open()
	combat_hud.set_belt(progress.belt)
	combat_hud.show_banner("The key turns. The grate swings open.", 1.8)
	return "unlocked"


## 6-9: use what is in that belt slot. In a fight a salve or bandage takes a maneuver; outside one a salve heals at
## once. The key is used at the grate (E).
func use_belt(slot: int) -> void:
	if slot < 0 or slot >= progress.belt.size():
		return
	var item: String = progress.belt[slot]
	if in_fight():
		if not _can_act():
			return
		var ev := battle.hero_use(item)
		if ev.any(func(e): return e.t == "heal" or (e.t == "status" and item == "bandage")):
			progress.belt.remove_at(slot)
			combat_hud.set_belt(progress.belt)
		_act(ev)
		return
	match item:
		"salve":
			if hero_unit.stamina >= hero_unit.max_stamina:
				combat_hud.show_banner("He isn't hurt.", 1.2)
				return
			hero_unit.stamina = mini(hero_unit.max_stamina, hero_unit.stamina + Items.SALVE_HEAL)
			progress.belt.remove_at(slot)
			combat_hud.show_banner("He smears salve into his wounds.", 1.4)
			_refresh()
		"bandage":
			combat_hud.show_banner("Nothing is bleeding. A bandage is for a fight.", 1.4)
		"grate_key":
			combat_hud.show_banner(Items.TEXT.grate_key, 1.8)
	combat_hud.set_belt(progress.belt)


## Can this creature see Thomas right now: close enough (MovementRules.SIGHT metres), in its view (a cone the way
## it faces; all round when it is close or already after him), with a clear line of sight?
func sees_thomas(e: Combatant) -> bool:
	if not e.alive() or e.fled or not views[e].visible or e.state == "lurking":
		return false
	var v: ActorView = views[e]
	var d := v.position.distance_to(hero.position)
	if d > MovementRules.px(MovementRules.SIGHT):
		return false
	# crouched right behind a crate or barrel, he is hidden (unless it is close enough to notice anything)
	if sneaking and d > MovementRules.px(StealthRules.AROUND) and StealthRules.behind_cover(level, v.position, hero.position):
		return false
	return StealthRules.in_view(v.position, v.look, hero.position, _after_him(e)) and level.line_of_sight(e.cell, hero.grid_pos)


## How light it is where Thomas stands (0 black .. 1), counting his own lantern.
func light_on_thomas() -> float:
	return StealthRules.light_at(hero.position, Grounding.lights, lantern)


## Everyone who can see Thomas fills their spotting meter (sneaking spec); out of sight it drains. Half full, an
## enemy is suspicious and comes to look; full, it has spotted him and the fight starts. With no `delta` (tests),
## anyone who can see him spots him at once.
func _check_spotted(delta := INF) -> void:
	if in_fight() or dead:
		return
	var light := light_on_thomas()
	for e in enemies:
		if not e.alive() or e.fled:
			continue
		if sees_thomas(e):
			var d := MovementRules.metres(views[e].position.distance_to(hero.position))
			var t := StealthRules.FILL_FAST if _after_him(e) else StealthRules.fill_time(d, light, sneaking)
			if sneaking and level.get_tile(hero.grid_pos) == Level.Tile.WATER:
				t *= StealthRules.WATER_HIDE   # crouched in water, half of him is under it
			elif sneaking and level.get_tile(hero.grid_pos) == Level.Tile.DEEP:
				t *= StealthRules.DEEP_HIDE    # crouched in the sewage, only his head shows
			e.alert = minf(1.0, e.alert + delta / t)
			e.target = hero.grid_pos
			if e.alert >= 1.0:
				_start_battle()
				return
			if e.alert >= StealthRules.SUSPICIOUS_AT:
				_become_suspicious(e, hero.grid_pos)
		else:
			e.alert = maxf(0.0, e.alert - StealthRules.DRAIN * (delta if delta < INF else 1.0))


## A lurker under the sewage. Crouched within 6 m with a clear view for a moment, Thomas spots its tell, and it shows
## (he can strike it first). Within 2 m it rises, and if he hadn't spotted it, it strikes first and he is surprised.
func _tick_lurker(e: Combatant, delta: float) -> void:
	var v: ActorView = views[e]
	var d := MovementRules.metres(v.position.distance_to(hero.position))
	if not e.noticed and sneaking and d <= StealthRules.LURKER_NOTICE and level.line_of_sight(hero.grid_pos, e.cell):
		_watching[e] = _watching.get(e, 0.0) + delta
		if _watching[e] >= StealthRules.LURKER_NOTICE_TIME:
			notice_lurker(e)
	if d <= StealthRules.LURKER_RISE:
		lurker_rises(e)


## Thomas has spotted a lurker's tell: it shows, faintly, and he can strike it from the dark.
func notice_lurker(e: Combatant) -> void:
	e.noticed = true
	var v: ActorView = views[e]
	v.visible = true
	v.modulate.a = 0.45
	combat_hud.show_banner("Bubbles, and a ring of scum that doesn't drift. Something lies under the sewage, waiting.", 2.4)


## It rises out of the sewage. Spotted, it is just a fight; unspotted, it strikes first and Thomas is surprised.
func lurker_rises(e: Combatant) -> void:
	var v: ActorView = views[e]
	v.visible = true
	v.modulate.a = 1.0
	e.state = "hunting"
	e.alert = 1.0
	stop_walking()
	combat_hud.show_banner("The sewage heaves, and something rises out of it." if e.noticed else "The sewage heaves at your feet. Something rises, already reaching for you.", 2.0)
	_start_battle(null, not e.noticed)


## Something caught a glimpse or a sound: it stops, stares toward `at`, then goes to look.
func _become_suspicious(e: Combatant, at: Vector2i) -> void:
	if _after_him(e):
		return
	if e.state != "suspicious" and e.state != "investigating":
		e.resume_state = e.state
	if e.state != "suspicious":
		e.wait = StealthRules.SUSPICIOUS_WAIT
	e.state = "suspicious"
	e.target = at
	views[e].face_point(MovementRules.centre(at))


## A suspicious enemy stares, then walks to where it saw or heard him, looks about, and goes back to what it was
## doing (a patrol picks up its route again).
func _tick_suspicion(e: Combatant, delta: float) -> void:
	if e.state == "suspicious":
		e.wait -= delta
		if e.wait <= 0.0:
			e.state = "investigating"
			e.wait = StealthRules.SEARCH_LOOK
		return
	if e.cell != e.target and level.find_path(e.cell, e.target).size() > 0:
		_roam(e, e.target, MovementRules.PATROL_SPEED, delta)
		return
	_look_about(e, delta * 3.0)
	e.wait -= delta
	if e.wait <= 0.0:
		e.state = e.resume_state if e.resume_state != "" else "idle"
		e.resume_state = ""


## An idle enemy turns its head now and then, toward open floor, so its view sweeps the room.
func _look_about(e: Combatant, delta: float) -> void:
	var v: ActorView = views[e]
	if not _heads.has(e):
		_heads[e] = _head_rng(e).randf_range(0.0, StealthRules.LOOK_ABOUT.y)
	_heads[e] -= delta
	if _heads[e] > 0.0:
		return
	var rng := _head_rng(e)
	_heads[e] = rng.randf_range(StealthRules.LOOK_ABOUT.x, StealthRules.LOOK_ABOUT.y)
	var open: Array[Vector2] = []
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
		if level.is_walkable(MovementRules.cell_of(v.position + dir * TILE * 2.0)):
			open.append(dir)
	if not open.is_empty():
		v.face_point(v.position + open[rng.randi_range(0, open.size() - 1)] * 10.0)


## Each enemy's head turns come from the level's seed, its place and how many turns it has made, so a life repeats.
func _head_rng(e: Combatant) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([level.seed_value, enemies.find(e), int(_heads.get(e, 0.0) * 1000.0), roundi(views[e].look.angle() * 100.0)])
	return rng


## Thomas makes a sound `radius` metres across: anyone idle or patrolling who hears it comes to look.
func _make_noise(radius: float) -> void:
	if radius <= 0.0 or in_fight():
		return
	for e in enemies:
		if not e.alive() or e.fled or _after_him(e) or e.state == "suspicious" or e.state == "investigating" or e.state == "lurking":
			continue
		if StealthRules.hears(level, hero.position, views[e].position, radius):
			noises += 1
			e.alert = maxf(e.alert, StealthRules.SUSPICIOUS_AT * 0.6)
			_become_suspicious(e, hero.grid_pos)


## T: get ready to throw a dagger (needs Throw from the Daggers tree). Right-click to put it away.
func aim_throw() -> void:
	if not progress.owns("daggers", "throw"):
		combat_hud.show_banner("Thomas hasn't learned to throw a blade.", 1.4)
		return
	aiming_throw = not aiming_throw
	if aiming_throw:
		stop_walking()
		combat_hud.show_banner("Throw: click a lamp to put it out, or the stone to make a noise.", 2.0)


## How far a dagger can be thrown, in pixels.
static func throw_reach() -> float:
	return MovementRules.px(Abilities.throw().range * Battle.SQ)


## Throw a dagger outside a fight (free): landing by a lamp, it puts the lamp out and the area goes dark; anywhere
## else it clatters off the stone and the nearest enemy who hears it wanders off alone to look. Returns what happened:
## "doused", "clatter", "too far" or "no line".
func throw_at(p: Vector2) -> String:
	if hero.position.distance_to(p) > throw_reach():
		combat_hud.show_banner("Too far to throw.", 1.2)
		return "too far"
	var c := MovementRules.cell_of(p)
	var lamp_line := false
	for l in level.lights:
		if Battle.dist(l, c) <= StealthRules.DOUSE_REACH:
			lamp_line = true
			if level.line_of_sight(hero.grid_pos, l) or Battle.dist(hero.grid_pos, l) <= 1:
				douse_lamp(l)
				return "doused"
	if not lamp_line and not level.line_of_sight(hero.grid_pos, c):
		combat_hud.show_banner("No clear line to throw.", 1.2)
		return "no line"
	_clatter(p)
	return "clatter"


## A lamp or brazier goes out: its light is gone, and so is the light it threw on Thomas.
func douse_lamp(c: Vector2i) -> void:
	level.lights.erase(c)
	lighting.build(level)
	view.queue_redraw()
	combat_hud.show_banner("The dagger strikes the lamp. The light gutters and goes out.", 1.8)


## A dagger clatters at `p`: the nearest enemy who hears it (and isn't already after him) comes alone to look.
func _clatter(p: Vector2) -> void:
	var best: Combatant = null
	var best_d := INF
	for e in enemies:
		if not e.alive() or e.fled or _after_him(e) or e.state == "lurking":
			continue
		var d: float = (views[e] as ActorView).position.distance_to(p)
		if d < best_d and StealthRules.hears(level, p, views[e].position, StealthRules.CLATTER):
			best_d = d
			best = e
	combat_hud.show_banner("The dagger clatters off the stone.", 1.4)
	if best != null:
		noises += 1
		if best.state != "suspicious" and best.state != "investigating":
			best.resume_state = best.state
		best.state = "suspicious"
		best.wait = StealthRules.SUSPICIOUS_WAIT
		best.target = MovementRules.cell_of(p)
		views[best].face_point(p)


## C: crouch and sneak, or stand up.
func toggle_sneak() -> void:
	sneaking = not sneaking
	hero.sneaking = sneaking
	_update_hud()


## The lantern: lit, shuttered (a small dim pool) or out (dark, best for sneaking).
func set_lantern(state: String) -> void:
	lantern = state
	if hero_lantern == null:
		return
	hero_lantern.enabled = state != "out"
	if state == "shuttered":
		hero_lantern.energy = StealthRules.SHUTTERED_ENERGY
		hero_lantern.texture_scale = StealthRules.SHUTTERED_RADIUS * TILE * 2.0 / 256.0
	else:
		hero_lantern.energy = Lighting.HERO_ENERGY
		hero_lantern.texture_scale = Lighting.HERO_RADIUS * TILE * 2.0 / 256.0
	_update_hud()


## L: shutter the lantern or open it again; if it is out, strike a light (it takes a moment, standing still, and
## makes a little noise).
func shutter_lantern() -> void:
	if lantern == "out":
		if _relight <= 0.0:
			_relight = StealthRules.RELIGHT_TIME
			combat_hud.show_banner("Striking a light...", StealthRules.RELIGHT_TIME)
	else:
		set_lantern("lit" if lantern == "shuttered" else "shuttered")


## O: put the lantern out.
func douse_lantern() -> void:
	_relight = 0.0
	set_lantern("out")


## Start a fight. `ambush`: Thomas struck an unaware enemy from hiding, so he goes first and everyone who hadn't
## spotted him is surprised for the first round. `ambushed`: something struck him unawares (a lurker rising), so
## they go first and he is surprised.
func _start_battle(ambush: Combatant = null, ambushed := false) -> void:
	stop_walking()
	_ambush = null
	_take_positions()
	# whoever saw him, their band, and anything already hunting or searching for him, fight; the rest may join if
	# they see him
	var bands := {}
	if ambush != null:
		bands[ambush.group] = true   # the one he strikes, and its band, are in it whether or not they saw him
	for e in enemies:
		if e.alive() and not e.fled and (_after_him(e) or sees_thomas(e)):
			bands[e.group] = true
	var fighting: Array = []
	var others: Array[Combatant] = []
	for e in enemies:
		if not e.alive() or e.fled:
			continue
		if bands.has(e.group) or _after_him(e):
			fighting.append(e)
		else:
			others.append(e)
	fights += 1
	battle = Battle.new()
	battle.setup(level, hero_unit, fighting, level.seed_value * 7919 + fights)
	battle.bystanders = others
	for u in battle.units:
		# bodies the fight nudged apart
		if views[u].position.distance_to(u.pos) > 0.5:
			views[u].glide_along([u.pos], MovementRules.px(MovementRules.FIGHT_WALK_SPEED))
	if level.outflow.has_area() and fighting.any(func(u): return u.kind == "solo"):
		battle.arena = level.outflow
	for e in fighting:
		e.surprised = ambush != null and e.alert < 1.0
		e.alert = 0.0
	combat_hud.clear_log()
	combat_hud.show_fight(true)
	hero_unit.surprised = ambushed
	if ambushed:
		var ev := battle.start(false)
		ev.push_front({"t": "log", "text": "Caught unawares: they move first."})
		_act(ev)
	elif ambush != null:
		var ev := battle.start(true)
		ev.append({"t": "log", "text": "Thomas strikes from the dark. They didn't see him coming."})
		ev.append_array(battle.hero_ability_on(0, ambush))
		_act(ev)
	else:
		_act(battle.start(battle.roll_initiative()))


# ---------------------------------------------------------------- input

func _can_act() -> bool:
	return in_fight() and battle.is_hero_turn() and not busy and not dead


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K or (event.keycode == KEY_ESCAPE and tree_screen.visible):
			_toggle_tree()
			get_viewport().set_input_as_handled()
			return
	if paused():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		new_level(randi())
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		veteran = not veteran
		new_level(randi())
		combat_hud.show_banner("Test: a level 10 veteran with every mace skill." if veteran else "Back to a fresh Thomas.", 2.5)
		return
	if dead or won:
		return
	if in_fight() and _combat_input(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		stop_walking()
		get_viewport().set_input_as_handled()
	elif in_fight():
		pass
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		toggle_sneak()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
		shutter_lantern()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_O:
		douse_lantern()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		aim_throw()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		interact()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_6 and event.keycode <= KEY_9:
		use_belt(event.keycode - KEY_6)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and aiming_throw:
		aiming_throw = false
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		open_context_menu(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if aiming_throw:
			aiming_throw = false
			throw_at(get_global_mouse_position())
		else:
			creep_or_walk(get_global_mouse_position())
	_zoom_input(event)


## A click while exploring: on an enemy that hasn't spotted him, creep up and strike it from the dark; anywhere
## else, walk there.
func creep_or_walk(p: Vector2) -> void:
	_ambush = null
	_then = Callable()
	# a crate, the valve or the grate: walk up and use it (as Baldur's Gate 3's left-click does)
	var thing := thing_at(p)
	if not thing.is_empty():
		_go_and(thing.cell, thing.action)
		return
	for e in enemies:
		if e.alive() and not e.fled and views[e].visible and views[e].position.distance_to(p) <= MovementRules.px(MovementRules.ENEMY_RADIUS) + 8.0:
			_ambush = e
			walk_to_point(views[e].position)
			return
	walk_to_point(p)


## Right-click: a menu of what can be done with what is under the mouse (Thomas, an enemy, a crate, the valve, the
## grate, a lamp, the floor), in or out of a fight.
func open_context_menu(p: Vector2) -> void:
	var opts := context_options(p)
	if opts.is_empty():
		return
	context_menu.clear()
	_context_actions.clear()
	for i in opts.size():
		context_menu.add_item(opts[i][0], i)
		_context_actions.append(opts[i][1])
		if opts[i].size() > 2 and opts[i][2]:
			context_menu.set_item_disabled(i, true)   # shown, greyed, with the reason in its label
	context_menu.position = Vector2i(get_viewport().get_mouse_position()) + Vector2i(4, 4)
	context_menu.reset_size()
	context_menu.popup()


## The thing under the mouse that can be used, for left-click and the hover highlight: {cell, name, action}, or
## empty. Caches not yet searched, the valve, a shut grate.
func thing_at(p: Vector2) -> Dictionary:
	if level == null:
		return {}
	for k in level.caches:
		var cache: Dictionary = level.caches[k]
		if not cache.opened and not cache.get("drowned", false) and MovementRules.centre(k).distance_to(p) <= 18.0:
			return {"cell": k, "name": {"crate": "Crate", "barrel": "Barrel", "satchel": "Drowned miner's satchel"}.get(cache.kind, "Cache"), "action": _search.bind(k)}
	if level.valve.x >= 0 and MovementRules.centre(level.valve).distance_to(p) <= 18.0:
		return {"cell": level.valve, "name": "Sluice valve", "action": _turn_valve}
	for g in level.grate:
		if MovementRules.centre(g).distance_to(p) <= 20.0 and level.get_tile(g) == Level.Tile.GRATE_SHUT:
			return {"cell": g, "name": "Iron grate (locked)", "action": _unlock_grate}
	return {}


## The choices for a right-click at `p`, as [label, what it does] or [label, what it does, true] for one shown greyed
## out because it can't be done now (the label says why).
func context_options(p: Vector2) -> Array:
	if in_fight():
		return _fight_options(p)
	var out: Array = []
	var c := MovementRules.cell_of(p)
	# Thomas himself: crouching, the lantern, the belt
	if hero.position.distance_to(p) <= 14.0:
		out.append(["Stand up" if sneaking else "Crouch and sneak", toggle_sneak])
		match lantern:
			"lit":
				out.append(["Shutter the lantern", shutter_lantern])
				out.append(["Put the lantern out", douse_lantern])
			"shuttered":
				out.append(["Open the lantern", shutter_lantern])
				out.append(["Put the lantern out", douse_lantern])
			"out":
				out.append(["Light the lantern", shutter_lantern])
		for i in progress.belt.size():
			if progress.belt[i] != "grate_key":   # the key is used at the grate
				out.append(["Use the %s" % Items.NAMES[progress.belt[i]].to_lower(), use_belt.bind(i)])
		return out
	# an enemy: creep up and strike it
	for e in enemies:
		if e.alive() and not e.fled and views[e].visible and views[e].position.distance_to(p) <= MovementRules.px(MovementRules.ENEMY_RADIUS) + 8.0:
			out.append(["Strike from the dark" if not _after_him(e) and e.alert < 1.0 else "Attack", creep_or_walk.bind(views[e].position)])
			return out
	# things to search or work
	for k in level.caches:
		var cache: Dictionary = level.caches[k]
		if not cache.opened and not cache.get("drowned", false) and MovementRules.centre(k).distance_to(p) <= 20.0:
			var what: String = {"crate": "the crate", "barrel": "the barrel", "satchel": "the satchel"}.get(cache.kind, "it")
			out.append(["Search %s" % what, _go_and.bind(k, _search.bind(k))])
	if level.valve.x >= 0 and MovementRules.centre(level.valve).distance_to(p) <= 20.0:
		out.append(["Turn the valve", _go_and.bind(level.valve, _turn_valve)])
	for g in level.grate:
		if MovementRules.centre(g).distance_to(p) <= 24.0 and level.get_tile(g) == Level.Tile.GRATE_SHUT:
			out.append(["Unlock the grate" if progress.belt.has("grate_key") else "Try the grate", _go_and.bind(g, _unlock_grate)])
			break
	var lamp := false
	for l in level.lights:
		if Battle.dist(l, c) <= StealthRules.DOUSE_REACH:
			lamp = true
	if progress.owns("daggers", "throw"):
		out.append(["Throw a dagger at the lamp" if lamp else "Throw a dagger here (a clatter)", throw_at.bind(p)])
	if open_spot_near(p, MovementRules.px(MovementRules.HERO_RADIUS)) != Vector2.INF:
		out.append(["Walk here", walk_to_point.bind(p)])
		out.append(["Sneak here", func(): if not sneaking: toggle_sneak(); walk_to_point(p)])
	return out


func _fight_options(p: Vector2) -> Array:
	var out: Array = []
	if not _can_act():
		return out
	var t := battle.unit_at(p)
	if t == hero_unit:
		for i in progress.belt.size():
			if progress.belt[i] != "grate_key":
				out.append(["Use the %s (maneuver)" % Items.NAMES[progress.belt[i]].to_lower(), use_belt.bind(i)])
		if hero_unit.prone:
			out.append(["Stand up (maneuver)", func(): _act(battle.hero_stand())])
		out.append(["Catch your breath (main action)", func(): _act(battle.hero_catch_breath())])
		out.append(["End the turn", _end_hero_turn])
		return out
	if t != null and t.team != hero_unit.team:
		for i in hero_unit.abilities.size():
			var ab: Dictionary = hero_unit.abilities[i]
			var why := battle.cannot_use(hero_unit, ab)
			if why == "" and not battle.meets_needs(t, ab):
				why = "Only against one caught unaware, or flanked." if (ab.needs as Array).has("unaware") else "Only against a dazed, prone or dying enemy."
			if why != "":
				out.append(["%s: %s" % [ab.name, why.trim_suffix(".").to_lower()], Callable(), true])
				continue
			var near := Battle.in_reach(hero_unit, t, Battle.reach_of(ab))
			out.append([ab.name + ("" if near else " (walk up)"), func(): _select(-1); _act(battle.hero_close_and_strike(i, t))])
		return out
	var c := MovementRules.cell_of(p)
	if level.gates.has(c) and level.get_tile(c) == Level.Tile.GATE_OPEN:
		out.append(["Shut the sluice gate (main action)", func(): _act(battle.hero_shut_gate(c))])
	out.append(["Move here", func(): _act(battle.hero_move_to_point(p))])
	if battle.can_shift() and hero_unit.pos.distance_to(p) <= MovementRules.px(MovementRules.SHIFT) + 16.0:
		out.append(["Careful step here (maneuver)", func(): _act(battle.hero_shift_to(p))])
	return out


## Walk up to square `c` and then do `f` (search, turn the valve, unlock the grate); at once if he is already there.
func _go_and(c: Vector2i, f: Callable) -> void:
	if hero.position.distance_to(MovementRules.centre(c)) <= Items.REACH * TILE:
		f.call()
		return
	var spot := open_spot_near(MovementRules.centre(c) + (hero.position - MovementRules.centre(c)).limit_length(20.0), MovementRules.px(MovementRules.HERO_RADIUS))
	if spot != Vector2.INF and walk_to_point(spot):
		_then = f
		_then_at = c


func _zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var z := cam.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		z = clampf(z, 1.0, 4.0)
		cam.zoom = Vector2(z, z)


## Fight controls. Returns true if the event was used.
func _combat_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_6 and k <= KEY_9:
			use_belt(k - KEY_6)
			return true
		if k >= KEY_1 and k <= KEY_5:
			_on_ability_key(k - KEY_1)
			return true
		match k:
			KEY_ENTER, KEY_KP_ENTER, KEY_E:
				_end_hero_turn()
				return true
			KEY_Q:
				if _can_act():
					_act(battle.hero_stand())
				return true
			KEY_B:
				if _can_act():
					_act(battle.hero_catch_breath())
				return true
			KEY_F:
				_toggle_step()
				return true
			KEY_G:
				if _can_act():
					var g := battle.gate_in_reach()
					if g.x >= 0:
						_act(battle.hero_shut_gate(g))
					else:
						combat_hud.add_log("No open sluice gate within reach.")
				return true
			KEY_ESCAPE:
				_select(-1)
				return true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if selected >= 0 or stepping:
				_select(-1)
				stepping = false
				combat_hud.set_stepping(false)
			else:
				open_context_menu(get_global_mouse_position())
			return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.shift_pressed:
				stepping = true
			_combat_click(get_global_mouse_position())
			return true
	return false


## A click in a fight, anywhere: a careful step, the chosen ability on whoever is there, a gate to shut, an enemy
## to strike (walking up to it first if it is out of reach), or a spot to walk to.
func _combat_click(p: Vector2) -> void:
	if not _can_act():
		return
	if stepping:
		stepping = false
		combat_hud.set_stepping(false)
		_act(battle.hero_shift_to(p))
		return
	var t := battle.unit_at(p)
	if selected >= 0:
		var i := selected
		_select(-1)
		_act(battle.hero_close_and_strike(i, t) if t != null and t.team != hero_unit.team else battle.hero_ability_on(i, t))
		return
	var c := MovementRules.cell_of(p)
	if level.gates.has(c):
		_act(battle.hero_shut_gate(c))
	elif t != null and t.team != hero_unit.team:
		_act(battle.hero_close_and_strike(0, t))   # clicking an enemy strikes it, walking up first if needed
	else:
		_act(battle.hero_move_to_point(p))


## A number key or button: abilities that hit everyone, or have only one target, go at once.
func _on_ability_key(i: int) -> void:
	if not _can_act() or i < 0 or i >= hero_unit.abilities.size():
		return
	var ab: Dictionary = hero_unit.abilities[i]
	var why := battle.cannot_use(hero_unit, ab)
	if why != "":
		combat_hud.add_log(why)
		return
	var targets := battle.valid_targets(hero_unit, ab)
	if ab.target == "adjacent_all" or targets.size() == 1:
		_select(-1)
		_act(battle.hero_ability_on(i, targets[0] if targets.size() > 0 else null))
	elif targets.is_empty():
		combat_hud.add_log("No one in reach for %s." % ab.name if (ab.needs as Array).is_empty() else "No dazed, prone or dying enemy in reach.")
	else:
		_select(i)


func _toggle_tree() -> void:
	if tree_screen.visible:
		tree_screen.visible = false
	else:
		stop_walking()
		tree_screen.open(progress, not in_fight() and not dead)


func _toggle_step() -> void:
	if not _can_act():
		return
	if not stepping and not battle.can_shift():
		combat_hud.add_log("No maneuver left for a careful step." if battle.budget.maneuver <= 0 else "Thomas can't step while he is down.")
		return
	_select(-1)
	stepping = not stepping
	combat_hud.set_stepping(stepping)
	overlay.queue_redraw()


func _select(i: int) -> void:
	if i >= 0 and stepping:
		stepping = false
		combat_hud.set_stepping(false)
	selected = i
	combat_hud.select(i)
	overlay.queue_redraw()


func _end_hero_turn() -> void:
	if _can_act():
		_select(-1)
		_act(battle.hero_end_turn())


func mouse_cell() -> Vector2i:
	var p := get_global_mouse_position()
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


# ---------------------------------------------------------------- playing back fight events

func _act(events: Array) -> void:
	if events.is_empty():
		return
	_play(events)


func _play(events: Array) -> void:
	busy = true
	_refresh()
	for e in events:
		await _play_one(e)
	busy = false
	_refresh()
	overlay.queue_redraw()


func _play_one(e: Dictionary) -> void:
	match e.t:
		"start":
			combat_hud.show_banner("Something has seen you.", 1.4)
			_shake = 3.0
			await _wait(0.6)
		"log":
			combat_hud.add_log(e.text)
		"landed":
			var tree_id: String = {"mace": "maces", "dagger": "daggers"}.get(e.weapon, "")
			var got := progress.add_hit(tree_id)
			if got == "point":
				combat_hud.show_banner("A %s mastery point.   K to spend it after the fight." % ("dagger" if tree_id == "daggers" else "mace"), 1.6)
				await _wait(0.3)
		"malice":
			combat_hud.set_malice(e.value)
		"malice_spend":
			combat_hud.set_malice(e.value)
			combat_hud.show_banner("Malice: " + e.name, 1.2)
			_shake = 2.0
			await _wait(0.45)
		"join":
			views[e.unit].sync(e.unit)
			_shake = 2.0
			await _wait(0.25)
		"flee":
			views[e.unit].sync(e.unit)
			await _wait(0.2)
		"escape":
			var v: ActorView = views[e.unit]
			var tw := create_tween()
			tw.tween_property(v, "modulate:a", 0.0, 0.5)
			await _wait(0.5)
			v.visible = false
		"turn":
			if e.unit == hero_unit:
				combat_hud.show_banner("You're down. Q to stand." if hero_unit.prone else "Your turn", 1.2 if hero_unit.prone else 0.8)
				await _wait(0.2)
			else:
				await _wait(0.1)
		"resolve":
			_refresh()
		"move":
			var v: ActorView = views[e.unit]
			await _wait(v.glide_along(e.points, MovementRules.px(MovementRules.FIGHT_WALK_SPEED)) + 0.02)
		"door":
			view.queue_redraw()
		"flood":
			view.queue_redraw()
			_shake = maxf(_shake, 2.5)
			await _wait(0.3)
		"gate":
			view.queue_redraw()
			_shake = maxf(_shake, 3.0)
			await _wait(0.25)
		"attack":
			# the blow lands: drive forward, straight into the hit that follows
			var t = e.target
			if t != null:
				views[e.unit].lunge_at(t.pos, MovementRules.STRIKE_LUNGE, e.unit != hero_unit)
				await _wait(0.05)
		"roll":
			# draw back while the dice roll; a heavy blow holds the wind-up a moment longer
			var striker: ActorView = views[e.unit]
			striker.wind_up(e.get("at", e.unit.pos), MovementRules.WINDUP_PULL)
			if e.unit == hero_unit:
				hero.play_attack(e.ability.id, e.roll.crit)
			combat_hud.dice.show_roll(e.roll, e.unit.name, e.ability.name)
			await _wait(0.75 if e.roll.crit else 0.5)
			if heavy_blow(e.unit, e.ability):
				await _wait(MovementRules.WINDUP_PAUSE)
		"hit":
			await _play_hit(e)
		"push":
			# one smooth slide the whole way, fast at first and easing to a stop
			var v: ActorView = views[e.unit]
			var pts: Array = e.points
			if not pts.is_empty():
				v.play_once("pushed_back")
				var from := v.position
				var squares := from.distance_to(pts[-1]) / TILE
				var time := MovementRules.PUSH_TIME_PER_SQUARE * maxf(squares, 1.0) + 0.04
				v.glide_along(pts, from.distance_to(pts[-1]) / time)
				if e.unit.stamina < e.unit.max_stamina * 0.6:
					gore.smear(from, pts[-1])
				await _wait(time)
		"slam":
			_shake = 7.0
			views[e.unit].play_once("wall_slam")
			var wall: Vector2 = e.at
			var body: Vector2 = e.unit.pos
			OneShot.spawn(world_ui, "res://assets/effects/mace/wall_slam.png", wall, 10.0, wall.x < body.x)
			Dust.spawn(gore, wall + Vector2(0, 6), body - wall, true)
			gore.splash(body, wall - body, 2.0)
			await _hitstop(0.08)
		"prone", "stand", "status", "heal":
			if e.t == "prone" and level.is_wet(e.unit.cell):
				_ripple(e.unit.cell, true)
			views[e.unit].sync(e.unit)
			_refresh()
			await _wait(0.12)
		"injury":
			var v: ActorView = views[e.unit]
			v.sync(e.unit)
			gore.splash(v.position, Vector2.ZERO, 4.0)
			_shake = 4.0
			await _wait(0.25)
		"dying":
			views[e.unit].sync(e.unit)
			combat_hud.show_banner("Thomas is dying", 1.6)
			_refresh()
			await _wait(0.5)
		"telegraph":
			views[e.unit].sync(e.unit)
			_shake = 1.5
			overlay.queue_redraw()
			await _wait(0.45)
		"telegraph_end":
			views[e.unit].sync(e.unit)
			overlay.queue_redraw()
		"smash":
			views[e.unit].lunge_at(e.band.centre, 12.0)
			_shake = 9.0
			await _hitstop(0.1)
		"death":
			if e.unit.kind == "solo":
				tag_cell = e.unit.cell
				overlay.queue_redraw()
			if e.unit != hero_unit:
				var gained := progress.add_xp({"minion": 1, "solo": 10}.get(e.unit.kind, 4))
				if gained > 0:
					hero_unit.max_stamina = progress.max_stamina()
					hero_unit.stamina += 3 * gained
					combat_hud.show_banner("Level %d.   K to see what you can learn." % progress.level, 1.8)
			var v: ActorView = views[e.unit]
			v.sync(e.unit)
			gore.pool(v.position, 6.0 if e.unit.kind == "minion" else 10.0)
			if e.crushed:
				gore.chunks(v.position + Vector2(0, -2))
			_shake = maxf(_shake, 5.0)
			await _wait(0.35)
		"end":
			await _wait(0.4)
			_finish(e.winner)


func _play_hit(e: Dictionary) -> void:
	var u: Combatant = e.unit
	var v: ActorView = views[u]
	v.hit_flash()
	OneShot.spawn(world_ui, "res://assets/effects/hits/tier_3.png" if e.tier >= 3 else "res://assets/effects/hits/crushing.png", v.position + Vector2(0, -10), 12.0)
	var dmg: int = e.dmg
	var away := Vector2.ZERO
	if battle != null and battle.active != null and battle.active != u:
		away = (v.position - views[battle.active].position).normalized()
	gore.splash(v.position, away, 1.0 + dmg * 0.4)
	if e.crit:
		await _crit_moment(v, dmg)
	else:
		_shake = maxf(_shake, MovementRules.SHAKE_BASE + dmg * MovementRules.SHAKE_PER_DAMAGE)
		await _hitstop(hitstop_for(e.tier))
	v.sync(u)
	_refresh()


## How long a hit freezes the world: longer for a stronger tier.
static func hitstop_for(tier: int) -> float:
	return MovementRules.HITSTOP[clampi(tier, 1, 3) - 1]


## A heavy blow gets a longer wind-up: one that costs Resolve, knocks down, or comes from a boss.
static func heavy_blow(u: Combatant, ab: Dictionary) -> bool:
	if int(ab.get("cost", 0)) > 0 or u.kind == "solo":
		return true
	for t in ab.get("tiers", []):
		if (t as Dictionary).get("prone", false):
			return true
	return false


## Crits: push in, slow everything down, hold, then let it land.
func _crit_moment(v: ActorView, dmg: int) -> void:
	var z := cam.zoom
	_focus = v.position
	Engine.time_scale = 0.15
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(cam, "zoom", z * 1.4, 0.15)
	await _wait(0.15)
	_shake = 10.0 + dmg * 0.3
	gore.splash(v.position, Vector2.ZERO, 5.0)
	await _wait(0.6)
	Engine.time_scale = 1.0
	var back := create_tween()
	back.tween_property(cam, "zoom", z, 0.3)
	_focus = null


func _hitstop(t: float) -> void:
	Engine.time_scale = 0.05
	await _wait(t)
	Engine.time_scale = 1.0


## Waits in real time, whatever the time scale.
func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _finish(winner: String) -> void:
	Engine.time_scale = 1.0
	_select(-1)
	combat_hud.show_fight(false)
	for u in enemies:
		if u.fled and not returning.any(func(r): return r[0] == u):
			returning.append([u, MovementRules.RETURN_AFTER])
	if winner == "escaped":
		combat_hud.show_banner("You've lost them, for now.", 2.0)
		for u in battle.units:
			if u.alive() and u != hero_unit:
				u.state = "searching"
				u.target = MovementRules.cell_of(battle.last_seen)
				u.telegraph.clear()
				views[u].sync(u)
	if winner == "hero" or winner == "escaped":
		if winner == "hero" and tag_cell.x >= 0:
			combat_hud.show_banner("Garrick falls. Something brass glints in the water.", 3.0)
		elif winner == "hero":
			combat_hud.show_banner("The fight is over." if returning.is_empty() else "The fight is over. Something got away.", 2.0)
		hero_unit.resolve = 0
		hero_unit.prone = false
		hero_unit.dazed = 0
		hero_unit.slowed = 0
		hero_unit.bleeding = false
		hero_unit.surprised = false
		if hero_unit.stamina <= 0:
			hero_unit.stamina = 1
			hero_unit.dying = false
		hero.sync(hero_unit)
		hero.glide_free(hero_unit.pos, 0.0)
		_vel = Vector2.ZERO
		_routes.clear()
		battle = null
		overlay.queue_redraw()
	else:
		dead = true
		combat_hud.show_banner("Thomas Wren is dead.   Press R to wake again.", 99999.0)
	_refresh()


# ---------------------------------------------------------------- every frame

func _process(delta: float) -> void:
	if in_fight():
		_tick_fight_keys(delta)
	_tick_explore(delta)
	_tick_world(delta)
	_tick_drain(delta)
	Grounding.hero_light = hero.position if lantern != "out" else Vector2.INF
	var target: Vector2 = _focus if _focus != null else hero.position
	cam.position = cam.position.lerp(target, 1.0 - exp(-delta * 12.0))
	if _shake > 0.05:
		cam.offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake
		_shake = lerpf(_shake, 0.0, 1.0 - exp(-delta * 14.0))
	else:
		cam.offset = Vector2.ZERO
	_tick_hover()
	overlay.queue_redraw()   # cones, meters and routes move every frame


## What is under the mouse (for the HUD's line about an enemy), updated when the mouse or Thomas moves.
func _tick_hover() -> void:
	var m := get_global_mouse_position()
	if m.distance_to(_hover_px) < 1.5 and hero.position.distance_to(_hover_from) < 3.0:
		return
	_hover = MovementRules.cell_of(m)
	_hover_px = m
	_hover_from = hero.position
	overlay.queue_redraw()
	_update_hud()


func _refresh() -> void:
	combat_hud.refresh(hero_unit, battle, not busy)
	_update_hud()


func _update_hud() -> void:
	if hud == null:
		return
	var e := _enemy_at(_hover) if level != null else null
	if e != null:
		var words := [e.health_word()] + Array(e.condition_words())
		hud.text = "%s:  %s" % [e.name, ", ".join(words)]
	elif dead or won:
		hud.text = "R to start again"
	elif in_fight():
		hud.text = "Click anywhere to move  ·  click an enemy to strike (he walks up if he can)  ·  right-click for more  ·  1-5 abilities  ·  6-9 belt  ·  F careful step  ·  Q stand  ·  B catch breath  ·  %sEnter end turn  ·  R new level" % ("G shut a sluice gate  ·  " if battle.arena.has_area() else "")
	else:
		var spend := progress.points_for(progress.weapon_tree()) + progress.level_points + progress.stat_points
		var how := ("Sneaking" if sneaking else "Walking") + ", lantern " + lantern + ("  ·  T throw a dagger" if progress.owns("daggers", "throw") else "")
		hud.text = "Depth %d  ·  Level %d  ·  XP %d / %d  ·  K skills%s  ·  %s  ·  click to walk, right-click for more  ·  click an enemy to strike from the dark  ·  E search / use  ·  6-9 belt  ·  C sneak  ·  L shutter / light lantern  ·  O put it out  ·  R new life" % [depth, progress.level, progress.xp, progress.xp_needed(), " (points to spend!)" if spend > 0 else "", how]
