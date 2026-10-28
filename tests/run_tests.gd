extends SceneTree
## Runs every test file in tests/ headless:  godot --headless --path . -s tests/run_tests.gd
## Each test file extends RefCounted and has methods named test_*. A failed check throws, and the run exits 1.

const FILES := ["res://tests/test_level.gd", "res://tests/test_movement.gd", "res://tests/test_power_roll.gd", "res://tests/test_battle.gd"]

var failed := 0
var passed := 0


func _initialize() -> void:
	await process_frame
	for f in FILES:
		var script: GDScript = load(f)
		var methods := script.get_script_method_list().map(func(m): return m.name).filter(func(n): return n.begins_with("test_"))
		for m in methods:
			var t = script.new()
			if t.has_method("setup"):
				await t.setup(self)
			t.failures = []
			await t.call(m)
			if t.failures.is_empty():
				passed += 1
				print("PASS  %s :: %s" % [f.get_file(), m])
			else:
				failed += 1
				for msg in t.failures:
					print("FAIL  %s :: %s  —  %s" % [f.get_file(), m, msg])
			if t.has_method("teardown"):
				t.teardown()
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
