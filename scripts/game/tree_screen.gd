class_name TreeScreen
extends Control
## The skill tree screen (K): level, experience, stats, and this life's weapon tree (Maces for Fury, Daggers for
## Shadow) to spend mastery points in.
## Learning is only allowed outside a fight.

signal changed

const INK := Color(0.9, 0.85, 0.75)
const DIM := Color(0.6, 0.57, 0.52)
const AMBER := Color(1.0, 0.8, 0.45)
const ORIGIN := Vector2(150, 50)
const SIZE := Vector2(980, 610)

var progress: Progress
var can_learn := true
var tree_id := "maces"
var header: Label
var points: Label
var detail: Label
var others: Label
var stat_row: HBoxContainer
var links: Control
var title: Label
var buttons := {}   # node id -> Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var border := ColorRect.new()
	border.color = Color(0.45, 0.38, 0.28)
	border.position = ORIGIN - Vector2(1, 1)
	border.size = SIZE + Vector2(2, 2)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	var panel := ColorRect.new()
	panel.color = Color(0.06, 0.06, 0.07)
	panel.position = ORIGIN
	panel.size = SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	header = _label(ORIGIN + Vector2(20, 14), 20, INK)
	points = _label(ORIGIN + Vector2(20, 46), 14, AMBER)
	stat_row = HBoxContainer.new()
	stat_row.position = ORIGIN + Vector2(20, 72)
	stat_row.add_theme_constant_override("separation", 14)
	add_child(stat_row)
	title = _label(ORIGIN + Vector2(20, 112), 17, INK)
	links = Links.new()
	links.screen = self
	links.position = Vector2.ZERO
	links.size = Vector2(1280, 720)
	links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(links)
	detail = _label(ORIGIN + Vector2(20, 432), 14, INK)
	detail.size = Vector2(620, 170)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	others = _label(ORIGIN + Vector2(660, 100), 12, DIM)
	others.size = Vector2(300, 490)
	others.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := _label(ORIGIN + Vector2(SIZE.x - 170, 14), 13, DIM)
	close.text = "K or Esc to close"


func _label(pos: Vector2, font: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", font)
	add_child(l)
	return l


## Rows go down the screen; a row's nodes spread across it.
func _node_pos(n: Dictionary) -> Vector2:
	var row: Array = SkillTrees.tree(tree_id).filter(func(m): return m.row == n.row)
	var i := 0
	for j in row.size():
		if row[j].id == n.id:
			i = j
	var width := row.size() * 210 - 20
	var x := 20 + (620 - width) / 2.0 + i * 210
	return ORIGIN + Vector2(x, 145 + (n.row - 1) * 74)


func open(p: Progress, learning_allowed: bool) -> void:
	progress = p
	can_learn = learning_allowed
	_build_tree(p.weapon_tree())
	refresh()
	detail.text = "Hover over a skill to read it. Click to learn it." if can_learn else "You can look, but not learn, during a fight."
	visible = true


## The buttons for a weapon tree's skills (rebuilt when the tree changes with a new life's backstory).
func _build_tree(id: String) -> void:
	if id == tree_id and not buttons.is_empty():
		return
	tree_id = id
	for b in buttons.values():
		b.queue_free()
	buttons.clear()
	title.text = SkillTrees.NAMES[id]
	for n in SkillTrees.tree(id):
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(190, 48)
		b.position = _node_pos(n)
		b.add_theme_font_size_override("font_size", 13)
		b.text = "%s\n%s" % [n.name, n.kind]
		b.pressed.connect(_on_node.bind(n.id))
		b.mouse_entered.connect(_on_hover.bind(n.id))
		add_child(b)
		buttons[n.id] = b


func refresh() -> void:
	if progress == null:
		return
	header.text = "Thomas Wren   ·   %s   ·   Level %d   ·   Experience %d / %d" % [progress.backstory.capitalize(), progress.level, progress.xp, progress.xp_needed()]
	var hits := int(progress.hits.get(tree_id, 0))
	var to_next := Progress.HITS_PER_POINT - hits % Progress.HITS_PER_POINT
	points.text = "%s mastery points: %d   (next in %d hits)      Level points: %d   (for spell schools and utility trees; none found yet)" % [{"maces": "Mace", "daggers": "Dagger"}.get(tree_id, "Weapon"), progress.points_for(tree_id), to_next, progress.level_points]
	for c in stat_row.get_children():
		c.queue_free()
	for st in Progress.STATS:
		var l := Label.new()
		l.text = "%s %d" % [st.capitalize(), int(progress.stats[st])]
		l.add_theme_color_override("font_color", INK if st == SkillTrees.TREE_STAT.get(tree_id, "might") else DIM)
		l.add_theme_font_size_override("font_size", 14)
		stat_row.add_child(l)
		if progress.stat_points > 0 and can_learn:
			var b := Button.new()
			b.text = "+"
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(func(): progress.raise_stat(st); changed.emit(); refresh())
			stat_row.add_child(b)
	if progress.stat_points > 0:
		var l := Label.new()
		l.text = "(%d stat point to spend; Might for maces, Agility for daggers)" % progress.stat_points
		l.add_theme_color_override("font_color", AMBER)
		l.add_theme_font_size_override("font_size", 13)
		stat_row.add_child(l)
	for n in SkillTrees.tree(tree_id):
		var b: Button = buttons[n.id]
		if progress.owns(tree_id, n.id):
			b.modulate = AMBER
		elif progress.cannot_take(tree_id, n.id) == "":
			b.modulate = Color(0.85, 1.0, 0.85)
		elif not n.ready:
			b.modulate = Color(0.45, 0.45, 0.45)
		else:
			b.modulate = Color(0.7, 0.7, 0.7)
	var lines: Array[String] = ["Other trees"]
	for t in SkillTrees.WEAPON_TREES:
		if t != tree_id:
			lines.append("%s: opens after %d hits with one, or from its manual. %s" % [SkillTrees.NAMES[t], Progress.OPEN_AT, "Another life's backstory starts with it." if not SkillTrees.tree(t).is_empty() else "Not in the game yet."])
	for t in SkillTrees.SPELL_TREES:
		lines.append("%s: needs its tome. Not in the game yet." % SkillTrees.NAMES[t])
	lines.append("Stealth, Survival, Warfare: not in the game yet.")
	others.text = "\n".join(lines)
	links.queue_redraw()


func _on_hover(id: String) -> void:
	var n := SkillTrees.node(tree_id, id)
	var status := "Learned." if progress.owns(tree_id, id) else progress.cannot_take(tree_id, id)
	if status == "":
		status = "Click to learn (1 mastery point)." if can_learn else "You can't learn during a fight."
	detail.text = SkillTrees.describe(n) + "\n\n" + status


func _on_node(id: String) -> void:
	if not can_learn:
		detail.text = "You can't learn during a fight."
		return
	var why := progress.cannot_take(tree_id, id)
	if why != "":
		_on_hover(id)
		return
	progress.take(tree_id, id)
	changed.emit()
	refresh()
	_on_hover(id)


## The lines between connected skills.
class Links extends Control:
	var screen: TreeScreen

	func _draw() -> void:
		if screen == null or screen.progress == null:
			return
		for n in SkillTrees.tree(screen.tree_id):
			for need in n.needs:
				if not screen.buttons.has(need) or not screen.buttons.has(n.id):
					continue
				var a: Button = screen.buttons[need]
				var b: Button = screen.buttons[n.id]
				var lit := screen.progress.owns(screen.tree_id, need)
				draw_line(a.position + Vector2(a.size.x / 2, a.size.y), b.position + Vector2(b.size.x / 2, 0), Color(1, 0.8, 0.45, 0.7) if lit else Color(0.5, 0.47, 0.42, 0.35), 2.0)
