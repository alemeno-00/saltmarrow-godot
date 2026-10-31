class_name Journal
extends RefCounted
## Everything Thomas has read (room contents part 2): it survives death and every new life, as the story so far does
## (docs/story.md). Kept on disk at `path` (tests give their own path, so a test never touches the player's journal).
## Each entry keeps the words as he read them that life: a letter in that life's wording, a miner as he lay then.

const PATH := "user://journal.json"

var path := PATH
var entries: Array = []   # [{id, title, text}], in the order he read them


static func open(p := PATH) -> Journal:
	var j := Journal.new()
	j.path = p
	j._load()
	return j


func has(id: String) -> bool:
	return entries.any(func(e): return e.id == id)


## Add what he has just read. Returns false if it was already in the journal.
func add(id: String, title: String, text: String) -> bool:
	if has(id):
		return false
	entries.append({"id": id, "title": title, "text": text})
	_save()
	return true


## Forget everything (and the file): for tests and a fresh start.
func wipe() -> void:
	entries.clear()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _load() -> void:
	entries.clear()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary and d.get("entries") is Array:
		for e in d.entries:
			if e is Dictionary and e.has("id"):
				entries.append({"id": String(e.id), "title": String(e.get("title", "")), "text": String(e.get("text", ""))})


func _save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"entries": entries}, "\t"))
