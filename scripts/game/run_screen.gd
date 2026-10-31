class_name RunScreen
extends Control
## The start and end of a run (design/game-brief.md, MVP item 7; build order step 4): the title when the game opens,
## the death screen, and the win once Garrick's tally tag is in Thomas's hand. Mouse first: every choice is a button;
## R (wake again) and J (the journal) still work.
## - `open_title(found)`: Saltmarrow Deep, and Wake / Journal / Quit.
## - `open_dead(stats)` and `open_won(stats)`: what happened this life, what carries over, and Wake again / Journal.
##   `stats`: {cause, depth, level, kills, found_now, found_all}.

signal wake
signal journal
signal quit

const INK := Color(0.9, 0.85, 0.75)
const DIM := Color(0.6, 0.57, 0.52)
const AMBER := Color(1.0, 0.8, 0.45)
const PEARL := Color(0.82, 0.86, 0.9)

var mode := ""        # "title", "dead" or "won" while open
var _dim: ColorRect
var _backdrop: TextureRect      # the title's painting of Saltmarrow (ART_JOBS 20), once it arrives
var _logo: TextureRect          # the carved title, once it arrives
var _rain: Rain                  # rain over the title's painting
var _bands: Array[ColorRect] = []  # dark bands behind the title and the buttons, so they read over the painting
var _flash := 0.0                # a distant lightning flash fading
var _next_flash := 9.0
const BACKDROP := "res://assets/ui/title_background.png"
const SEA_MASK := "res://assets/ui/title_background_sea.png"   # red: open sea; green: surf (ART_JOBS 20)
const LOGO := "res://assets/ui/title.png"
var _title: Label
var _sub: Label
var _body: Label
var _buttons: Array[Button] = []
var _fade := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_dim = ColorRect.new()
	_dim.size = Vector2(1280, 720)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_backdrop = TextureRect.new()
	_backdrop.size = Vector2(1280, 720)
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_rain = Rain.new()
	add_child(_rain)
	for r in [Rect2(0, 140, 1280, 112), Rect2(0, 506, 1280, 68)]:
		var band := ColorRect.new()
		band.color = Color(0.02, 0.03, 0.05, 0.62)
		band.position = r.position
		band.size = r.size
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.visible = false
		add_child(band)
		_bands.append(band)
	_logo = TextureRect.new()
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)
	set_title_art(UiStyle.tex(BACKDROP), UiStyle.tex(SEA_MASK), UiStyle.tex(LOGO))
	_title = _label(Vector2(0, 150), 44, INK)
	_sub = _label(Vector2(0, 214), 17, DIM)
	_body = _label(Vector2(0, 268), 16, INK)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.position.x = 290
	_body.size = Vector2(700, 220)
	for i in 3:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(200, 40)
		b.add_theme_font_size_override("font_size", 17)
		UiStyle.style_button(b)
		add_child(b)
		_buttons.append(b)
	_buttons[0].pressed.connect(func(): wake.emit())
	_buttons[1].pressed.connect(func(): journal.emit())
	_buttons[2].pressed.connect(func(): quit.emit())


## The game's opening: its name, and Wake, the journal, Quit (not on the web, where there is nothing to quit to).
## The title's painting, the mask of its sea (which then moves: canvas_ui_title_sea), and the carved title. Any may
## be null until ChatGPT's art arrives.
func set_title_art(backdrop: Texture2D, sea: Texture2D, logo: Texture2D) -> void:
	_backdrop.texture = backdrop
	_backdrop.material = null
	if backdrop != null and sea != null:
		var m := ShaderMaterial.new()
		m.shader = load("res://scripts/game/canvas_ui_title_sea.gdshader")
		m.set_shader_parameter("sea_mask", sea)
		m.set_shader_parameter("art_size", Vector2(backdrop.get_size()))
		_backdrop.material = m
	_logo.texture = logo
	if logo != null:
		_logo.position = Vector2((1280 - logo.get_width()) / 2.0, 110)
	if mode == "title":
		_backdrop.visible = backdrop != null
		_rain.visible = backdrop != null
		for band in _bands:
			band.visible = backdrop != null
		_logo.visible = logo != null
		_title.text = "" if logo != null else "SALTMARROW DEEP"


## Is the sea in the title moving (the painting and its mask are both in)?
func sea_moving() -> bool:
	return _backdrop.material != null


func open_title(found: int) -> void:
	mode = "title"
	_dim.color = Color(0.02, 0.03, 0.05, 1.0)
	_backdrop.visible = _backdrop.texture != null
	_rain.visible = _backdrop.visible
	for band in _bands:
		band.visible = _backdrop.visible
	_logo.visible = _logo.texture != null
	_title.text = "" if _logo.visible else "SALTMARROW DEEP"
	_title.add_theme_color_override("font_color", INK)
	_sub.text = "A star fell into the sea beside Saltmarrow. Your sister went down to find it."
	_body.text = ""
	_show_buttons(["Wake", "Journal (%d)" % found, "" if OS.has_feature("web") else "Quit"])
	_open()


## He is dead: how, how far he got, and what the next life keeps.
func open_dead(stats: Dictionary) -> void:
	mode = "dead"
	_backdrop.visible = false
	_rain.visible = false
	for band in _bands:
		band.visible = false
	_logo.visible = false
	_dim.color = Color(0.03, 0.02, 0.02, 0.86)
	_title.text = "Thomas Wren is dead."
	_title.add_theme_color_override("font_color", Color(0.85, 0.5, 0.45))
	_sub.text = "%s, at depth %d." % [stats.get("cause", "He fell"), stats.get("depth", 1)]
	_body.text = _life(stats) + "\n\nHe wakes on the chapel floor. Sister Agathe is smiling.\nThe tunnels have moved. What he carried, what he learned, is gone.\nThe journal keeps all %d of the pages he has ever read." % stats.get("found_all", 0)
	_show_buttons(["Wake again", "Journal (%d)" % stats.get("found_all", 0), ""])
	_open()


## Garrick's tally tag is in his hand: the First Shift is over.
func open_won(stats: Dictionary) -> void:
	mode = "won"
	_backdrop.visible = false
	_rain.visible = false
	for band in _bands:
		band.visible = false
	_logo.visible = false
	_dim.color = Color(0.02, 0.03, 0.05, 0.88)
	_title.text = "The First Shift is over."
	_title.add_theme_color_override("font_color", AMBER)
	_sub.text = "SALTMARROW LIFT · NIGHT SHIFT · No. 1 · GARRICK"
	_body.text = _life(stats) + "\n\nMara will strike one more name from her count tonight.\nBelow the outflow, the water is faintly lit, and somewhere under it they are still singing.\nEllen is further down."
	_show_buttons(["Begin again", "Journal (%d)" % stats.get("found_all", 0), ""])
	_open()


func close() -> void:
	visible = false
	mode = ""


func _life(stats: Dictionary) -> String:
	var kills: int = stats.get("kills", 0)
	var found: int = stats.get("found_now", 0)
	return "This life: level %d  ·  %d %s  ·  %d %s found" % [stats.get("level", 1), kills, "foe" if kills == 1 else "foes", found, "page" if found == 1 else "pages"]


func _show_buttons(labels: Array) -> void:
	var shown := labels.filter(func(l): return l != "")
	var x := 640.0 - (shown.size() * 220.0 - 20.0) / 2.0
	for i in _buttons.size():
		_buttons[i].visible = labels[i] != ""
		_buttons[i].text = labels[i]
		if _buttons[i].visible:
			_buttons[i].position = Vector2(x, 520)
			x += 220.0


func _open() -> void:
	visible = true
	_fade = 0.0
	modulate.a = 0.0


func _process(delta: float) -> void:
	# now and then, far out to sea, lightning: the painting brightens and fades
	if _backdrop.visible:
		_next_flash -= delta
		if _next_flash <= 0.0:
			_flash = 1.0
			_next_flash = randf_range(7.0, 16.0)
		_flash = maxf(0.0, _flash - delta * 2.5)
		var k := 1.0 + 0.35 * _flash * (0.6 + 0.4 * sin(_flash * 40.0))
		_backdrop.modulate = Color(k, k, k * 1.05)
	if visible and _fade < 1.0:
		_fade = minf(1.0, _fade + delta / 0.8)
		modulate.a = _fade


func _label(at: Vector2, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.size = Vector2(1280, size + 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	add_child(l)
	return l


## Thin rain slanting down over the title's painting, drawn in the dark slate's pale grey.
class Rain extends Control:
	const DROPS := 140
	const SPEED := 620.0        # px a second
	const SLANT := Vector2(-0.28, 1.0)
	var _drops: Array[Vector3] = []   # x, y, length

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(1280, 720)
		visible = false
		for i in DROPS:
			_drops.append(Vector3(randf() * 1400.0, randf() * 720.0, randf_range(6.0, 14.0)))

	func _process(delta: float) -> void:
		if not visible:
			return
		for i in _drops.size():
			var d := _drops[i]
			d.x += SLANT.x * SPEED * delta
			d.y += SLANT.y * SPEED * delta
			if d.y > 720.0:
				d = Vector3(randf() * 1400.0, -20.0, d.z)
			_drops[i] = d
		queue_redraw()

	func _draw() -> void:
		for d in _drops:
			draw_line(Vector2(d.x, d.y), Vector2(d.x, d.y) + SLANT * d.z, Color(0.7, 0.75, 0.82, 0.18), 1.0)
