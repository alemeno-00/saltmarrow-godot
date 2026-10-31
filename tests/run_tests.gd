extends SceneTree
## Runs every test file in tests/ headless:  godot --headless --path . -s tests/run_tests.gd
## Each test file extends TestBase and has methods named test_*. A test fails when a check fails
## or when any engine or script error is logged while it runs (setup, body or teardown).
## A test file that does not load counts as a failure. Any failure makes the run exit 1.

const FILES := ["res://tests/test_level.gd", "res://tests/test_movement.gd", "res://tests/test_movement_rules.gd", "res://tests/test_directions.gd", "res://tests/test_stealth.gd", "res://tests/test_sneak_cover.gd", "res://tests/test_daggers.gd", "res://tests/test_items.gd", "res://tests/test_controls.gd", "res://tests/test_sewage.gd", "res://tests/test_rig.gd", "res://tests/test_fog.gd", "res://tests/test_power_roll.gd", "res://tests/test_battle.gd", "res://tests/test_hunting.gd", "res://tests/test_progress.gd", "res://tests/test_first_shift.gd", "res://tests/test_outflow_game.gd", "res://tests/test_room_kit.gd", "res://tests/test_room_kit_game.gd", "res://tests/test_lighting.gd", "res://tests/test_water.gd", "res://tests/test_room_contents.gd", "res://tests/test_room_events.gd", "res://tests/test_lore.gd", "res://tests/test_run_screens.gd"]

## Seconds the whole run may take before it is stopped as failed (a test that errors
## after an await can leave the runner waiting forever).
const TIMEOUT := 300.0

var failed := 0
var passed := 0
var catcher := ErrorCatcher.new()


## Collects every error the engine logs (script errors, push_error, failed engine checks).
## Warnings are ignored. The engine can log from any thread, hence the mutex.
class ErrorCatcher extends Logger:
	var _lock := Mutex.new()
	var _errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var what := rationale if not rationale.is_empty() else code
		_lock.lock()
		_errors.append("%s  (%s:%d in %s)" % [what, file, line, function])
		_lock.unlock()

	## Returns the errors logged since the last call and forgets them.
	func take() -> Array[String]:
		_lock.lock()
		var out := _errors.duplicate()
		_errors.clear()
		_lock.unlock()
		return out


func _initialize() -> void:
	OS.add_logger(catcher)
	create_timer(TIMEOUT).timeout.connect(_on_timeout)
	await process_frame
	catcher.take()
	for f in FILES:
		await _run_file(f)
	OS.remove_logger(catcher)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _run_file(f: String) -> void:
	var script: GDScript = load(f)
	if script == null or not script.can_instantiate():
		_report(f, "(load)", ["the test file did not load"] + catcher.take())
		return
	var methods := script.get_script_method_list().map(func(m): return m.name).filter(func(n): return n.begins_with("test_"))
	for m in methods:
		catcher.take()
		var t = script.new()
		if t.has_method("setup"):
			await t.setup(self)
		var problems: Array = []
		if t.failures.is_empty() and catcher.take().is_empty():
			await t.call(m)
		else:
			problems.append("setup failed, test not run")
		if t.has_method("teardown"):
			t.teardown()
		await process_frame  # let queued frees run so their errors land on this test
		_report(f, m, problems + t.failures + catcher.take())


func _report(f: String, m: String, problems: Array) -> void:
	if problems.is_empty():
		passed += 1
		print("PASS  %s :: %s" % [f.get_file(), m])
		return
	failed += 1
	for msg in problems:
		print("FAIL  %s :: %s  —  %s" % [f.get_file(), m, msg])


func _on_timeout() -> void:
	print("\nFAIL  the run took longer than %d seconds and was stopped" % TIMEOUT)
	print("%d passed, %d failed" % [passed, failed + 1])
	quit(1)
