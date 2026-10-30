class_name Fog
extends RefCounted
## Fog of war: what Thomas has explored, and what he can see right now. Squares he has never seen are black;
## squares he has seen but can't see now are remembered, dimmed, with no creatures shown in them; only what is in
## his line of sight is lit and shows who is there.
##
## Sight is a straight line within SIGHT squares, stopped by whatever blocks sight (walls, closed doors, gates,
## props). The wall that stops a line is itself seen, so rooms show their edges.

const SIGHT := 10        # squares (15 m)

var width := 0
var height := 0
var explored := PackedByteArray()
var seen := PackedByteArray()      # in sight now
var _from := Vector2i(-9999, -9999)


func _init(w := 0, h := 0) -> void:
	width = w
	height = h
	explored.resize(w * h)
	seen.resize(w * h)


## Work out what can be seen from `from`. Cheap to call every frame: it only recomputes when `from` changed or
## `force` is set (a door opened, say). Returns whether it was worked out again.
func update(level: Level, from: Vector2i, force := false) -> bool:
	if from == _from and not force:
		return false
	_from = from
	seen.fill(0)
	for y in range(maxi(0, from.y - SIGHT), mini(height, from.y + SIGHT + 1)):
		for x in range(maxi(0, from.x - SIGHT), mini(width, from.x + SIGHT + 1)):
			var c := Vector2i(x, y)
			if (c - from).length_squared() <= SIGHT * SIGHT and level.line_of_sight(from, c):
				seen[y * width + x] = 1
				explored[y * width + x] = 1
	return true


## Is `c` in sight now?
func sees(c: Vector2i) -> bool:
	return _inside(c) and seen[c.y * width + c.x] == 1


## Has `c` ever been seen?
func knows(c: Vector2i) -> bool:
	return _inside(c) and explored[c.y * width + c.x] == 1


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height
