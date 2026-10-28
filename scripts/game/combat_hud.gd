class_name CombatHud
extends Control
## The fight's screen furniture: Thomas's portrait, Resolve, actions left, the ability bar and cards,
## the dice, a banner, and a short log. Placeholder drawing until the UI art arrives.

signal ability_pressed(index: int)
signal stand_pressed
signal breath_pressed
signal end_turn_pressed

const INK := Color(0.9, 0.85, 0.75)
const DIM := Color(0.6, 0.57, 0.52)
const AMBER := Color(1.0, 0.8, 0.45)

var portrait: Portrait
var dice: DiceView
var resolve_label: Label
var actions_label: Label
var bar: HBoxContainer
var ability_buttons: Array[Button] = []
var stand_button: Button
var breath_button: Button
var end_button: Button
var card: Label
var card_panel: PanelContainer
var banner: Label
var log_label: Label
var _log_lines: Array[String] = []
var history: Array[String] = []   # every line this level, for tests and tools
var _banner_time := 0.0
var _hovered := -1
var selected := -1
var _abilities: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	portrait = Portrait.new()
	portrait.position = Vector2(14, 720 - 132)
	portrait.size = Vector2(112, 118)
	add_child(portrait)

	resolve_label = _label(Vector2(136, 720 - 128), 18, AMBER)
	actions_label = _label(Vector2(136, 720 - 100), 14, INK)

	log_label = _label(Vector2(14, 720 - 290), 13, DIM)
	log_label.size = Vector2(430, 150)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	bar = HBoxContainer.new()
	bar.position = Vector2(136, 720 - 64)
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)

	card_panel = PanelContainer.new()
	card_panel.position = Vector2(470, 720 - 250)
	card_panel.custom_minimum_size = Vector2(420, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.07, 0.92)
	sb.border_color = Color(0.45, 0.38, 0.28)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(10)
	card_panel.add_theme_stylebox_override("panel", sb)
	card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_panel)
	card = Label.new()
	card.add_theme_color_override("font_color", INK)
	card.add_theme_font_size_override("font_size", 14)
	card_panel.add_child(card)
	card_panel.visible = false

	dice = DiceView.new()
	dice.position = Vector2(640 - 110, 18)
	dice.size = Vector2(220, 120)
	add_child(dice)

	banner = _label(Vector2(0, 150), 28, INK)
	banner.size = Vector2(1280, 40)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	banner.modulate.a = 0.0
	show_fight(false)


func _label(pos: Vector2, font: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_font_size_override("font_size", font)
	add_child(l)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	bar.add_child(b)
	return b


## Build the ability buttons for Thomas's kit.
func set_abilities(abilities: Array) -> void:
	_abilities = abilities
	for c in bar.get_children():
		c.queue_free()
	ability_buttons.clear()
	for i in abilities.size():
		var ab: Dictionary = abilities[i]
		var cost := "" if int(ab.cost) == 0 else "  (%d)" % int(ab.cost)
		var b := _button("%d  %s%s" % [i + 1, ab.name, cost])
		b.pressed.connect(func(): ability_pressed.emit(i))
		b.mouse_entered.connect(func(): _hovered = i; _show_card())
		b.mouse_exited.connect(func(): _hovered = -1; _show_card())
		ability_buttons.append(b)
	stand_button = _button("Q  Stand up")
	stand_button.pressed.connect(func(): stand_pressed.emit())
	breath_button = _button("B  Catch breath")
	breath_button.pressed.connect(func(): breath_pressed.emit())
	end_button = _button("Enter  End turn")
	end_button.pressed.connect(func(): end_turn_pressed.emit())


func select(i: int) -> void:
	selected = i
	for j in ability_buttons.size():
		ability_buttons[j].modulate = AMBER if j == i else Color.WHITE
	_show_card()


func _show_card() -> void:
	var i := _hovered if _hovered >= 0 else selected
	if i < 0 or i >= _abilities.size():
		card_panel.visible = false
		return
	card.text = Abilities.describe(_abilities[i])
	card_panel.visible = true
	card_panel.reset_size()
	card_panel.position.y = 720 - 76 - card_panel.size.y


func show_fight(on: bool) -> void:
	bar.visible = on
	actions_label.visible = on
	resolve_label.visible = on
	log_label.visible = on
	if not on:
		card_panel.visible = false
		select(-1)


## Refresh everything from the battle state. `can_act` is false while events are playing.
func refresh(hero: Combatant, battle: Battle, can_act: bool) -> void:
	portrait.set_state(hero)
	if battle == null or battle.over:
		return
	resolve_label.text = "Resolve %d" % hero.resolve
	var mine := battle.is_hero_turn()
	if mine:
		var b := battle.budget
		var dz := "   (dazed: one action only)" if hero.dazed > 0 else ""
		actions_label.text = "Move %d   ·   Maneuver %s   ·   Main %s   ·   Recoveries %d%s" % [b.move, "yes" if b.maneuver > 0 else "used", "yes" if b.main > 0 else "used", hero.recoveries, dz]
	else:
		actions_label.text = "Their turn"
	for i in ability_buttons.size():
		var ab: Dictionary = _abilities[i]
		ability_buttons[i].disabled = not (mine and can_act and battle.cannot_use(hero, ab) == "")
	stand_button.disabled = not (mine and can_act and hero.prone and battle.budget.maneuver > 0)
	breath_button.disabled = not (mine and can_act and battle.budget.main > 0 and hero.recoveries > 0)
	end_button.disabled = not (mine and can_act)


func add_log(text: String) -> void:
	history.append(text)
	_log_lines.append(text)
	while _log_lines.size() > 7:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func clear_log() -> void:
	_log_lines.clear()
	log_label.text = ""


func show_banner(text: String, seconds := 1.4) -> void:
	banner.text = text
	banner.modulate.a = 1.0
	_banner_time = seconds


func _process(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time < 0.4:
			banner.modulate.a = maxf(0.0, _banner_time / 0.4)


## Thomas's face. It shows how hurt he is instead of a number.
class Portrait extends Control:
	var state := 0   # 0 steady, 1 hurt, 2 badly hurt, 3 dying
	var dazed := false
	var _words := ["Steady", "Hurt", "Badly hurt", "Dying"]

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_state(h: Combatant) -> void:
		var s := 0
		if h.dying or h.dead:
			s = 3
		elif h.health_ratio() <= 0.35:
			s = 2
		elif h.health_ratio() <= 0.7:
			s = 1
		if s != state or dazed != (h.dazed > 0):
			state = s
			dazed = h.dazed > 0
			queue_redraw()

	func _draw() -> void:
		var o := Vector2(4, 4)
		draw_rect(Rect2(Vector2.ZERO, Vector2(104, 104)), Color(0.05, 0.05, 0.06))
		draw_rect(Rect2(Vector2.ZERO, Vector2(104, 104)), Color(0.45, 0.38, 0.28), false, 2.0)
		var px := 6.0
		var skin := Color("c89a7a")
		if state == 2:
			skin = Color("b8957f")
		elif state == 3:
			skin = Color("8f8a86")
		# coat and scarf
		draw_rect(Rect2(o + Vector2(2, 13) * px, Vector2(12, 3) * px), Color("3a3f3a"))
		draw_rect(Rect2(o + Vector2(4, 12) * px, Vector2(8, 2) * px), Color("a8322a"))
		# neck and face
		draw_rect(Rect2(o + Vector2(6, 10) * px, Vector2(4, 2) * px), skin.darkened(0.15))
		draw_rect(Rect2(o + Vector2(4, 3) * px, Vector2(8, 8) * px), skin)
		# hair growing out, stubble
		draw_rect(Rect2(o + Vector2(4, 2) * px, Vector2(8, 2) * px), Color("3a2a1e"))
		draw_rect(Rect2(o + Vector2(4, 9) * px, Vector2(8, 2) * px), skin.darkened(0.25))
		# the scar from cheekbone to ear
		draw_line(o + Vector2(4.5, 6) * px, o + Vector2(6, 8.5) * px, Color("9a6a58"), 2.0)
		# eyes
		var eye := Color("2a2a30")
		if state == 3:
			draw_rect(Rect2(o + Vector2(6, 6.4) * px, Vector2(1, 0.3) * px), eye)
			draw_rect(Rect2(o + Vector2(9, 6.4) * px, Vector2(1, 0.3) * px), eye)
		else:
			draw_rect(Rect2(o + Vector2(6, 6) * px, Vector2(1, 1) * px), eye)
			draw_rect(Rect2(o + Vector2(9, 6) * px, Vector2(1, 1) * px), eye)
		# mouth
		draw_rect(Rect2(o + Vector2(7, 8.6) * px, Vector2(2, 0.4) * px), Color("6a4036"))
		var blood := Color(0.45, 0.04, 0.06)
		if state >= 1:
			draw_rect(Rect2(o + Vector2(8.5, 8.6) * px, Vector2(0.5, 1.2) * px), blood)
			draw_rect(Rect2(o + Vector2(9, 5) * px, Vector2(2, 1) * px), Color(0.45, 0.3, 0.4, 0.6))
		if state >= 2:
			draw_rect(Rect2(o + Vector2(10.5, 3) * px, Vector2(0.6, 5) * px), blood)
			draw_rect(Rect2(o + Vector2(5, 9.5) * px, Vector2(1, 2) * px), blood)
			draw_rect(Rect2(o + Vector2(3, 13) * px, Vector2(2, 2) * px), blood)
		if state >= 3:
			draw_rect(Rect2(o + Vector2(6, 9) * px, Vector2(3, 3) * px), Color(0.3, 0.02, 0.04, 0.8))
		if dazed:
			draw_rect(Rect2(Vector2.ZERO, Vector2(104, 104)), Color(0.7, 0.75, 1.0, 0.12))
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(0, 116), _words[state], HORIZONTAL_ALIGNMENT_CENTER, 104, 13, Color(0.9, 0.85, 0.75) if state < 2 else Color(0.95, 0.5, 0.45))


## Two tumbling d10s, then the total and its tier. Bigger on a crit.
## Placeholder numbers; the dice art will show pips instead.
class DiceView extends Control:
	var _roll: Dictionary = {}
	var _who := ""
	var _what := ""
	var _t := 0.0
	var _hold := 0.0
	var _r1 := 1
	var _r2 := 1

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func show_roll(r: Dictionary, who: String, what: String) -> void:
		_roll = r
		_who = who
		_what = what
		_t = 0.0
		_hold = 1.6 if r.crit else 1.1
		visible = true
		queue_redraw()

	func _process(delta: float) -> void:
		if not visible:
			return
		_t += delta
		if _t < 0.3:
			_r1 = randi_range(1, 10)
			_r2 = randi_range(1, 10)
		if _t > 0.3 + _hold:
			visible = false
		queue_redraw()

	func _die(c: Vector2, n: int, s: float, col: Color) -> void:
		var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.9, -s * 0.15), c + Vector2(0, s), c + Vector2(-s * 0.9, -s * 0.15)])
		draw_colored_polygon(pts, Color(0.12, 0.11, 0.1))
		pts.append(pts[0])
		draw_polyline(pts, col, 2.0)
		var f := ThemeDB.fallback_font
		draw_string(f, c + Vector2(-s, 6), str(n), HORIZONTAL_ALIGNMENT_CENTER, s * 2, int(s * 0.75), col)

	func _draw() -> void:
		if _roll.is_empty():
			return
		var crit: bool = _roll.crit
		var s := 30.0 if crit else 22.0
		var col := Color(1.0, 0.8, 0.4) if crit else Color(0.9, 0.85, 0.75)
		var settled := _t >= 0.3
		var a: int = _roll.d1 if settled else _r1
		var b: int = _roll.d2 if settled else _r2
		var cx := size.x / 2.0
		_die(Vector2(cx - s * 1.2, s + 8), a, s, col)
		_die(Vector2(cx + s * 1.2, s + 8), b, s, col)
		if settled:
			var f := ThemeDB.fallback_font
			var tier_word: String = ["weak", "solid", "strong"][int(_roll.tier) - 1]
			var extra := ""
			if int(_roll.edges) > 0:
				extra = "  edge"
			elif int(_roll.edges) < 0:
				extra = "  bane"
			var line := "%s  %d  ·  %s%s" % [_what, int(_roll.total), "CRITICAL" if crit else tier_word, extra]
			draw_string(f, Vector2(-100, s * 2 + 34), line, HORIZONTAL_ALIGNMENT_CENTER, size.x + 200, 18 if crit else 15, col)
