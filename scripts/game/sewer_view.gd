extends LevelView
## One registered background texture for the fight test, not a modular tileset renderer.

const BACKDROP = preload("res://assets/tiles/sewers/playable/corridor-backdrop.png")


func _draw() -> void:
	draw_texture(BACKDROP, Vector2.ZERO)
