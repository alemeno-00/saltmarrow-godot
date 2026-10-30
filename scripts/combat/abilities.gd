class_name Abilities
extends RefCounted
## Ability data for the first fight. Numbers come from docs/trees.md.
## Each tier is a dictionary of effects: dmg, push, dazed (rounds), slowed (rounds), prone, crush.

static func _ab(id: String, name: String, cost: int, target: String, tiers: Array, part := "", injury := [0, 0, 0], needs := []) -> Dictionary:
	return {"id": id, "name": name, "cost": cost, "action": "main", "target": target, "range": 1,
		"tiers": tiers, "injury_part": part, "injury": injury, "needs": needs, "weapon": ""}


static func _mace(ab: Dictionary) -> Dictionary:
	ab.weapon = "mace"
	return ab


## Daggers are quick and light: rolled with Agility.
static func _dagger(ab: Dictionary) -> Dictionary:
	ab.weapon = "dagger"
	ab.stat = "agility"
	return ab


## Look up one of Thomas's abilities by id.
static func by_id(id: String) -> Dictionary:
	match id:
		"heavy_blow":
			return heavy_blow()
		"skull_crack":
			return skull_crack()
		"knee_breaker":
			return knee_breaker()
		"wide_arc":
			return wide_arc()
		"execution":
			return execution()
		"stab":
			return stab()
		"backstab":
			return backstab()
		"open_the_vein":
			return open_the_vein()
		"throw":
			return throw()
	return {}


## The basic attack for a backstory: Fury swings a maul, Shadow stabs.
static func basic_for(backstory: String) -> Dictionary:
	return stab() if backstory == "shadow" else heavy_blow()


# Thomas, daggers (docs/trees.md, Daggers)

static func stab() -> Dictionary:
	return _dagger(_ab("stab", "Stab", 0, "enemy", [{"dmg": 2}, {"dmg": 4}, {"dmg": 6}], "torso", [0, 5, 15]))


## Only against an enemy that is unaware of him (caught by surprise) or flanked.
static func backstab() -> Dictionary:
	return _dagger(_ab("backstab", "Backstab", 3, "enemy", [{"dmg": 4}, {"dmg": 7}, {"dmg": 11}], "torso", [10, 30, 50], ["unaware"]))


static func open_the_vein() -> Dictionary:
	return _dagger(_ab("open_the_vein", "Open the Vein", 3, "enemy", [{"dmg": 2}, {"dmg": 4, "bleed": 4}, {"dmg": 6, "bleed": 4}], "leg", [10, 25, 40]))


## Thrown up to 5 squares (7.5 m) at someone he can see. Outside a fight it is free: it puts out a lamp, or clatters
## off the stone to draw one enemy away.
static func throw() -> Dictionary:
	var ab := _dagger(_ab("throw", "Throw", 2, "enemy", [{"dmg": 2}, {"dmg": 4}, {"dmg": 7}], "leg", [0, 10, 20]))
	ab.range = 5
	return ab


# Thomas, maces

static func heavy_blow() -> Dictionary:
	return _mace(_ab("heavy_blow", "Heavy Blow", 0, "enemy", [{"dmg": 2}, {"dmg": 5}, {"dmg": 7, "push": 1}], "torso", [0, 0, 10]))


static func skull_crack() -> Dictionary:
	return _mace(_ab("skull_crack", "Skull Crack", 3, "enemy", [{"dmg": 3}, {"dmg": 5, "dazed": 1}, {"dmg": 8, "dazed": 1}], "head", [0, 15, 40]))


static func knee_breaker() -> Dictionary:
	return _mace(_ab("knee_breaker", "Knee Breaker", 3, "enemy", [{"dmg": 3, "slowed": 2}, {"dmg": 5, "slowed": 2}, {"dmg": 7, "prone": true}], "leg", [10, 30, 60]))


static func wide_arc() -> Dictionary:
	return _mace(_ab("wide_arc", "Wide Arc", 5, "adjacent_all", [{"dmg": 3, "push": 1}, {"dmg": 5, "push": 2}, {"dmg": 7, "push": 3}], "arm", [0, 10, 20]))


static func execution() -> Dictionary:
	return _mace(_ab("execution", "Execution", 7, "enemy", [{"dmg": 6}, {"dmg": 10}, {"dmg": 15, "crush": true}], "head", [30, 60, 100], ["dazed", "prone", "dying"]))


# Enemies

## A lurker's grab from the sewage: on a solid or strong hit it drags its victim down under the surface (prone: in
## deep sewage that means drowning every turn until he gets up).
static func drag_under() -> Dictionary:
	return _ab("drag_under", "Drag Under", 0, "enemy", [{"dmg": 3}, {"dmg": 5, "prone": true}, {"dmg": 7, "prone": true}], "leg", [0, 10, 25])


static func pick_swing() -> Dictionary:
	return _ab("pick_swing", "Pick Swing", 0, "enemy", [{"dmg": 3}, {"dmg": 5}, {"dmg": 8}], "torso", [0, 10, 20])


## Telegraphed: the miner raises the pick on one turn and brings it down on the next.
static func overhead_smash() -> Dictionary:
	return _ab("overhead_smash", "Overhead Smash", 0, "area", [{"dmg": 6, "prone": true}, {"dmg": 9, "prone": true}, {"dmg": 12, "prone": true}], "head", [10, 25, 50])


static func clutch() -> Dictionary:
	return _ab("clutch", "Clutching Hands", 0, "enemy", [{"dmg": 1}, {"dmg": 2}, {"dmg": 4}])


# Garrick, the First Shift (design/quick-specs/first-shift-boss-2026-10-29.md)

static func pick_and_chain() -> Dictionary:
	return _ab("pick_and_chain", "Pick and Chain", 0, "enemy", [{"dmg": 4}, {"dmg": 7}, {"dmg": 10}], "torso", [0, 10, 20])


## Telegraphed: the chain swings back on one turn and sweeps five squares across Thomas on the next.
static func lift_chain_sweep() -> Dictionary:
	var ab := _ab("lift_chain_sweep", "Lift-Chain Sweep", 0, "area", [{"dmg": 8, "prone": true}, {"dmg": 12, "prone": true}, {"dmg": 16, "prone": true}])
	ab.width = 2          # squares on each side of Thomas
	ab.reach = 2          # the chain reaches two squares
	ab.cooldown = 3
	ab.cooldown_hurt = 2  # at half Stamina or less
	ab.tell = "%s swings the chain back..."
	return ab


## The ability card: what every tier does.
static func describe(ab: Dictionary) -> String:
	var cost := "free" if int(ab.cost) == 0 else "%d Resolve" % int(ab.cost)
	var lines: Array[String] = ["%s   ·   %s   ·   main action" % [ab.name, cost]]
	if ab.target == "adjacent_all":
		lines.append("Every enemy next to you.")
	elif int(ab.get("range", 1)) > 1:
		lines.append("One enemy you can see, up to %d squares (%.1f m) away." % [int(ab.range), int(ab.range) * 1.5])
	else:
		lines.append("One enemy next to you.")
	if (ab.needs as Array).has("unaware"):
		lines.append("Only against an enemy caught unaware, or flanked.")
	elif not (ab.needs as Array).is_empty():
		lines.append("Only against a dazed, prone or dying enemy.")
	if ab.get("stat", "might") == "agility":
		lines.append("Rolled with Agility.")
	for i in 3:
		lines.append("%s:  %s" % [PowerRoll.BANDS[i], effect_text(ab.tiers[i])])
	if ab.injury_part != "":
		var inj: Array = ab.injury
		lines.append("%s injury: %d / %d / %d%%" % [String(ab.injury_part).capitalize(), inj[0], inj[1], inj[2]])
	return "\n".join(lines)


static func effect_text(t: Dictionary) -> String:
	var parts: Array[String] = []
	if t.has("dmg"):
		parts.append("%d damage" % int(t.dmg))
	if t.get("push", 0) > 0:
		parts.append("push %d" % int(t.push))
	if t.has("dazed"):
		parts.append("dazed")
	if t.has("slowed"):
		parts.append("slowed")
	if t.get("prone", false):
		parts.append("knocked prone")
	if t.has("bleed"):
		parts.append("heavy bleeding (%d a turn)" % int(t.bleed))
	if t.get("crush", false):
		parts.append("skull crushed (minions and standard enemies die)")
	return ", ".join(parts)
