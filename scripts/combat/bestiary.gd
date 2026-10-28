class_name Bestiary
extends RefCounted
## Stat blocks for the first fight.


## Thomas as his growth makes him. Without a Progress, a Fury fresh from the war.
static func thomas(p: Progress = null) -> Combatant:
	if p == null:
		p = Progress.fury()
	var c := Combatant.new()
	c.name = "Thomas"
	c.team = "hero"
	c.kind = "hero"
	c.style = "thomas"
	c.max_stamina = p.max_stamina()
	c.stamina = c.max_stamina
	c.might = int(p.stats.might)
	c.speed = 5
	c.free_strike = 4
	c.basic = Abilities.heavy_blow()
	c.abilities = p.abilities()
	c.perks = p.perks()
	c.recoveries = 3
	c.recovery_value = 8
	return c


## Everything learned, for tests: all of the mace abilities and passives that work.
static func thomas_full() -> Combatant:
	var p := Progress.fury()
	for n in SkillTrees.maces():
		if n.ready and not p.owns("maces", n.id) and n.kind == "ability":
			p.owned.append("maces/" + n.id)
	var c := thomas(p)
	c.perks = []
	return c


static func drowned_miner() -> Combatant:
	var c := Combatant.new()
	c.name = "Drowned Miner"
	c.kind = "standard"
	c.style = "miner"
	c.max_stamina = 20
	c.stamina = 20
	c.might = 2
	c.speed = 4
	c.free_strike = 3
	c.basic = Abilities.pick_swing()
	c.big = Abilities.overhead_smash()
	return c


static func faithful() -> Combatant:
	var c := Combatant.new()
	c.name = "Faithful"
	c.kind = "minion"
	c.style = "faithful"
	c.max_stamina = 4
	c.stamina = 4
	c.might = 1
	c.speed = 5
	c.free_strike = 1
	c.basic = Abilities.clutch()
	return c
