class_name CombatHud
extends Control
## Everything on screen while playing (design/ux/hud.md), mouse first as in Baldur's Gate 3:
## - **the hotbar**, bottom centre: Thomas's portrait, his Stamina (bar and numbers) and Resolve; the action slots
##   (exploring: sneak, lantern, throw, search; fighting: his abilities, careful step, stand up, catch breath); the
##   belt's four slots; in a fight, what's left of the turn and End turn;
## - **top left**: depth, level and experience; **top right**: Journal, Skills, Menu;
## - **top centre** in a fight: the turn order, the round and their Malice; the dice below it;
## - **by the cursor**: a tooltip for what is under the mouse; **bottom left** in a fight: the log; banners.
## The look comes from UiStyle (placeholders until ChatGPT's UI kit, ART_JOBS job 20).

signal ability_pressed(index: int)
signal stand_pressed
signal breath_pressed
signal end_turn_pressed
signal step_pressed
signal belt_pressed(slot: int)
signal explore_pressed(action: String)    # sneak, lantern, douse, throw, search
signal journal_pressed
signal skills_pressed
signal menu_pressed

const INK := UiStyle.INK
const DIM := UiStyle.DIM
const AMBER := UiStyle.AMBER
const SLOT := Vector2(44, 44)
const SCREEN := Vector2(1280, 720)

var portrait: Portrait
var dice: DiceView
var hotbar: PanelContainer
var stamina_bar: Bar
var stamina_label: Label
var resolve_label: Label
var malice_label: Label
var actions_label: Label          # what's left of the turn
var bar: HBoxContainer            # the fight's slots
var explore_row: HBoxContainer    # the exploring slots
var explore_buttons := {}         # action -> Button
var ability_buttons: Array[Button] = []
var stand_button: Button
var step_button: Button
var breath_button: Button
var end_button: Button
var card: Label
var card_panel: PanelContainer
var tip_panel: PanelContainer
var tip: Label
var banner: Label
var log_label: Label
var turn_row: HBoxContainer       # the turn order along the top, the one acting lit
var belt_row: HBoxContainer       # the belt's four slots, in the hotbar
var status_label: Label           # top left: depth, level
var xp_bar: Bar
var top_buttons := {}             # journal, skills, menu -> Button
var turn_tokens: Array = []       # [Combatant, Control] in the order shown (tests read this)
var _turn_key := ""
var _log_lines: Array[String] = []
var history: Array[String] = []   # every line this level, for tests and tools
var _banner_time := 0.0
var _hovered := -1
var selected := -1
var _abilities: Array = []
var _fight := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hotbar()
	_build_top()

	log_label = _label(Vector2(14, SCREEN.y - 300), 13, DIM)
	log_label.size = Vector2(330, 170)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	card_panel = PanelContainer.new()
	card_panel.add_theme_stylebox_override("panel", UiStyle.panel_small())
	card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_panel.custom_minimum_size = Vector2(380, 0)
	add_child(card_panel)
	card = Label.new()
	card.add_theme_color_override("font_color", INK)
	card.add_theme_font_size_override("font_size", 14)
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.custom_minimum_size = Vector2(368, 0)
	card_panel.add_child(card)
	card_panel.visible = false

	tip_panel = PanelContainer.new()
	tip_panel.add_theme_stylebox_override("panel", UiStyle.panel_small())
	tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tip_panel)
	tip = Label.new()
	tip.add_theme_color_override("font_color", INK)
	tip.add_theme_font_size_override("font_size", 13)
	tip_panel.add_child(tip)
	tip_panel.visible = false

	dice = DiceView.new()
	dice.position = Vector2(SCREEN.x / 2.0 - 110, 62)
	dice.size = Vector2(220, 120)
	add_child(dice)

	banner = _label(Vector2(0, 170), 28, INK)
	banner.size = Vector2(SCREEN.x, 40)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	banner.modulate.a = 0.0
	set_belt([])
	set_explore(false, "lit", false, false)
	show_fight(false)


## The hotbar along the bottom: portrait and vitals, the action slots, the belt, the turn's budget, End turn.
func _build_hotbar() -> void:
	hotbar = PanelContainer.new()
	hotbar.add_theme_stylebox_override("panel", UiStyle.panel())
	hotbar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hotbar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar.add_child(row)

	portrait = Portrait.new()
	portrait.show_word = false
	portrait.custom_minimum_size = Vector2(66, 66)
	portrait.scale = Vector2(0.5, 0.5)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(66, 66)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(portrait)
	row.add_child(holder)

	var vitals := VBoxContainer.new()
	vitals.add_theme_constant_override("separation", 2)
	vitals.alignment = BoxContainer.ALIGNMENT_CENTER
	vitals.custom_minimum_size = Vector2(118, 0)
	row.add_child(vitals)
	stamina_bar = Bar.new()
	stamina_bar.fill = UiStyle.HARM
	stamina_bar.custom_minimum_size = Vector2(118, 10)
	vitals.add_child(stamina_bar)
	stamina_label = _chip("", 13, INK)
	vitals.add_child(stamina_label)
	resolve_label = _chip("", 13, AMBER)
	vitals.add_child(resolve_label)

	explore_row = HBoxContainer.new()
	explore_row.add_theme_constant_override("separation", 4)
	row.add_child(explore_row)
	for a in [["sneak", "Sneak", "C"], ["lantern", "Lantern", "L"], ["throw", "Throw", "T"], ["search", "Use", "E"]]:
		var b := _slot(a[1], a[0], a[2], 0)
		var act: String = a[0]
		b.pressed.connect(func(): explore_pressed.emit(act))
		if act == "lantern":
			b.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT: explore_pressed.emit("douse"))
		explore_row.add_child(b)
		explore_buttons[act] = b

	bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	row.add_child(bar)

	var sep := VSeparator.new()
	row.add_child(sep)
	belt_row = HBoxContainer.new()
	belt_row.add_theme_constant_override("separation", 4)
	row.add_child(belt_row)

	actions_label = _chip("", 12, INK)
	actions_label.custom_minimum_size = Vector2(130, 0)
	actions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(actions_label)

	end_button = Button.new()
	end_button.text = "End turn"
	end_button.focus_mode = Control.FOCUS_NONE
	end_button.custom_minimum_size = Vector2(96, 44)
	end_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	end_button.add_theme_font_size_override("font_size", 15)
	UiStyle.style_button(end_button, true)
	end_button.pressed.connect(func(): end_turn_pressed.emit())
	end_button.tooltip_text = "End your turn (Enter)"
	row.add_child(end_button)


## Top left: depth, level, experience. Top right: Journal, Skills, Menu. Top centre: the turn order (fights).
func _build_top() -> void:
	status_label = _label(Vector2(14, 10), 15, INK)
	xp_bar = Bar.new()
	xp_bar.fill = AMBER
	xp_bar.position = Vector2(14, 34)
	xp_bar.size = Vector2(150, 6)
	add_child(xp_bar)

	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	add_child(right)
	for b in [["journal", "Journal", "J"], ["skills", "Skills", "K"], ["menu", "Menu", "Esc"]]:
		var btn := Button.new()
		btn.text = b[1]
		btn.tooltip_text = "%s (%s)" % [b[1], b[2]]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(84, 30)
		btn.add_theme_font_size_override("font_size", 14)
		UiStyle.style_button(btn)
		var which: String = b[0]
		btn.pressed.connect(func(): {"journal": journal_pressed, "skills": skills_pressed, "menu": menu_pressed}[which].emit())
		right.add_child(btn)
		top_buttons[which] = btn
	right.reset_size()
	right.position = Vector2(SCREEN.x - right.size.x - 12, 10)

	turn_row = HBoxContainer.new()
	turn_row.add_theme_constant_override("separation", 6)
	turn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	turn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_row.position = Vector2(0, 10)
	turn_row.size = Vector2(SCREEN.x, 40)
	add_child(turn_row)
	malice_label = _label(Vector2.ZERO, 13, Color(0.85, 0.35, 0.3))


func _label(pos: Vector2, font: int, col: Color) -> Label:
	var l := _chip("", font, col)
	l.position = pos
	add_child(l)
	return l


func _chip(text: String, font: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_font_size_override("font_size", font)
	return l


## One action slot: its icon (or a short word until the art arrives), its hotkey in the corner, its cost.
func _slot(word: String, icon_id: String, key: String, cost: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = SLOT
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	UiStyle.style_slot(b)
	var t := UiStyle.ability_icon(icon_id)
	if t != null:
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = t
		icon.position = Vector2(6, 6)
		icon.size = Vector2(32, 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
	else:
		b.text = word
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 10)
	if key != "":
		var k := _chip(key, 10, AMBER)
		k.position = Vector2(3, 0)
		b.add_child(k)
	if cost > 0:
		var c := _chip(str(cost), 10, AMBER)
		c.position = Vector2(SLOT.x - 10, 0)
		b.add_child(c)
	return b


## Build the fight's slots for Thomas's kit.
func set_abilities(abilities: Array) -> void:
	_abilities = abilities
	for c in bar.get_children():
		c.queue_free()
	ability_buttons.clear()
	for i in abilities.size():
		var ab: Dictionary = abilities[i]
		var b := _slot(_short(ab.name), String(ab.get("id", "")), str(i + 1), int(ab.cost))
		b.pressed.connect(func(): ability_pressed.emit(i))
		b.mouse_entered.connect(func(): _hovered = i; _show_card())
		b.mouse_exited.connect(func(): _hovered = -1; _show_card())
		bar.add_child(b)
		ability_buttons.append(b)
	step_button = _extra("Step", "careful_step", "F", "Careful step   ·   maneuver\nStep up to 1.5 m without giving anyone a free strike.\nF (or hold Shift), then click where to step.")
	step_button.pressed.connect(func(): step_pressed.emit())
	stand_button = _extra("Stand", "stand_up", "Q", "Stand up   ·   maneuver\nGet up off the ground.")
	stand_button.pressed.connect(func(): stand_pressed.emit())
	breath_button = _extra("Breathe", "catch_breath", "B", "Catch breath   ·   main action\nSpend a Recovery to get Stamina back. Dying, it brings him round.")
	breath_button.pressed.connect(func(): breath_pressed.emit())


func _extra(word: String, id: String, key: String, text: String) -> Button:
	var b := _slot(word, id, key, 0)
	b.mouse_entered.connect(func(): _hint(text))
	b.mouse_exited.connect(func(): _show_card())
	bar.add_child(b)
	return b


## A name short enough for a slot until its icon arrives: "Heavy Blow" -> "Heavy".
static func _short(name: String) -> String:
	var w := name.split(" ")
	return w[0] if w[0].length() > 3 or w.size() == 1 else w[0] + " " + w[1]


func select(i: int) -> void:
	selected = i
	for j in ability_buttons.size():
		ability_buttons[j].modulate = AMBER if j == i else Color.WHITE
	_show_card()


func _hint(text: String) -> void:
	card.text = text
	_place_card()


func _place_card() -> void:
	card_panel.visible = true
	card_panel.reset_size()
	card_panel.position = Vector2((SCREEN.x - card_panel.size.x) / 2.0, hotbar.position.y - card_panel.size.y - 8)


func set_stepping(on: bool) -> void:
	if step_button:
		step_button.modulate = AMBER if on else Color.WHITE


func _show_card() -> void:
	var i := _hovered if _hovered >= 0 else selected
	if i < 0 or i >= _abilities.size():
		card_panel.visible = false
		return
	card.text = Abilities.describe(_abilities[i])
	_place_card()


func show_fight(on: bool) -> void:
	_fight = on
	bar.visible = on
	explore_row.visible = not on
	actions_label.visible = on
	end_button.visible = on
	malice_label.visible = on
	log_label.visible = on
	turn_row.visible = on
	if not on:
		card_panel.visible = false
		select(-1)
		turn_tokens.clear()
		_turn_key = ""
	_fit_hotbar()


## Keep the hotbar centred along the bottom, whatever it holds.
func _fit_hotbar() -> void:
	if hotbar == null:
		return
	hotbar.reset_size()
	hotbar.position = Vector2((SCREEN.x - hotbar.size.x) / 2.0, SCREEN.y - hotbar.size.y - 8)


## The exploring slots: whether he is crouched, the lantern's state, whether he can throw, whether anything is in
## reach to search or use.
func set_explore(sneaking: bool, lantern: String, can_throw: bool, can_use: bool) -> void:
	var s: Button = explore_buttons.sneak
	s.modulate = AMBER if sneaking else Color.WHITE
	s.tooltip_text = ("Stand up" if sneaking else "Crouch and sneak") + " (C)"
	var l: Button = explore_buttons.lantern
	var icon := UiStyle.ability_icon("lantern_" + lantern)
	if icon != null and l.has_node("Icon"):
		(l.get_node("Icon") as TextureRect).texture = icon
	elif icon == null:
		l.text = {"lit": "Lit", "shuttered": "Dim", "out": "Out"}.get(lantern, "Lit")
	l.tooltip_text = {"lit": "Lantern lit: click to shutter it", "shuttered": "Lantern shuttered: click to open it", "out": "Lantern out: click to light it"}.get(lantern, "") + " (L). Right-click: put it out (O)."
	explore_buttons.throw.visible = can_throw
	explore_buttons.throw.tooltip_text = "Throw a dagger (T), then click where"
	explore_buttons.search.disabled = not can_use
	explore_buttons.search.tooltip_text = "Search or use what is in reach (E)" if can_use else "Nothing in reach to search or use"
	_fit_hotbar()


## Top left: where he is and how far he has grown.
func set_status(depth: int, level: int, xp: int, need: int, spend: bool) -> void:
	status_label.text = "Depth %d   ·   Level %d%s" % [depth, level, "   ·   points to spend (K)" if spend else ""]
	status_label.add_theme_color_override("font_color", AMBER if spend else INK)
	xp_bar.value = float(xp) / float(maxi(1, need))


## Refresh everything from Thomas and the battle. `can_act` is false while events are playing.
func refresh(hero: Combatant, battle: Battle, can_act: bool) -> void:
	portrait.set_state(hero)
	stamina_bar.value = clampf(float(hero.stamina) / float(maxi(1, hero.max_stamina)), 0.0, 1.0)
	var word: String = ["Steady", "Hurt", "Badly hurt", "Dying"][portrait.state]
	stamina_label.text = "%d / %d   %s" % [hero.stamina, hero.max_stamina, word]
	stamina_label.add_theme_color_override("font_color", INK if portrait.state < 2 else Color(0.95, 0.5, 0.45))
	resolve_label.text = "Resolve %d   ·   Recoveries %d" % [hero.resolve, hero.recoveries]
	if battle == null or battle.over:
		_fit_hotbar()
		return
	var mine := battle.is_hero_turn()
	if mine:
		var b := battle.budget
		actions_label.text = "Move %.1f m\nManeuver %s  ·  Main %s%s" % [b.move, "✓" if b.maneuver > 0 else "–", "✓" if b.main > 0 else "–", "\nDazed: one action" if hero.dazed > 0 else ""]
	else:
		actions_label.text = "Their turn"
	set_turn_order(battle)
	for i in ability_buttons.size():
		var ab: Dictionary = _abilities[i]
		ability_buttons[i].disabled = not (mine and can_act and battle.cannot_use(hero, ab) == "")
	stand_button.disabled = not (mine and can_act and hero.prone and battle.budget.maneuver > 0)
	step_button.disabled = not (mine and can_act and not hero.prone and battle.budget.maneuver > 0)
	breath_button.disabled = not (mine and can_act and battle.budget.main > 0 and hero.recoveries > 0)
	end_button.disabled = not (mine and can_act)
	_fit_hotbar()


## The turn order along the top (as in Baldur's Gate 3): a token for everyone still in the fight, in the order
## they act, the one acting lit; the round before them and their Malice after.
func set_turn_order(battle: Battle) -> void:
	var key := "%d %s" % [battle.round, str(battle.active)]
	for u in battle.units:
		key += ("1" if u.alive() else "0") + ",".join(u.condition_words())
	if key == _turn_key:
		return
	_turn_key = key
	for c in turn_row.get_children():
		if c != malice_label:
			c.queue_free()
	turn_tokens.clear()
	turn_row.add_child(_chip("Round %d" % battle.round, 13, DIM))
	for u in battle.units:
		if u.alive():
			var t := Token.new()
			t.setup(u, u == battle.active)
			turn_row.add_child(t)
			turn_tokens.append([u, t])
	if malice_label.get_parent() != turn_row:
		malice_label.get_parent().remove_child(malice_label)
		turn_row.add_child(malice_label)
	turn_row.move_child(malice_label, -1)


## The belt: four slots (keys 6-9), each the item's icon or empty.
func set_belt(items: Array) -> void:
	for c in belt_row.get_children():
		c.queue_free()
	for i in Items.BELT_SLOTS:
		var slot := Button.new()
		slot.custom_minimum_size = SLOT
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot.focus_mode = Control.FOCUS_NONE
		UiStyle.style_slot(slot)
		slot.pressed.connect(func(): belt_pressed.emit(i))
		if i < items.size():
			var tex := Items.icon(items[i])
			if tex != null:
				var icon := TextureRect.new()
				icon.texture = tex
				icon.position = Vector2(6, 6)
				icon.size = Vector2(32, 32)
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(icon)
			else:
				slot.text = Items.NAMES[items[i]]
				slot.clip_text = true
				slot.add_theme_font_size_override("font_size", 10)
			slot.tooltip_text = Items.TEXT[items[i]]
		else:
			slot.tooltip_text = "An empty belt slot"
		var key := _chip(str(6 + i), 10, AMBER)
		key.position = Vector2(3, 0)
		slot.add_child(key)
		belt_row.add_child(slot)
	_fit_hotbar()


## The enemy side's Malice: it grows every round, so long fights get worse.
func set_malice(v: int) -> void:
	malice_label.text = "Their Malice %d" % v


## The tooltip by the cursor: a few lines about what is under the mouse, at `at` (screen pixels). Empty hides it.
func show_tip(lines: Array, at: Vector2) -> void:
	if lines.is_empty():
		tip_panel.visible = false
		return
	tip.text = "\n".join(lines)
	tip_panel.visible = true
	tip_panel.reset_size()
	var p := at + Vector2(18, 18)
	p.x = minf(p.x, SCREEN.x - tip_panel.size.x - 6)
	p.y = minf(p.y, SCREEN.y - tip_panel.size.y - 6)
	tip_panel.position = p


func add_log(text: String) -> void:
	history.append(text)
	_log_lines.append(text)
	while _log_lines.size() > 8:
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
	if tip_panel.visible and get_tree() != null and _paused_screen():
		tip_panel.visible = false
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time < 0.4:
			banner.modulate.a = maxf(0.0, _banner_time / 0.4)


## Is a screen open over the game (the menu, the journal...)? Then the tooltip hides.
func _paused_screen() -> bool:
	var g := get_parent().get_parent() if get_parent() != null else null
	return g != null and g.has_method("paused") and g.paused()


## A thin bar, `value` 0-1 full: Stamina, experience. Placeholder until the kit's bar art.
class Bar extends Control:
	var value := 1.0:
		set(v):
			value = clampf(v, 0.0, 1.0)
			queue_redraw()
	var fill := UiStyle.HARM

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.04, 0.04, 0.05, 0.9))
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * value, size.y - 2)), fill)
		draw_rect(r, UiStyle.BRASS_DIM, false, 1.0)


## Someone in the turn order: their face (or their initials until the art arrives), lit when acting, red-edged for
## the other side, their conditions underneath.
class Token extends Control:
	var unit: Combatant
	var active := false

	func setup(u: Combatant, is_active: bool) -> void:
		unit = u
		active = is_active
		custom_minimum_size = Vector2(36, 36)
		mouse_filter = Control.MOUSE_FILTER_PASS
		var words := [u.name, u.health_word()] + Array(u.condition_words())
		tooltip_text = ", ".join(words)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, Vector2(36, 36))
		draw_rect(r, UiStyle.SLATE_LIGHT)
		var face := UiStyle.portrait(unit.style)
		if face != null:
			draw_texture_rect(face, r.grow(-2), false)
		else:
			var f := ThemeDB.fallback_font
			var initials := "".join(Array(unit.name.split(" ")).map(func(w): return w.substr(0, 1)))
			draw_string(f, Vector2(0, 23), initials, HORIZONTAL_ALIGNMENT_CENTER, 36, 14, UiStyle.INK if unit.team == "hero" else Color(0.9, 0.55, 0.5))
		var edge := UiStyle.AMBER if active else (UiStyle.BRASS if unit.team == "hero" else UiStyle.HARM)
		draw_rect(r, edge, false, 2.0 if active else 1.0)
		var hp := clampf(float(unit.stamina) / float(maxi(1, unit.max_stamina)), 0.0, 1.0)
		if unit.team == "hero":
			draw_rect(Rect2(2, 32, 32 * hp, 2), UiStyle.HARM)


## Thomas's face. It shows how hurt he is instead of a number.
class Portrait extends Control:
	var state := 0   # 0 steady, 1 hurt, 2 badly hurt, 3 dying
	var dazed := false
	var show_word := true   # the word under the face (the hotbar shows it beside the Stamina bar instead)
	var _words := ["Steady", "Hurt", "Badly hurt", "Dying"]

	const ART := "res://assets/characters/thomas/production/sprites/steady-portrait-candidate.png"
	## One portrait per health state (assets/portraits/thomas/README.md); chosen, not animated between.
	const STATES := ["res://assets/portraits/thomas/steady.png", "res://assets/portraits/thomas/hurt.png",
		"res://assets/portraits/thomas/badly_hurt.png", "res://assets/portraits/thomas/dying.png"]
	var _tex: Texture2D = null
	var _faces: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(ART):
			_tex = load(ART)
		for p in STATES:
			_faces.append(load(p) if ResourceLoader.exists(p) else null)

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
		if _faces[state] != null:
			_draw_face(_faces[state])
			return
		if _tex != null:
			_draw_art()
			return
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
		if not show_word:
			return
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(0, 116), _words[state], HORIZONTAL_ALIGNMENT_CENTER, 104, 13, Color(0.9, 0.85, 0.75) if state < 2 else Color(0.95, 0.5, 0.45))


	## The painted portrait for this health state: the wounds are in the art.
	func _draw_face(tex: Texture2D) -> void:
		var box := Rect2(Vector2(2, 2), Vector2(128, 128))
		draw_rect(box.grow(2), Color(0.45, 0.38, 0.28))
		draw_rect(box, Color(0.05, 0.05, 0.06))
		draw_texture_rect(tex, box, false)
		if dazed:
			draw_rect(box, Color(0.7, 0.75, 1.0, 0.12))
		if not show_word:
			return
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(2, 146), _words[state], HORIZONTAL_ALIGNMENT_CENTER, 128, 13, Color(0.9, 0.85, 0.75) if state < 2 else Color(0.95, 0.5, 0.45))

	func _draw_art() -> void:
		var box := Rect2(Vector2(2, 2), Vector2(128, 128))
		draw_rect(box.grow(2), Color(0.45, 0.38, 0.28))
		draw_rect(box, Color(0.05, 0.05, 0.06))
		var tint: Color = [Color.WHITE, Color(0.95, 0.88, 0.86), Color(0.85, 0.74, 0.72), Color(0.58, 0.58, 0.62)][state]
		draw_texture_rect(_tex, box, false, tint)
		var blood := Color(0.42, 0.03, 0.05)
		var p := box.position
		# 128 x 128 face: mouth near (82, 60), eye near (82, 45), scarred cheek near (67, 47), brow near (75, 36)
		if state >= 1:
			draw_rect(Rect2(p + Vector2(81, 61), Vector2(1, 3)), blood)
			draw_rect(Rect2(p + Vector2(80, 49), Vector2(4, 2)), Color(0.35, 0.22, 0.32, 0.4))
		if state >= 2:
			draw_rect(Rect2(p + Vector2(75, 34), Vector2(1, 7)), blood)
			draw_rect(Rect2(p + Vector2(65, 52), Vector2(1, 5)), blood)
			draw_rect(Rect2(p + Vector2(82, 64), Vector2(1, 4)), blood)
		if state >= 3:
			draw_rect(box, Color(0.1, 0.1, 0.14, 0.25))
		if dazed:
			draw_rect(box, Color(0.7, 0.75, 1.0, 0.12))
		if not show_word:
			return
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(2, 146), _words[state], HORIZONTAL_ALIGNMENT_CENTER, 128, 13, Color(0.9, 0.85, 0.75) if state < 2 else Color(0.95, 0.5, 0.45))


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
	## The bone die and the slate die (assets/ui/dice/): 8 tumbling frames, then a resting face with pips for 1-10.
	var _tumble: Array = []
	var _faces: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false
		for d in ["bone", "slate"]:
			var t := "res://assets/ui/dice/%s_tumble.png" % d
			var f := "res://assets/ui/dice/%s_faces.png" % d
			_tumble.append(load(t) if ResourceLoader.exists(t) else null)
			_faces.append(load(f) if ResourceLoader.exists(f) else null)

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

	## One die: tumbling while the roll is in the air, then its face. Falls back to a drawn die without the art.
	func _die_art(i: int, c: Vector2, n: int, s: float, settled: bool) -> bool:
		var tex: Texture2D = _faces[i] if settled else _tumble[i]
		if tex == null:
			return false
		var frame := n - 1 if settled else (int(_t * 12.0) + i * 3) % 8
		var side := s * 2.2
		draw_texture_rect_region(tex, Rect2(c - Vector2(side, side) / 2.0, Vector2(side, side)), Rect2(frame * 48, 0, 48, 48))
		return true

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
		if not _die_art(0, Vector2(cx - s * 1.2, s + 8), a, s, settled):
			_die(Vector2(cx - s * 1.2, s + 8), a, s, col)
		if not _die_art(1, Vector2(cx + s * 1.2, s + 8), b, s, settled):
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
