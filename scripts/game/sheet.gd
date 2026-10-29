class_name Sheet
extends RefCounted
## A character's sprite sheet: one row per animation, frames left to right, all the same size.
## Rows, frame counts and speeds come from the README beside each sheet in assets/.

const FRAME := Vector2(64, 64)
const ROOT := Vector2(32, 56)   # where the feet are in every frame

var texture: Texture2D
var anims := {}   # name -> {row, frames, fps, loop}


func has(name: String) -> bool:
	return anims.has(name)


## Seconds a one-shot animation takes to play through.
func duration(name: String) -> float:
	var a: Dictionary = anims[name]
	return float(a.frames) / float(a.fps)


## The part of the sheet to draw for `name`, `t` seconds in. Non-looping animations hold their last frame.
func frame_rect(name: String, t: float) -> Rect2:
	var a: Dictionary = anims[name]
	var i := int(floor(t * float(a.fps)))
	i = posmod(i, int(a.frames)) if a.loop else mini(i, int(a.frames) - 1)
	return Rect2(Vector2(i * FRAME.x, (int(a.row) - 1) * FRAME.y), FRAME)


func _add(name: String, row: int, frames: int, fps: float, loop := true) -> void:
	anims[name] = {"row": row, "frames": frames, "fps": fps, "loop": loop}


static func _load(path: String) -> Sheet:
	if not ResourceLoader.exists(path):
		return null
	var s := Sheet.new()
	s.texture = load(path)
	return s


## Thomas: assets/characters/thomas/body.png (8 rows).
static func thomas() -> Sheet:
	var s := _load("res://assets/characters/thomas/body.png")
	if s == null:
		return null
	s._add("idle", 1, 4, 4)
	s._add("walk", 2, 6, 8)
	s._add("sneak", 3, 6, 6)
	s._add("hurt", 4, 3, 10, false)
	s._add("wounded_walk", 5, 6, 6)
	s._add("dying_crawl", 6, 6, 5)
	s._add("death", 7, 6, 7, false)
	s._add("careful_step", 8, 4, 8, false)
	s._add("prone", 6, 1, 1, false)   # no lying-down row yet: the first frame of the crawl has him on the ground
	return s


## The Drowned Miner: assets/enemies/drowned_miner/body.png (16 rows).
static func miner() -> Sheet:
	var s := _load("res://assets/enemies/drowned_miner/body.png")
	if s == null:
		return null
	s._add("idle", 1, 4, 4)
	s._add("walk", 2, 6, 6)
	s._add("windup", 3, 3, 6, false)
	s._add("attack", 4, 3, 10, false)
	s._add("hurt", 5, 3, 10, false)
	s._add("pushed_back", 6, 3, 10, false)
	s._add("wall_slam", 7, 3, 10, false)
	s._add("dazed", 8, 4, 4)
	s._add("knocked_prone", 9, 4, 10, false)
	s._add("lying_prone", 10, 2, 4)
	s._add("getting_up", 11, 4, 6, false)
	s._add("limping_walk", 12, 6, 6)
	s._add("flee", 13, 6, 6)
	s._add("death", 14, 6, 6, false)
	s._add("dismembered_death", 15, 6, 6, false)
	s._add("skull_crushed", 16, 6, 6, false)
	return s


## The Faithful: assets/enemies/faithful/body.png (8 rows).
static func faithful() -> Sheet:
	var s := _load("res://assets/enemies/faithful/body.png")
	if s == null:
		return null
	s._add("idle", 1, 4, 4)
	s._add("walk", 2, 6, 6)
	s._add("attack", 3, 4, 10, false)
	s._add("singing", 4, 4, 4)
	s._add("pushed_back", 5, 3, 10, false)
	s._add("knocked_prone", 6, 4, 10, false)
	s._add("death", 7, 6, 6, false)
	s._add("skull_crushed", 8, 6, 6, false)
	return s


static func for_style(style: String) -> Sheet:
	match style:
		"miner":
			return miner()
		"faithful":
			return faithful()
	return null
