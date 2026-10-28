class_name SkillTrees
extends RefCounted
## The skill trees as data. Only Maces is built so far; the rest are designed in docs/trees.md.
## A node can be taken once you own one of the nodes it `needs` (row 1 needs nothing).

const WEAPON_TREES := ["maces", "swords", "daggers", "flails", "spears", "staves"]
const SPELL_TREES := ["storm", "faith", "mind", "star"]
const NAMES := {"maces": "Maces", "swords": "Swords", "daggers": "Daggers", "flails": "Flails", "spears": "Spears", "staves": "Staves",
	"storm": "Storm", "faith": "Faith", "mind": "Mind", "star": "The Star"}


static func tree(id: String) -> Array:
	match id:
		"maces":
			return maces()
	return []


static func node(tree_id: String, node_id: String) -> Dictionary:
	for n in tree(tree_id):
		if n.id == node_id:
			return n
	return {}


static func _n(id: String, name: String, row: int, kind: String, needs: Array, text: String, ready := true) -> Dictionary:
	return {"id": id, "name": name, "row": row, "kind": kind, "needs": needs, "text": text, "ready": ready}


static func maces() -> Array:
	return [
		_n("skull_crack", "Skull Crack", 1, "ability", [], ""),
		_n("weight_behind_it", "Weight Behind It", 1, "passive", [], "Heavy Blow also pushes on a solid hit. Every push from a mace goes 1 square further. A creature you push into a wall or another creature takes 2 extra damage."),
		_n("knee_breaker", "Knee Breaker", 2, "ability", ["skull_crack", "weight_behind_it"], ""),
		_n("shatter", "Shatter", 2, "ability", ["weight_behind_it"], "Break the armour piece you hit. Comes with armour and items.", false),
		_n("bone_deep", "Bone-Deep", 2, "passive", ["skull_crack"], "+15% to all your mace injury chances. Every injury you cause also dazes for a round."),
		_n("wide_arc", "Wide Arc", 3, "ability", ["knee_breaker", "shatter"], ""),
		_n("ringing_blows", "Ringing Blows", 3, "passive", ["bone_deep", "knee_breaker"], "Your mace attacks against dazed enemies have an edge."),
		_n("sunder", "Sunder", 3, "passive", ["shatter"], "+2 damage against enemies with broken armour. Comes with armour and items.", false),
		_n("execution", "Execution", 4, "ability", ["wide_arc", "ringing_blows"], ""),
		_n("hammers_due", "The Hammer's Due", 4, "passive", ["wide_arc", "ringing_blows", "sunder"], "Capstone. Extra Resolve whenever you injure an enemy, or slam one into something."),
	]


## What a node says on its card.
static func describe(n: Dictionary) -> String:
	if n.kind == "ability":
		var ab := Abilities.by_id(n.id)
		if not ab.is_empty():
			return Abilities.describe(ab)
	return "%s   ·   passive\n%s" % [n.name, n.text]
