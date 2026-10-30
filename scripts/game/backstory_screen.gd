class_name BackstoryScreen
extends Control
## The start of each life: who Thomas was before he came to Saltmarrow (docs/story.md, Backstories). The choice is a
## head start: his weapon, his skill tree, how he earns extra Resolve. 1 or 2, or click.
## Decided by Julian, 2026-10-30 (design/quick-specs/sneaking-2026-10-30.md).

signal chosen(backstory: String)

const INK := Color(0.9, 0.85, 0.75)
const DIM := Color(0.6, 0.57, 0.52)
const AMBER := Color(1.0, 0.8, 0.45)
const CHOICES := [
	["fury", "Fury", "The war never left him. He swings a maul and fights angry: every wound drives him on.\n\nMaces (Might)  ·  extra Resolve when he is hurt  ·  starts with Skull Crack and Weight Behind It."],
	["shadow", "Shadow", "He learned to kill quietly, in the dark, before anyone knew he was there.\n\nDaggers (Agility)  ·  extra Resolve when he strikes an enemy that can't see him  ·  starts with Backstab and Twin Fangs. Best with sneaking: C to crouch, O to put the lantern out."],
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var title := _label(Vector2(0, 120), 26, INK)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "A new life. Who was Thomas, before Saltmarrow?"
	for i in CHOICES.size():
		var c: Array = CHOICES[i]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(170 + i * 480, 210)
		b.size = Vector2(440, 300)
		b.add_theme_font_size_override("font_size", 15)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%d   %s\n\n%s" % [i + 1, c[1], c[2]]
		b.pressed.connect(func(): choose(c[0]))
		add_child(b)


func _label(pos: Vector2, font: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", font)
	add_child(l)
	return l


func open() -> void:
	visible = true


func choose(backstory: String) -> void:
	visible = false
	chosen.emit(backstory)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var i: int = event.keycode - KEY_1
		if i >= 0 and i < CHOICES.size():
			choose(CHOICES[i][0])
			get_viewport().set_input_as_handled()
