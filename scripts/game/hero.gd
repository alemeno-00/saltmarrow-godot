class_name Hero
extends ActorView
## Thomas on the map: ChatGPT's animated body sheet (assets/characters/thomas/body.png), facing right and
## mirrored to face left. Falls back to a drawn placeholder if the sheet is missing.


func _ready() -> void:
	sheet = Sheet.thomas()


func _draw_body() -> void:
	_draw_placeholder()


## Swing the maul: the basic blow as wind-up, strike and recovery; a critical one as the big overhead;
## a mace ability as its own row.
func play_attack(ability_id: String, crit: bool) -> void:
	if ability_id == "heavy_blow":
		if crit:
			play_sequence(["mace_crit"] as Array[String])
		else:
			play_sequence(["mace_windup", "mace_strike", "mace_recovery"] as Array[String])
	else:
		play_sequence([ability_id] as Array[String])


func _sheet_tint() -> Color:
	return _tint()


func _tint() -> Color:
	if dying:
		return Color(0.75, 0.72, 0.72)
	return Color.WHITE


func _draw_placeholder() -> void:
	var f := float(facing)
	# legs
	draw_rect(Rect2(-4, 4, 3, 8), Color("2a2622"))
	draw_rect(Rect2(1, 4, 3, 8), Color("2a2622"))
	# greatcoat
	draw_rect(Rect2(-6, -6, 12, 13), Color("3a3f3a"))
	draw_rect(Rect2(-6, -6, 2, 13), Color("2c302c"))
	# Ellen's scarf
	draw_rect(Rect2(-5, -7, 10, 3), Color("a8322a"))
	draw_rect(Rect2(-5 - 2 * f if f < 0 else 3, -5, 2, 5), Color("8a2a22"))
	# head
	if crushed:
		draw_rect(Rect2(-4, -10, 8, 3), Color("5a0a0c"))
	else:
		draw_rect(Rect2(-4, -14, 8, 7), Color("c89a7a").lerp(Color("8f8a86"), 0.6 if dying else 0.0))
		draw_rect(Rect2(-4, -15, 8, 2), Color("3a2a1e"))
		draw_rect(Rect2(1 * f if f > 0 else -3, -11, 2, 1), Color("1a1410"))
	# the maul
	var wood := Color("5a4630")
	var iron := Color("6e6a66")
	if raised:
		draw_line(Vector2(2 * f, -4), Vector2(4 * f, -22), wood, 2.0)
		draw_rect(Rect2(Vector2(4 * f - 4, -27), Vector2(8, 6)), iron)
	else:
		draw_line(Vector2(5 * f, 0), Vector2(13 * f, -10), wood, 2.0)
		draw_rect(Rect2(Vector2(13 * f - 3, -15), Vector2(7, 6)), iron)
	# lantern at the hip
	draw_rect(Rect2(-8 * f - (2 if f > 0 else 0), 0, 3, 4), Color("ffcf6a"))
