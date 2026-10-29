class_name EnemyView
extends ActorView
## An enemy on the map. Placeholder drawings for the Drowned Miner and the Faithful.

var style := "miner"


func _draw_body() -> void:
	match style:
		"miner":
			_miner()
		"faithful":
			_faithful()
		"garrick":
			_garrick()


## Garrick, the First Shift: a huge Drowned foreman with a pick and a length of lift chain.
func _garrick() -> void:
	var f := float(facing)
	var coat := Color("2c3a3c")
	var salt := Color("d8d6cc")
	# legs, wide-set
	draw_rect(Rect2(-8, 6, 6, 10), Color("1f2224"))
	draw_rect(Rect2(2, 6, 6, 10), Color("1f2224"))
	# broad stooped body in a rotted foreman's coat, salt-crusted
	draw_rect(Rect2(-11, -12, 22, 20), coat)
	draw_rect(Rect2(-11, -12, 22, 3), Color("566c6e"))
	draw_rect(Rect2(-11, 5, 4, 3), salt)
	draw_rect(Rect2(7, -6, 4, 3), salt)
	draw_rect(Rect2(-3, -2, 3, 2), salt)
	# the brass tally tag at his neck
	draw_rect(Rect2(-1, -9, 3, 3), Color("b88c40"))
	# head sunk between the shoulders, pearl eyes
	if crushed:
		draw_rect(Rect2(-5 + 2 * f, -16, 10, 4), Color("5a0a0c"))
	else:
		draw_rect(Rect2(-5 + 2 * f, -21, 10, 9), Color("7f8e89"))
		draw_rect(Rect2(-5 + 2 * f, -22, 10, 2), Color("33291f"))
		draw_rect(Rect2(2 * f + (2 if f > 0 else -3), -18, 2, 1), Color("eef4ff"))
		draw_rect(Rect2(-1 * f + (0 if f > 0 else -1), -18, 2, 1), Color("eef4ff"))
	# the lift chain: wrapped round the back arm, swung high when winding up
	var iron := Color("6f6c66")
	var links: Array[Vector2] = []
	if raised:
		for i in 7:
			links.append(Vector2(-f * (6 + i * 3), -14 - sin(i * 0.5) * 12))
	else:
		for i in 7:
			links.append(Vector2(-f * (8 + i * 2), 2 + i * 2))
	for p in links:
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), iron)
	# the pick in the front hand
	var wood := Color("5a4630")
	draw_line(Vector2(9 * f, -4), Vector2(16 * f, -14), wood, 2.0)
	draw_line(Vector2(13 * f, -18), Vector2(19 * f, -9), Color("8c8c88"), 2.0)


func _miner() -> void:
	var f := float(facing)
	var cloth := Color("344245")
	draw_rect(Rect2(-5, 4, 4, 8), Color("26282a"))
	draw_rect(Rect2(1, 4, 4, 8), Color("26282a"))
	# hunched oilskin, wet and salt-crusted
	draw_rect(Rect2(-7, -6, 14, 12), cloth)
	draw_rect(Rect2(-7, -6, 14, 2), Color("5f7476"))
	draw_rect(Rect2(-7, 4, 3, 2), Color("d8d6cc"))
	draw_rect(Rect2(4, -2, 3, 2), Color("d8d6cc"))
	draw_rect(Rect2(-2, 1, 2, 2), Color("d8d6cc"))
	# head hung low, pearly eyes
	if crushed:
		draw_rect(Rect2(-4 + 2 * f, -9, 8, 3), Color("5a0a0c"))
	else:
		draw_rect(Rect2(-4 + 2 * f, -12, 8, 7), Color("8a9893"))
		draw_rect(Rect2(-4 + 2 * f, -13, 8, 2), Color("3d3226"))
		draw_rect(Rect2(1 * f + 2 * f if f > 0 else -2, -9, 2, 1), Color("eef4ff"))
	# the pick
	var wood := Color("5a4630")
	var iron := Color("8c8c88")
	if raised:
		draw_line(Vector2(0, -4), Vector2(2 * f, -26), wood, 2.0)
		draw_line(Vector2(-5 * f, -27), Vector2(9 * f, -24), iron, 2.0)
	else:
		draw_line(Vector2(3 * f, -1), Vector2(12 * f, -9), wood, 2.0)
		draw_line(Vector2(9 * f, -13), Vector2(14 * f, -4), iron, 2.0)


func _faithful() -> void:
	var f := float(facing)
	var skin := Color("d2bfae")
	draw_rect(Rect2(-3, 5, 2, 7), skin)
	draw_rect(Rect2(1, 5, 2, 7), skin)
	# white chapel smock, salt at the hem
	draw_rect(Rect2(-5, -6, 10, 12), Color("d9d4c8"))
	draw_rect(Rect2(-5, 4, 10, 2), Color("eae8e0"))
	draw_rect(Rect2(-1, -4, 2, 2), Color("101014"))
	# reaching arms
	draw_line(Vector2(4 * f, -3), Vector2(10 * f, -1), skin, 2.0)
	if crushed:
		draw_rect(Rect2(-3, -9, 6, 3), Color("5a0a0c"))
	else:
		draw_rect(Rect2(-3, -13, 6, 7), skin)
		draw_rect(Rect2(-3, -14, 6, 2), Color("2a2420"))
		draw_rect(Rect2(1 * f if f > 0 else -2, -11, 1, 1), Color("eef4ff"))
		draw_rect(Rect2(-1 if f > 0 else -1, -8, 3, 1), Color("7a4a40"))
