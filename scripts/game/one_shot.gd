class_name OneShot
extends Node2D
## An effect strip played once where something happened, then gone: hit flashes, wall slams.
## Strips are one row of square frames, pivot at the frame centre (assets/effects/*/README.md).

var texture: Texture2D
var frame := 64.0
var frames := 4
var fps := 12.0
var flip := false
var _t := 0.0


## Plays `path` at `at` (pixels) under `parent`. Does nothing if the strip isn't there.
static func spawn(parent: Node, path: String, at: Vector2, fps_in := 12.0, flip_in := false) -> void:
	if not ResourceLoader.exists(path):
		return
	var e := OneShot.new()
	e.texture = load(path)
	e.frame = float(e.texture.get_height())
	e.frames = int(e.texture.get_width() / e.frame)
	e.fps = fps_in
	e.flip = flip_in
	e.position = at
	parent.add_child(e)


func _process(delta: float) -> void:
	# real time, so hitstop and slow motion don't freeze the effect
	_t += delta / maxf(Engine.time_scale, 0.05)
	if _t * fps >= frames:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var i := mini(int(_t * fps), frames - 1)
	var src := Rect2(i * frame, 0, frame, frame)
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(texture, Rect2(Vector2(-frame / 2.0, -frame / 2.0), Vector2(frame, frame)), src)
