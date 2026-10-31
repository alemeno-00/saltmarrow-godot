class_name JournalScreen
extends Control
## Reading what Thomas finds, and the journal of everything he has read (room contents part 2). Mouse first: click
## an entry to read it, click outside the page (or Esc, or J) to close.
## - `show_page(title, text, note)`: one page, just found.
## - `open_journal(journal)`: every entry, newest last; the newest is open.

signal closed

const INK := Color(0.2, 0.16, 0.12)
const PAPER := Color(0.86, 0.81, 0.7)
const DIM := Color(0.6, 0.57, 0.52)
const AMBER := Color(1.0, 0.8, 0.45)
const PAGE := Rect2(390, 90, 500, 520)
const LIST := Rect2(110, 90, 260, 520)

var _title: Label
var _text: RichTextLabel
var _note: Label
var _list: ItemList
var _paper: ColorRect
var _journal: Journal = null
var mode := ""            # "page" or "journal" while open


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_paper = ColorRect.new()
	_paper.color = PAPER
	_paper.position = PAGE.position
	_paper.size = PAGE.size
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	_title = Label.new()
	_title.position = PAGE.position + Vector2(28, 22)
	_title.size = Vector2(PAGE.size.x - 56, 30)
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", INK)
	add_child(_title)
	_text = RichTextLabel.new()
	_text.position = PAGE.position + Vector2(28, 64)
	_text.size = PAGE.size - Vector2(56, 120)
	_text.add_theme_font_size_override("normal_font_size", 15)
	_text.add_theme_color_override("default_color", INK)
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_text)
	_note = Label.new()
	_note.position = Vector2(PAGE.position.x, PAGE.end.y + 12)
	_note.size = Vector2(PAGE.size.x, 24)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override("font_color", DIM)
	add_child(_note)
	_list = ItemList.new()
	_list.position = LIST.position
	_list.size = LIST.size
	_list.focus_mode = Control.FOCUS_NONE
	_list.add_theme_font_size_override("font_size", 13)
	_list.item_selected.connect(_show_entry)
	add_child(_list)


## One page, as he finds it. `note` goes under it ("Added to the journal", "Already in the journal").
func show_page(title: String, text: String, note: String) -> void:
	mode = "page"
	_list.visible = false
	_fill(title, text)
	_note.text = note + "     (click anywhere to close)"
	visible = true


## The journal: every entry, the newest open.
func open_journal(j: Journal) -> void:
	mode = "journal"
	_journal = j
	_list.clear()
	_list.visible = true
	for e in j.entries:
		_list.add_item(e.title)
	if j.entries.is_empty():
		_fill("Journal", "Nothing yet. What Thomas finds and reads down here is kept, life after life.")
	else:
		_list.select(j.entries.size() - 1)
		_show_entry(j.entries.size() - 1)
	_note.text = "%d found     (J or click outside to close)" % j.entries.size()
	visible = true


func close() -> void:
	if visible:
		visible = false
		mode = ""
		closed.emit()


## The text on the open page (tests read this).
func page_text() -> String:
	return _text.text


func page_title() -> String:
	return _title.text


func _show_entry(i: int) -> void:
	if _journal != null and i >= 0 and i < _journal.entries.size():
		_fill(_journal.entries[i].title, _journal.entries[i].text)


func _fill(title: String, text: String) -> void:
	_title.text = title
	_text.text = text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if mode == "page" or not (PAGE.has_point(p) or LIST.has_point(p)):
			close()
			accept_event()
