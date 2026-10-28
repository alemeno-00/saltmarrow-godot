extends Hero

const BODY = preload("res://assets/tiles/sewers/fidelity-v2/actors/thomas.png")


func _draw_body() -> void:
	# Enlarge visible body 48 -> 60px while keeping the feet at local (0,12).
	var rect := Rect2(-40, -58, 80, 80)
	if facing < 0:
		rect.position.x = 40
		rect.size.x = -80
	draw_texture_rect(BODY, rect, false)
