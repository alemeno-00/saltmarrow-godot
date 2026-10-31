class_name LoreDrop
extends Node2D
## Something to read on the floor (room contents part 2): a letter, a chapel paper, or a dead miner with his tally
## tag. Drawn stand-ins until art job 14c arrives. A paper already in the journal is drawn a little faded.

var kind := ""     # letter, chapel, tag
var read := false
var _t := 0.0


static func spawn(parent: Node, c: Vector2i, kind_in: String) -> LoreDrop:
	var d := LoreDrop.new()
	d.kind = kind_in
	d.position = MovementRules.centre(c)
	parent.add_child(d)
	return d


func _process(delta: float) -> void:
	_t += delta
	if kind == "tag":
		queue_redraw()   # the brass catches the light now and then


func _draw() -> void:
	var a := 0.6 if read and kind != "tag" else 1.0
	match kind:
		"letter":
			draw_rect(Rect2(-5, 2, 10, 7), Color(0.78, 0.74, 0.64, a))
			draw_rect(Rect2(-5, 2, 10, 7), Color(0.45, 0.4, 0.33, a), false, 1.0)
			draw_line(Vector2(-3, 4), Vector2(3, 4), Color(0.35, 0.3, 0.26, a))
			draw_line(Vector2(-3, 6), Vector2(2, 6), Color(0.35, 0.3, 0.26, a))
		"chapel":
			draw_rect(Rect2(-4, 0, 9, 11), Color(0.72, 0.7, 0.62, a))
			draw_rect(Rect2(-4, 0, 9, 11), Color(0.42, 0.4, 0.34, a), false, 1.0)
			for i in 4:
				draw_line(Vector2(-2, 2 + i * 2), Vector2(3, 2 + i * 2), Color(0.32, 0.3, 0.27, a))
		"tag":
			# a man lying on his side: legs, body, head, and a glint of brass at his chest
			var body := Color(0.2, 0.21, 0.23)
			draw_rect(Rect2(-13, 3, 9, 4), body.darkened(0.15))
			draw_rect(Rect2(-5, 1, 12, 7), body)
			draw_circle(Vector2(10, 4), 3.5, Color(0.55, 0.56, 0.58))
			draw_rect(Rect2(-4, 1, 3, 2), Color(0.85, 0.88, 0.92, 0.8))   # salt on his shoulder
			var glint := 0.55 + 0.45 * maxf(0.0, sin(_t * 1.7))
			draw_rect(Rect2(2, 3, 2, 2), Color(0.85, 0.66, 0.3, glint))
