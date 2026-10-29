class_name Game
extends Node2D
## Exploring a level with Thomas, and fighting when something sees him.
##
## Exploring: keys or arrows step one square; holding repeats; two keys together step diagonally.
## Clicking a square walks him there along the shortest safe route; any key stops him.
##
## Fighting (Draw Steel turns): click a lit square to move, click an enemy next to you to strike,
## 1-5 for abilities, F (or Shift-click) for a careful step that draws no free strikes, Q to stand, B to catch your breath, Enter to end the turn. R starts a new level.
##
## K opens the skill tree. Stairs lead deeper; Thomas keeps everything he has learned. R starts a new life.
##
## Outside a fight, enemies that are hunting or searching move one square each time Thomas takes a turn.
## An enemy that ran away comes back after a while, with friends.

signal turn_passed(turn: int)

const TILE := 32
const COMBO_WINDOW := 0.035   # how long to wait for a second key so two keys make a diagonal
const REPEAT_DELAY := 0.17    # holding a key: first repeat
const REPEAT_RATE := 0.12     # holding a key: following repeats
const WALK_RATE := 0.11       # click-to-walk: time per square
const SIGHT := Battle.SIGHT   # how far enemies see, in squares
const RETURN_AFTER := 20      # exploring turns before a runaway comes back
const BOTTOM_DEPTH := 3       # the Outflow and Garrick are on this level; beating him wins the run

@export var level_seed: int = 1

var level: Level
var turn := 0
var path: Array[Vector2i] = []

var hero_unit: Combatant
var enemies: Array[Combatant] = []
var views := {}          # Combatant -> ActorView
var battle: Battle = null
var busy := false        # events are playing; input waits
var selected := -1       # the ability chosen, waiting for a target
var stepping := false    # F pressed: the next click is a careful step
var reach := {}          # squares Thomas can move to this turn
var dead := false
var progress: Progress
var depth := 1
var veteran := false     # F9: test as a high-level Thomas
var tree_screen: TreeScreen
var returning: Array = []   # [Combatant, turns left] for enemies that ran and will come back
var tag_cell := Vector2i(-1, -1)   # where Garrick's tally tag lies, once he is dead
var won := false

var _hold_dir := Vector2i.ZERO
var _hold_timer := 0.0
var _hold_started := false
var _pending_timer := -1.0
var _walk_timer := 0.0
var _hover := Vector2i(-1, -1)
var _hover_path: Array[Vector2i] = []
var _shake := 0.0
var _focus = null        # where the camera looks during a crit, or null for Thomas
var _rng := RandomNumberGenerator.new()


func hover_cell() -> Vector2i:
	return _hover


func hover_path() -> Array[Vector2i]:
	return _hover_path

@onready var view: LevelView = $LevelView
@onready var gore: Gore = $Gore
@onready var actors: Node2D = $Actors
@onready var hero: Hero = $Actors/Hero
@onready var cam: Camera2D = $Camera
@onready var hud: Label = $HUD/Info
@onready var combat_hud: CombatHud = $HUD/CombatHud
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	combat_hud.ability_pressed.connect(_on_ability_key)
	combat_hud.stand_pressed.connect(func(): _act(battle.hero_stand()) if _can_act() else null)
	combat_hud.breath_pressed.connect(func(): _act(battle.hero_catch_breath()) if _can_act() else null)
	combat_hud.end_turn_pressed.connect(_end_hero_turn)
	combat_hud.step_pressed.connect(_toggle_step)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	tree_screen = TreeScreen.new()
	layer.add_child(tree_screen)
	tree_screen.changed.connect(_apply_progress)
	new_level(level_seed)


## A fresh level. With `keep`, Thomas goes on down with everything he has; without it, a new life.
func new_level(seed_in: int, keep := false) -> void:
	Engine.time_scale = 1.0
	var next_depth := depth + 1 if keep and hero_unit != null and not dead else 1
	level = Level.new(60, 40)
	level.generate(seed_in, next_depth >= BOTTOM_DEPTH)
	tag_cell = Vector2i(-1, -1)
	won = false
	view.show_level(level)
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
	hero_unit.cell = level.start
	hero.sync(hero_unit)
	gore.clear_all()
	clear_enemies()
	_spawn_enemies()
	battle = null
	busy = false
	dead = false
	selected = -1
	reach = {}
	returning.clear()
	combat_hud.set_abilities(hero_unit.abilities)
	combat_hud.show_fight(false)
	combat_hud.clear_log()
	combat_hud.refresh(hero_unit, null, true)
	cam.position = hero.position
	path.clear()
	turn = 0
	_update_hud()


func clear_enemies() -> void:
	for c in actors.get_children():
		if c != hero:
			c.queue_free()
	enemies.clear()
	views = {hero_unit: hero}


## The first fight: a Drowned Miner and three Faithful, waiting a couple of rooms from the start.
## Groups waiting in every third room, starting two rooms from the start. Deeper levels hold more.
func _spawn_enemies() -> void:
	var group := 0
	if level.outflow.has_area():
		_add_enemy(Bestiary.garrick(), level.outflow.get_center()).group = 1000
	for i in range(2, level.rooms.size(), 3):
		if level.rooms[i] == level.outflow:
			continue
		var c := level.rooms[i].get_center()
		var miner := group % 2 == 0
		var want := 3 if miner else 3 + depth
		if miner:
			_add_enemy(Bestiary.drowned_miner(), c).group = group
		var placed := 0
		for d in [Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(-2, -1), Vector2i(2, -1), Vector2i(1, 2), Vector2i(-1, 2), Vector2i(0, -2), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 0)]:
			if placed >= want:
				break
			var p: Vector2i = c + d
			if level.get_tile(p) == Level.Tile.FLOOR and _enemy_at(p) == null:
				_add_enemy(Bestiary.faithful(), p).group = group
				placed += 1
		group += 1


## After learning something: rebuild Thomas's abilities, passives and stats.
func _apply_progress() -> void:
	var ratio := float(hero_unit.stamina) / float(hero_unit.max_stamina)
	hero_unit.max_stamina = progress.max_stamina()
	hero_unit.stamina = maxi(hero_unit.stamina, roundi(ratio * hero_unit.max_stamina)) if hero_unit.stamina > 0 else hero_unit.stamina
	hero_unit.might = int(progress.stats.might)
	hero_unit.abilities = progress.abilities()
	hero_unit.perks = progress.perks()
	combat_hud.set_abilities(hero_unit.abilities)
	_refresh()


func _add_enemy(u: Combatant, c: Vector2i) -> Combatant:
	u.cell = c
	var v := EnemyView.new()
	v.style = u.style
	actors.add_child(v)
	v.place(c)
	v.facing = -1
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


## The direction the held movement keys point in right now.
func held_direction() -> Vector2i:
	var d := Vector2i.ZERO
	if Input.is_action_pressed("move_left"):
		d.x -= 1
	if Input.is_action_pressed("move_right"):
		d.x += 1
	if Input.is_action_pressed("move_up"):
		d.y -= 1
	if Input.is_action_pressed("move_down"):
		d.y += 1
	return d


## Try to move one square. Returns true if Thomas moved.
## If a diagonal is blocked, he slides along whichever straight direction is open.
## In a fight, a step spends a square of movement.
func try_step(dir: Vector2i) -> bool:
	if dir == Vector2i.ZERO or dead:
		return false
	if in_fight():
		if not _can_act():
			return false
		var ev := battle.hero_step(dir)
		if ev.is_empty() and dir.x != 0 and dir.y != 0:
			ev = battle.hero_step(Vector2i(dir.x, 0))
			if ev.is_empty():
				ev = battle.hero_step(Vector2i(0, dir.y))
		if ev.is_empty():
			return false
		_act(ev)
		return true
	var from := hero.grid_pos
	var chosen := Vector2i.ZERO
	if _open(from, dir):
		chosen = dir
	elif dir.x != 0 and dir.y != 0:
		if _open(from, Vector2i(dir.x, 0)):
			chosen = Vector2i(dir.x, 0)
		elif _open(from, Vector2i(0, dir.y)):
			chosen = Vector2i(0, dir.y)
	if chosen == Vector2i.ZERO:
		return false
	var to := from + chosen
	if level.get_tile(to) == Level.Tile.DOOR_CLOSED:
		level.set_tile(to, Level.Tile.DOOR_OPEN)
		view.queue_redraw()
	hero.move_to(to)
	hero_unit.cell = to
	_end_turn()
	if level.get_tile(to) == Level.Tile.STAIRS and not in_fight():
		_descend()
	elif to == tag_cell and not in_fight():
		_win()
	return true


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
	new_level(level.seed_value + 1, true)
	combat_hud.show_banner("Deeper.   Depth %d" % depth, 2.0)


func _open(from: Vector2i, dir: Vector2i) -> bool:
	return level.can_step(from, dir) and _enemy_at(from + dir) == null


func wait_turn() -> void:
	_end_turn()


## Start walking to a square along the shortest route. Returns false if it can't be reached.
func walk_to(target: Vector2i) -> bool:
	var p := level.find_path(hero.grid_pos, target)
	if p.is_empty():
		return false
	path = p
	_walk_timer = 0.0
	return true


func stop_walking() -> void:
	path.clear()


func _end_turn() -> void:
	turn += 1
	turn_passed.emit(turn)
	_enemies_explore()
	_update_hud()
	_check_spotted()


## Outside a fight: hunters close in on Thomas, searchers go to where they last saw him, runaways come back.
func _enemies_explore() -> void:
	if in_fight() or dead:
		return
	for e in enemies:
		if not e.alive() or e.state == "idle":
			continue
		var goal := hero.grid_pos if e.state == "hunting" else e.target
		var p := level.find_path(e.cell, goal)
		if not p.is_empty() and p[0] != hero.grid_pos and _enemy_at(p[0]) == null:
			e.cell = p[0]
			views[e].move_to(p[0])
		if e.state == "searching" and e.cell == e.target:
			e.state = "idle"
	for r in returning.duplicate():
		r[1] -= 1
		if r[1] <= 0:
			returning.erase(r)
			_bring_back(r[0])


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


## Something with a line of sight to Thomas, close enough, starts a fight.
func _check_spotted() -> void:
	if in_fight() or dead:
		return
	for e in enemies:
		if e.alive() and Battle.dist(e.cell, hero.grid_pos) <= SIGHT and level.line_of_sight(e.cell, hero.grid_pos):
			_start_battle()
			return


func _start_battle() -> void:
	stop_walking()
	hero_unit.cell = hero.grid_pos
	# whoever saw him, their band, and anything already hunting him, fight; the rest may join if they see him
	var bands := {}
	for e in enemies:
		if e.alive() and (e.state != "idle" or (Battle.dist(e.cell, hero.grid_pos) <= SIGHT and level.line_of_sight(e.cell, hero.grid_pos))):
			bands[e.group] = true
	var fighting: Array = []
	var others: Array[Combatant] = []
	for e in enemies:
		if not e.alive():
			continue
		if bands.has(e.group) or e.state != "idle":
			fighting.append(e)
		else:
			others.append(e)
	battle = Battle.new()
	battle.setup(level, hero_unit, fighting, level.seed_value * 7919 + turn)
	battle.bystanders = others
	if level.outflow.has_area() and fighting.any(func(u): return u.kind == "solo"):
		battle.arena = level.outflow
	combat_hud.clear_log()
	combat_hud.show_fight(true)
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
	if tree_screen.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		new_level(level.seed_value + 1)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		veteran = not veteran
		new_level(level.seed_value + 1)
		combat_hud.show_banner("Test: a level 10 veteran with every mace skill." if veteran else "Back to a fresh Thomas.", 2.5)
		return
	if dead or won:
		return
	if in_fight() and _combat_input(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		stop_walking()
		# wait a moment for a second key, so pressing two together moves diagonally
		if _pending_timer < 0.0 and not _hold_started:
			_pending_timer = COMBO_WINDOW
		get_viewport().set_input_as_handled()
	elif in_fight():
		pass
	elif event.is_action_pressed("wait"):
		stop_walking()
		wait_turn()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := mouse_cell()
		if c == hero.grid_pos:
			wait_turn()
		else:
			walk_to(c)
	_zoom_input(event)


func _zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var z := cam.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		z = clampf(z, 1.0, 4.0)
		cam.zoom = Vector2(z, z)


## Fight controls. Returns true if the event was used.
func _combat_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_9:
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
			_select(-1)
			return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.shift_pressed:
				stepping = true
			_combat_click(mouse_cell())
			return true
	return false


func _combat_click(c: Vector2i) -> void:
	if not _can_act():
		return
	if stepping:
		stepping = false
		combat_hud.set_stepping(false)
		_act(battle.hero_shift(c))
		return
	if selected >= 0:
		var i := selected
		_select(-1)
		_act(battle.hero_ability(i, c))
		return
	var e := _enemy_at(c)
	if level.gates.has(c):
		_act(battle.hero_shut_gate(c))
	elif e != null and Battle.adjacent(e.cell, hero_unit.cell):
		_act(battle.hero_ability(0, c))   # clicking an enemy next to you is a basic attack
	elif reach.has(c):
		_act(battle.hero_move_to(c))


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
		_act(battle.hero_ability(i, targets[0].cell if targets.size() > 0 else hero_unit.cell))
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
	if not stepping and battle.shift_cells().is_empty():
		combat_hud.add_log("No maneuver left for a careful step." if battle.budget.maneuver <= 0 else "Nowhere to step.")
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
	reach = {}
	_refresh()
	for e in events:
		await _play_one(e)
	busy = false
	if in_fight() and battle.is_hero_turn():
		reach = battle.reachable(hero_unit, battle.budget.move)
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
			var tree_id: String = {"mace": "maces"}.get(e.weapon, "")
			var got := progress.add_hit(tree_id)
			if got == "point":
				combat_hud.show_banner("A mace mastery point.   K to spend it after the fight.", 1.6)
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
			v.move_to(e.to)
			await _wait(ActorView.STEP_TIME + 0.03)
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
			var t = e.target
			if t != null:
				views[e.unit].lunge_at(t.cell, 9.0)
				await _wait(0.07)
		"roll":
			if e.unit == hero_unit:
				hero.play_attack(e.ability.id, e.roll.crit)
			combat_hud.dice.show_roll(e.roll, e.unit.name, e.ability.name)
			await _wait(0.75 if e.roll.crit else 0.5)
		"hit":
			await _play_hit(e)
		"push":
			var v: ActorView = views[e.unit]
			v.play_once("pushed_back")
			for c in e.path:
				var from := v.position
				v.move_to(c, 0.07)
				if e.unit.stamina < e.unit.max_stamina * 0.6:
					gore.smear(from, ActorView.cell_to_px(c))
				await _wait(0.08)
		"slam":
			_shake = 7.0
			views[e.unit].play_once("wall_slam")
			OneShot.spawn(self, "res://assets/effects/mace/wall_slam.png", (ActorView.cell_to_px(e.unit.cell) + ActorView.cell_to_px(e.cell)) / 2.0, 10.0, e.cell.x < e.unit.cell.x)
			gore.splash(ActorView.cell_to_px(e.unit.cell), Vector2(e.cell - e.unit.cell), 2.0)
			await _hitstop(0.08)
		"prone", "stand", "status", "heal":
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
			views[e.unit].lunge_at(e.cells[0], 12.0)
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
	OneShot.spawn(self, "res://assets/effects/hits/tier_3.png" if e.tier >= 3 else "res://assets/effects/hits/crushing.png", v.position + Vector2(0, -10), 12.0)
	var dmg: int = e.dmg
	var away := Vector2.ZERO
	if battle != null and battle.active != null and battle.active != u:
		away = (v.position - views[battle.active].position).normalized()
	gore.splash(v.position, away, 1.0 + dmg * 0.4)
	if e.crit:
		await _crit_moment(v, dmg)
	else:
		_shake = maxf(_shake, 2.0 + dmg * 0.5)
		await _hitstop(0.04 + dmg * 0.006)
	v.sync(u)
	_refresh()


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
			returning.append([u, RETURN_AFTER])
	if winner == "escaped":
		combat_hud.show_banner("You've lost them, for now.", 2.0)
		for u in battle.units:
			if u.alive() and u != hero_unit:
				u.state = "searching"
				u.target = battle.last_seen
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
		if hero_unit.stamina <= 0:
			hero_unit.stamina = 1
			hero_unit.dying = false
		hero.sync(hero_unit)
		hero.place(hero_unit.cell)
		battle = null
		overlay.queue_redraw()
	else:
		dead = true
		combat_hud.show_banner("Thomas Wren is dead.   Press R to wake again.", 99999.0)
	_refresh()


# ---------------------------------------------------------------- every frame

func _process(delta: float) -> void:
	if not tree_screen.visible:
		_tick_input(delta)
	_tick_walk(delta)
	var target: Vector2 = _focus if _focus != null else hero.position
	cam.position = cam.position.lerp(target, 1.0 - exp(-delta * 12.0))
	if _shake > 0.05:
		cam.offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake
		_shake = lerpf(_shake, 0.0, 1.0 - exp(-delta * 14.0))
	else:
		cam.offset = Vector2.ZERO
	_tick_hover()
	if in_fight() or tag_cell.x >= 0:
		overlay.queue_redraw()


## Keyboard movement: a short wait for diagonals, one step, then repeats while held.
func _tick_input(delta: float) -> void:
	var d := held_direction()
	if d == Vector2i.ZERO:
		_hold_dir = Vector2i.ZERO
		_hold_started = false
		_pending_timer = -1.0
		return
	if _pending_timer >= 0.0:
		_pending_timer -= delta
		if _pending_timer < 0.0:
			try_step(d)
			_hold_dir = d
			_hold_started = true
			_hold_timer = REPEAT_DELAY
		return
	if not _hold_started:
		return
	if d != _hold_dir:
		# changed direction while holding: step now in the new direction
		_hold_dir = d
		try_step(d)
		_hold_timer = REPEAT_DELAY
		return
	_hold_timer -= delta
	if _hold_timer <= 0.0:
		try_step(d)
		_hold_timer += REPEAT_RATE


func _tick_walk(delta: float) -> void:
	if path.is_empty() or in_fight():
		return
	_walk_timer -= delta
	if _walk_timer > 0.0:
		return
	var next: Vector2i = path[0]
	var dir := next - hero.grid_pos
	if not _open(hero.grid_pos, dir):
		# something is in the way now; try to route again once
		var target: Vector2i = path[path.size() - 1]
		if not walk_to(target):
			path.clear()
		elif not path.is_empty() and not _open(hero.grid_pos, path[0] - hero.grid_pos):
			path.clear()
		return
	path.remove_at(0)
	try_step(dir)
	_walk_timer = WALK_RATE


func _tick_hover() -> void:
	var c := mouse_cell()
	if c == _hover:
		return
	_hover = c
	if in_fight():
		_hover_path = []
	else:
		_hover_path = level.find_path(hero.grid_pos, c) if level.in_bounds(c) else ([] as Array[Vector2i])
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
		hud.text = "Click a lit square to move  ·  click an enemy beside you to strike  ·  1-5 abilities  ·  F careful step  ·  Q stand  ·  B catch breath  ·  %sEnter end turn  ·  R new level" % ("G shut a sluice gate  ·  " if battle.arena.has_area() else "")
	else:
		var spend := progress.points_for("maces") + progress.level_points + progress.stat_points
		hud.text = "Depth %d  ·  Level %d  ·  XP %d / %d  ·  K skills%s  ·  WASD / arrows to move, click to walk, Space to wait, wheel to zoom, R new life, F9 test as a veteran" % [depth, progress.level, progress.xp, progress.xp_needed(), " (points to spend!)" if spend > 0 else "", ]
