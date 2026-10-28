class_name TestBase
extends RefCounted

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func eq(a, b, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])
