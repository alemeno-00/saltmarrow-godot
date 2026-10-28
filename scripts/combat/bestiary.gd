class_name Bestiary
extends RefCounted
## Stat blocks for the first fight.


## Thomas with a test kit: a Fury with a maul and five mace abilities.
static func thomas() -> Combatant:
	var c := Combatant.new()
	c.name = "Thomas"
	c.team = "hero"
	c.kind = "hero"
	c.style = "thomas"
	c.max_stamina = 24
	c.stamina = 24
	c.might = 2
	c.speed = 5
	c.free_strike = 4
	c.basic = Abilities.heavy_blow()
	c.abilities = [Abilities.heavy_blow(), Abilities.skull_crack(), Abilities.knee_breaker(), Abilities.wide_arc(), Abilities.execution()]
	c.recoveries = 3
	c.recovery_value = 8
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
