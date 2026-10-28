class_name Game
extends Node2D
## Exploration: walking Thomas around a level.
## Keys or arrows step one square; holding repeats; two keys together step diagonally.
## Clicking a square walks him there along the shortest safe route; any key stops him.

signal turn_passed(turn: int)

const TILE := 32
const COMBO_WINDOW := 0.035   # how long to wait for a second key so two keys make a diagonal
const REPEAT_DELAY := 0.17    # holding a key: first repeat
const REPEAT_RATE := 0.12     # holding a key: following repeats
const WALK_RATE := 0.11       # click-to-walk: time per square

@export var level_seed: int = 1

var level: Level
var turn := 0
var path: Array[Vector2i] = []

var _hold_dir := Vector2i.ZERO
var _hold_timer := 0.0
var _hold_started := false
var _pending_timer := -1.0
var _walk_timer := 0.0
var _hover := Vector2i(-1, -1)
var _hover_path: Array[Vector2i] = []


func hover_cell() -> Vector2i:
	return _hover


func hover_path() -> Array[Vector2i]:
	return _hover_path

@onready var view: LevelView = $LevelView
@onready var hero: Hero = $Hero
@onready var cam: Camera2D = $Camera
@onready var hud: Label = $HUD/Info
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	new_level(level_seed)


func new_level(seed_in: int) -> void:
	level = Level.new(60, 40)
	level.generate(seed_in)
	view.show_level(level)
	hero.place(level.start)
	cam.position = hero.position
	path.clear()
	turn = 0
	_update_hud()


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
func try_step(dir: Vector2i) -> bool:
	if dir == Vector2i.ZERO:
		return false
	var from := hero.grid_pos
	var chosen := Vector2i.ZERO
	if level.can_step(from, dir):
		chosen = dir
	elif dir.x != 0 and dir.y != 0:
		if level.can_step(from, Vector2i(dir.x, 0)):
			chosen = Vector2i(dir.x, 0)
		elif level.can_step(from, Vector2i(0, dir.y)):
			chosen = Vector2i(0, dir.y)
	if chosen == Vector2i.ZERO:
		return false
	var to := from + chosen
	if level.get_tile(to) == Level.Tile.DOOR_CLOSED:
		level.set_tile(to, Level.Tile.DOOR_OPEN)
		view.queue_redraw()
	hero.move_to(to)
	_end_turn()
	return true


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
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		stop_walking()
		# wait a moment for a second key, so pressing two together moves diagonally
		if _pending_timer < 0.0 and not _hold_started:
			_pending_timer = COMBO_WINDOW
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("wait"):
		stop_walking()
		wait_turn()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := mouse_cell()
		if c == hero.grid_pos:
			wait_turn()
		else:
			walk_to(c)
	elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var z := cam.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		z = clampf(z, 1.0, 4.0)
		cam.zoom = Vector2(z, z)


func mouse_cell() -> Vector2i:
	var p := get_global_mouse_position()
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


func _process(delta: float) -> void:
	_tick_input(delta)
	_tick_walk(delta)
	cam.position = cam.position.lerp(hero.position, 1.0 - exp(-delta * 12.0))
	_tick_hover()


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
	if path.is_empty():
		return
	_walk_timer -= delta
	if _walk_timer > 0.0:
		return
	var next: Vector2i = path[0]
	var dir := next - hero.grid_pos
	if not level.can_step(hero.grid_pos, dir):
		# something is in the way now; try to route again once
		var target: Vector2i = path[path.size() - 1]
		if not walk_to(target):
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
	_hover_path = level.find_path(hero.grid_pos, c) if level.in_bounds(c) else ([] as Array[Vector2i])
	overlay.queue_redraw()


func _update_hud() -> void:
	if hud:
		hud.text = "Turn %d   ·   square %d, %d   ·   WASD / arrows to move (two keys for diagonals), click to walk, Space to wait, wheel to zoom" % [turn, hero.grid_pos.x, hero.grid_pos.y]
