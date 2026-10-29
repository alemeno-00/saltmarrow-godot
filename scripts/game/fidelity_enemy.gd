class_name FidelityEnemy
extends EnemyView

const MINER = preload("res://assets/tiles/sewers/fidelity-v2/actors/miner.png")
const FAITHFUL = preload("res://assets/tiles/sewers/fidelity-v2/actors/faithful.png")


func _draw_body() -> void:
	var rect := Rect2(-40, -58, 80, 80)
	if facing < 0:
		rect.position.x = 40
		rect.size.x = -80
	draw_texture_rect(MINER if style == "miner" else FAITHFUL, rect, false)
