class_name GameMenu
extends Control
## The menu (Esc, or the Menu button; design/ux/hud.md): Resume, Controls, New life, Quit. The keyboard hints that
## used to run along the top of the screen live here, in one list; every hotkey still works.

signal resume
signal new_life
signal quit

const CONTROLS := """Everything can be done with the mouse:
  Left-click: walk there; on an enemy, strike (from the dark if it hasn't seen you); on a crate, a paper or the valve, use it.
  Right-click: everything you can do with what is under the mouse.
  The hotbar: sneak, the lantern, throw, search, the belt; in a fight, your abilities and End turn.

Hotkeys:
  C  crouch and sneak, or stand          L  shutter, open or light the lantern          O  put the lantern out
  T  throw a dagger (then click)          E  search or use what is in reach               6-9  use a belt item
  J  journal          K  skills          Esc  this menu          R  a new life (or wake, on the death screen)
  In a fight:  1-5  abilities          F  careful step (or hold Shift)          Q  stand up          B  catch breath
               G  shut a sluice gate          Enter  end turn"""

var _controls: Label
var _buttons := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	panel.position = Vector2(140, 110)
	panel.custom_minimum_size = Vector2(1000, 0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Saltmarrow Deep"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UiStyle.INK)
	col.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	for b in [["resume", "Resume"], ["controls", "Controls"], ["new_life", "New life"], ["quit", "Quit"]]:
		var btn := Button.new()
		btn.text = b[1]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(150, 36)
		btn.add_theme_font_size_override("font_size", 16)
		UiStyle.style_button(btn)
		row.add_child(btn)
		_buttons[b[0]] = btn
	_buttons.resume.pressed.connect(func(): close(); resume.emit())
	_buttons.controls.pressed.connect(func(): _controls.visible = not _controls.visible)
	_buttons.new_life.pressed.connect(func(): close(); new_life.emit())
	_buttons.quit.pressed.connect(func(): quit.emit())
	_buttons.quit.visible = not OS.has_feature("web")
	_controls = Label.new()
	_controls.text = CONTROLS
	_controls.add_theme_font_size_override("font_size", 14)
	_controls.add_theme_color_override("font_color", UiStyle.INK)
	_controls.visible = false
	col.add_child(_controls)


func open() -> void:
	visible = true


func close() -> void:
	visible = false


## Press one of the menu's buttons by name (tests).
func press(name: String) -> void:
	(_buttons[name] as Button).pressed.emit()
