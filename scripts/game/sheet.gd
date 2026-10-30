class_name Sheet
extends RefCounted
## A character's sprite sheet: one row per animation, frames left to right, all the same size.
## Rows, frame counts and speeds come from the README beside each sheet in assets/.

const FRAME := Vector2(64, 64)
const ROOT := Vector2(32, 56)   # where the feet are in every frame
## Directional sheets (art job 15 on): 80 x 80 frames, feet at (40, 72), one sheet per drawn direction. The game
## mirrors SE, E and NE to get SW, W and NW.
const DIR_FRAME := Vector2(80, 80)
const DIR_ROOT := Vector2(40, 72)
const DIRECTIONS := ["s", "se", "e", "ne", "n"]

var texture: Texture2D
var frame := FRAME   # this sheet's frame size
var root := ROOT     # where the feet are in this sheet's frames
var anims := {}   # name -> {row, frames, fps, loop, tex (optional: a second sheet, e.g. Thomas's attacks)}


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
	return Rect2(Vector2(i * frame.x, (int(a.row) - 1) * frame.y), frame)


## The image an animation's frames come from.
func texture_of(name: String) -> Texture2D:
	return anims[name].get("tex", texture)


func _add(name: String, row: int, frames: int, fps: float, loop := true, tex: Texture2D = null) -> void:
	anims[name] = {"row": row, "frames": frames, "fps": fps, "loop": loop}
	if tex != null:
		anims[name].tex = tex


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
	# the mace sheets hold the whole of Thomas with the maul: they replace the body during a blow
	var attack := "res://assets/characters/thomas/attack_mace.png"
	if ResourceLoader.exists(attack):
		var t: Texture2D = load(attack)
		s._add("mace_windup", 1, 3, 6, false, t)
		s._add("mace_strike", 2, 3, 12, false, t)
		s._add("mace_recovery", 3, 3, 7, false, t)
		s._add("mace_crit", 4, 8, 6, false, t)
	var abilities := "res://assets/characters/thomas/mace_abilities.png"
	if ResourceLoader.exists(abilities):
		var t: Texture2D = load(abilities)
		s._add("skull_crack", 1, 8, 12, false, t)
		s._add("knee_breaker", 2, 8, 12, false, t)
		s._add("shatter", 3, 9, 12, false, t)
		s._add("wide_arc", 4, 10, 12, false, t)
		s._add("execution", 5, 12, 10, false, t)
	return s


## A character's directional sheets in `folder` (`s.png`, `se.png`, `e.png`, `ne.png`, `n.png`), as direction ->
## Sheet, for the directions delivered so far. Rows in every sheet (`design/art-briefs/animation/BRIEF.md`): idle 6,
## walk 8, wounded walk 8, sneak 8, careful step 4.
static func directions(folder: String) -> Dictionary:
	var out := {}
	for d in DIRECTIONS:
		var s := _load(folder + d + ".png")
		if s == null:
			continue
		s.frame = DIR_FRAME
		s.root = DIR_ROOT
		s._add("idle", 1, 6, 6)
		s._add("walk", 2, 8, 10)
		s._add("wounded_walk", 3, 8, 8)
		s._add("sneak", 4, 8, 7)
		s._add("careful_step", 5, 4, 8, false)
		out[d] = s
	return out


## Thomas in five directions: assets/characters/thomas/dir/ (art job 15). Empty until it arrives.
static func thomas_dirs() -> Dictionary:
	return directions("res://assets/characters/thomas/dir/")


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
