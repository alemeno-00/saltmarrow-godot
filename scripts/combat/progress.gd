class_name Progress
extends RefCounted
## How far Thomas has grown in this life. Death wipes it.
##
## Level points come from experience and go to spell schools and the utility trees.
## Mastery points come from landing hits with a weapon type and only go into that weapon's tree.
## A weapon tree opens after OPEN_AT hits with it (or from its manual); a spell school only from its tome.

const OPEN_AT := 10
const HITS_PER_POINT := 8
const STATS := ["might", "agility", "reason", "intuition", "presence"]

var backstory := "fury"
var level := 1
var xp := 0
var level_points := 0
var stat_points := 0
var stats := {"might": 2, "agility": 1, "reason": 0, "intuition": 0, "presence": 1}
var hits := {}            # weapon tree -> hits landed
var mastery := {}         # weapon tree -> unspent mastery points
var open_trees: Array[String] = []
var owned: Array[String] = []   # "tree/node"


static func fury() -> Progress:
	var p := Progress.new()
	p.backstory = "fury"
	p.open_trees = ["maces"]
	p.owned = ["maces/skull_crack", "maces/weight_behind_it"]
	return p


## The Shadow (docs/story.md): a killer in the dark. Daggers, rolled with Agility.
static func shadow() -> Progress:
	var p := Progress.new()
	p.backstory = "shadow"
	p.stats = {"might": 1, "agility": 2, "reason": 0, "intuition": 1, "presence": 0}
	p.open_trees = ["daggers"]
	p.owned = ["daggers/backstab", "daggers/twin_fangs"]
	return p


## A fresh life with this backstory.
static func for_backstory(b: String) -> Progress:
	return shadow() if b == "shadow" else fury()


## The weapon tree this life fights with.
func weapon_tree() -> String:
	return SkillTrees.BACKSTORY_TREE.get(backstory, "maces")


## For testing: a Fury who has already lived through a lot. Every working mace skill, and the levels and stats to match.
static func veteran(to_level := 10) -> Progress:
	var p := fury()
	while p.level < to_level:
		p.add_xp(p.xp_needed() - p.xp)
	for n in SkillTrees.maces():
		if n.ready and not p.owns("maces", n.id):
			p.owned.append("maces/" + n.id)
	while p.stat_points > 0:
		p.raise_stat("might")
	p.hits["maces"] = 80
	return p


## Experience needed to reach the next level.
func xp_needed() -> int:
	return 5 * level * (level + 1) / 2


## Returns the number of levels gained.
func add_xp(n: int) -> int:
	xp += n
	var gained := 0
	while xp >= xp_needed():
		level += 1
		level_points += 1
		if level % 3 == 0:
			stat_points += 1
		gained += 1
	return gained


## A landed hit with a weapon tree. Returns "opened", "point" or "".
func add_hit(tree_id: String) -> String:
	if tree_id == "":
		return ""
	hits[tree_id] = int(hits.get(tree_id, 0)) + 1
	var h: int = hits[tree_id]
	if not open_trees.has(tree_id):
		if h >= OPEN_AT:
			open_trees.append(tree_id)
			return "opened"
		return ""
	if h % HITS_PER_POINT == 0:
		mastery[tree_id] = int(mastery.get(tree_id, 0)) + 1
		return "point"
	return ""


func owns(tree_id: String, node_id: String) -> bool:
	return owned.has(tree_id + "/" + node_id)


func points_for(tree_id: String) -> int:
	if SkillTrees.WEAPON_TREES.has(tree_id):
		return int(mastery.get(tree_id, 0))
	return level_points


## Empty if the node can be taken now, otherwise why not.
func cannot_take(tree_id: String, node_id: String) -> String:
	var n := SkillTrees.node(tree_id, node_id)
	if n.is_empty():
		return "No such skill."
	if owns(tree_id, node_id):
		return "Already learned."
	if not open_trees.has(tree_id):
		return "This tree isn't open yet."
	if not n.ready:
		return "Not in the game yet."
	if n.row > 1:
		var linked := false
		for need in n.needs:
			if owns(tree_id, need):
				linked = true
		if not linked:
			return "Learn a skill it connects to first."
	if points_for(tree_id) <= 0:
		return "No mastery points for this tree." if SkillTrees.WEAPON_TREES.has(tree_id) else "No level points."
	return ""


func take(tree_id: String, node_id: String) -> bool:
	if cannot_take(tree_id, node_id) != "":
		return false
	owned.append(tree_id + "/" + node_id)
	if SkillTrees.WEAPON_TREES.has(tree_id):
		mastery[tree_id] = int(mastery[tree_id]) - 1
	else:
		level_points -= 1
	return true


func raise_stat(stat: String) -> bool:
	if stat_points <= 0 or not STATS.has(stat):
		return false
	stats[stat] = int(stats[stat]) + 1
	stat_points -= 1
	return true


func max_stamina() -> int:
	return 24 + 3 * (level - 1)


## Passives Thomas has, by node id.
func perks() -> Array[String]:
	var out: Array[String] = []
	for o in owned:
		var parts := o.split("/")
		var n := SkillTrees.node(parts[0], parts[1])
		if not n.is_empty() and n.kind == "passive":
			out.append(n.id)
	return out


## Thomas's abilities: the basic attack, then every learned ability, in tree order.
func abilities() -> Array:
	var out: Array = [Abilities.basic_for(backstory)]
	for t in open_trees:
		for n in SkillTrees.tree(t):
			if n.kind == "ability" and owns(t, n.id):
				var ab := Abilities.by_id(n.id)
				if not ab.is_empty():
					out.append(ab)
	return out
