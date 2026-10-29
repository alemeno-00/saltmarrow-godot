class_name Battle
extends RefCounted
## One fight under Draw Steel rules, on the level's grid.
## Pure logic with no drawing: every action returns a list of events for the view to play back.
##
## A round: Thomas takes his turn (move, maneuver, main action), then every enemy takes theirs.
## Thomas gains 2 Resolve at the start of each of his turns, and 1 more the first time he is hurt each round (Fury).
##
## The enemy side has Malice (Draw Steel's villain resource): it grows every round, and is spent on
## Swarming Hymn (the Faithful surge forward together) and Press the Attack (a standard enemy strikes twice).
## Enemies flank: an enemy directly opposite an ally across Thomas attacks with an edge.
## A badly hurt standard enemy breaks and runs; if it gets out of sight it escapes, and will come back.
## If no enemy can see Thomas at the end of their turns, twice in a row, he has lost them and the fight ends.

const TIER_WORDS := ["weak", "solid", "strong"]
const SIGHT := 7
const HYMN_COST := 4
const PRESS_COST := 5
const FLEE_AT := 0.3

var level: Level
var units: Array[Combatant] = []
var hero: Combatant
var round := 0
var active: Combatant
var budget := {"move": 0, "maneuver": 0, "main": 0}
var over := false
var winner := ""
var rng := RandomNumberGenerator.new()
var forced_rolls: Array = []   # queued [d1, d2] pairs, used by tests
var injuries_on := true
var malice := 0
var last_seen := Vector2i.ZERO
var bystanders: Array[Combatant] = []   # enemies on the level not in the fight; they join if they see Thomas
var hidden_rounds := 0   # enemy turns in a row that ended with no one seeing Thomas

var _ev: Array = []


func setup(l: Level, h: Combatant, enemies: Array, seed_value: int) -> void:
	level = l
	hero = h
	units = [h]
	for e in enemies:
		units.append(e)
	rng.seed = seed_value


## Draw Steel: roll a d10, 6 or more and the heroes go first.
func roll_initiative() -> bool:
	return rng.randi_range(1, 10) >= 6


func start(hero_first: bool) -> Array:
	_ev = []
	round = 1
	malice = 1
	last_seen = hero.cell
	for u in units:
		u.hurt_this_round = false
		u.free_strike_ready = true
	_emit({"t": "start", "hero_first": hero_first})
	_log("A fight! " + ("Thomas moves first." if hero_first else "They move first."))
	if hero_first:
		_begin_turn(hero)
	else:
		_enemy_phase()
	return _flush()


func is_hero_turn() -> bool:
	return not over and active == hero


# ---------------------------------------------------------------- queries

func occupant(c: Vector2i) -> Combatant:
	for u in units:
		if u.alive() and u.cell == c:
			return u
	return null


func enemies_of(u: Combatant) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for o in units:
		if o.alive() and o.team != u.team:
			out.append(o)
	return out


static func adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d := (a - b).abs()
	return maxi(d.x, d.y) == 1


static func dist(a: Vector2i, b: Vector2i) -> int:
	var d := (a - b).abs()
	return maxi(d.x, d.y)


## Squares a creature can walk to with `limit` squares of movement. Returns cell -> previous cell.
func reachable(u: Combatant, limit: int) -> Dictionary:
	var prev := {}
	if u.prone or limit <= 0:
		return prev
	var steps := {u.cell: 0}
	var queue: Array[Vector2i] = [u.cell]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if steps[c] >= limit:
			continue
		for d in Level.DIRS_8:
			var n: Vector2i = c + d
			if steps.has(n) or not level.can_step(c, d) or occupant(n) != null:
				continue
			steps[n] = steps[c] + 1
			prev[n] = c
			queue.append(n)
	return prev


static func path_to(prev: Dictionary, from: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var c := goal
	while c != from:
		out.push_front(c)
		c = prev[c]
	return out


func meets_needs(t: Combatant, ab: Dictionary) -> bool:
	var needs: Array = ab.needs
	if needs.is_empty():
		return true
	return (needs.has("dazed") and t.dazed > 0) or (needs.has("prone") and t.prone) or (needs.has("dying") and t.dying)


## Enemies this ability could hit right now.
func valid_targets(u: Combatant, ab: Dictionary) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for e in enemies_of(u):
		if adjacent(u.cell, e.cell) and (ab.target == "adjacent_all" or meets_needs(e, ab)):
			out.append(e)
	return out


## Empty if the ability can be used now, otherwise the reason it can't.
func cannot_use(u: Combatant, ab: Dictionary) -> String:
	if int(ab.cost) > u.resolve:
		return "Not enough Resolve."
	if budget[ab.action] <= 0:
		return "No main action left this turn."
	return ""


# ---------------------------------------------------------------- Thomas's actions

func hero_step(dir: Vector2i) -> Array:
	if not is_hero_turn() or budget.move <= 0 or hero.prone:
		return []
	var to := hero.cell + dir
	if not level.can_step(hero.cell, dir) or occupant(to) != null:
		return []
	_walk(hero, [to])
	return _flush()


func hero_move_to(c: Vector2i) -> Array:
	if not is_hero_turn():
		return []
	var prev := reachable(hero, budget.move)
	if not prev.has(c):
		return []
	_walk(hero, path_to(prev, hero.cell, c))
	return _flush()


func hero_ability(idx: int, target_cell: Vector2i) -> Array:
	if not is_hero_turn() or idx < 0 or idx >= hero.abilities.size():
		return []
	var ab: Dictionary = hero.abilities[idx]
	var why := cannot_use(hero, ab)
	if why != "":
		_log(why)
		return _flush()
	var targets: Array[Combatant] = []
	if ab.target == "adjacent_all":
		targets = valid_targets(hero, ab)
		if targets.is_empty():
			_log("No one is in reach.")
	else:
		var t := occupant(target_cell)
		if t == null or t.team == hero.team:
			_log("Choose an enemy.")
		elif not adjacent(hero.cell, t.cell):
			_log("Out of reach.")
		elif not meets_needs(t, ab):
			_log("Only against a dazed, prone or dying enemy.")
		else:
			targets = [t]
	if targets.is_empty():
		return _flush()
	if int(ab.cost) > 0:
		hero.resolve -= int(ab.cost)
		_emit({"t": "resolve", "value": hero.resolve})
	var crit := _attack(hero, ab, targets)
	_spend("main")
	if crit and not over and not hero.dead:
		budget.main += 1
		_log("A critical hit: Thomas may act again.")
	return _flush()


## Careful step (a maneuver): one square, without giving anyone a free strike.
func hero_shift(c: Vector2i) -> Array:
	if not is_hero_turn() or hero.prone or budget.maneuver <= 0:
		return []
	var d := c - hero.cell
	if not adjacent(c, hero.cell) or not level.can_step(hero.cell, d) or occupant(c) != null:
		return []
	if level.get_tile(c) == Level.Tile.DOOR_CLOSED:
		level.set_tile(c, Level.Tile.DOOR_OPEN)
		_emit({"t": "door", "cell": c})
	hero.cell = c
	_emit({"t": "move", "unit": hero, "to": c})
	_spend("maneuver")
	return _flush()


func shift_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not is_hero_turn() or hero.prone or budget.maneuver <= 0:
		return out
	for d in Level.DIRS_8:
		if level.can_step(hero.cell, d) and occupant(hero.cell + d) == null:
			out.append(hero.cell + d)
	return out


func hero_stand() -> Array:
	if not is_hero_turn() or not hero.prone or budget.maneuver <= 0:
		return []
	hero.prone = false
	_emit({"t": "stand", "unit": hero})
	_log("Thomas gets to his feet.")
	_spend("maneuver")
	return _flush()


## Spend a Recovery to get some Stamina back. Uses the main action.
func hero_catch_breath() -> Array:
	if not is_hero_turn():
		return []
	if budget.main <= 0:
		_log("No main action left this turn.")
		return _flush()
	if hero.recoveries <= 0:
		_log("Thomas has nothing left to draw on.")
		return _flush()
	hero.recoveries -= 1
	hero.stamina = mini(hero.max_stamina, hero.stamina + hero.recovery_value)
	if hero.stamina > 0 and hero.dying:
		hero.dying = false
	_emit({"t": "heal", "unit": hero})
	_log("Thomas catches his breath.")
	_spend("main")
	return _flush()


func hero_end_turn() -> Array:
	if not is_hero_turn():
		return []
	_end_turn(hero)
	_enemy_phase()
	return _flush()


# ---------------------------------------------------------------- turns

func _begin_turn(u: Combatant) -> void:
	active = u
	budget = {"move": u.move_speed(), "maneuver": 1, "main": 1}
	_emit({"t": "turn", "unit": u})
	if u == hero:
		u.resolve += 2
		_emit({"t": "resolve", "value": u.resolve})
	u.big_cooldown = maxi(0, u.big_cooldown - 1)
	if u.bleeding or (u.dying and u == hero):
		_log("%s bleeds." % u.name)
		_damage(u, 2, false, 1)


func _end_turn(u: Combatant) -> void:
	if u.dazed > 0:
		u.dazed -= 1
	if u.slowed > 0:
		u.slowed -= 1
	_emit({"t": "status", "unit": u})


## Dazed creatures get only one of move, maneuver or main action.
func _spend(kind: String) -> void:
	if kind != "move":
		budget[kind] -= 1
	if active != null and active.dazed > 0:
		for k in budget:
			if k != kind:
				budget[k] = 0
		if kind != "move":
			budget.move = 0


func _enemy_phase() -> void:
	malice += 1 + floori(round / 2.0)
	_emit({"t": "malice", "value": malice})
	for o in bystanders.duplicate():
		if o.alive() and (sees_hero(o) or dist(o.cell, hero.cell) <= 3):
			bystanders.erase(o)
			units.append(o)
			_emit({"t": "join", "unit": o})
			_log("A %s hears the fight and comes." % o.name)
	_swarming_hymn()
	for e in units.duplicate():
		if over:
			return
		if e.team == hero.team or not e.alive():
			continue
		_begin_turn(e)
		if e.alive() and not over:
			_enemy_act(e)
		_end_turn(e)
	if over:
		return
	hidden_rounds = hidden_rounds + 1 if _hero_hidden() else 0
	if hidden_rounds >= 2:
		over = true
		winner = "escaped"
		_log("Nothing can see Thomas. He has lost them, for now.")
		_emit({"t": "end", "winner": winner})
		return
	round += 1
	for u in units:
		u.hurt_this_round = false
		u.free_strike_ready = true
	_begin_turn(hero)


func _enemy_act(e: Combatant) -> void:
	if e.kind == "standard" and not e.fleeing and not e.fled_once and e.health_ratio() <= FLEE_AT and not hero.dying:
		e.fleeing = true
		e.fled_once = true
		_cancel_telegraph(e, "breaking")
		_emit({"t": "flee", "unit": e})
		_log("The %s breaks and runs." % e.name)
	if e.fleeing:
		_flee(e)
		return
	if not e.telegraph.is_empty():
		_big_attack(e)
		_spend("main")
		return
	if e.prone:
		e.prone = false
		_emit({"t": "stand", "unit": e})
		_log("The %s gets up." % e.name)
		_spend("maneuver")
	if hero.dead or over:
		return
	if sees_hero(e):
		last_seen = hero.cell
	var goal := hero.cell if sees_hero(e) or dist(e.cell, hero.cell) <= 2 else last_seen
	if not adjacent(e.cell, hero.cell) and budget.move > 0:
		_approach(e, budget.move, goal)
		if not e.alive() or over:
			return
	if adjacent(e.cell, hero.cell) and budget.main > 0:
		if not e.big.is_empty() and e.big_cooldown <= 0:
			e.telegraph = _big_cells(e)
			e.big_cooldown = 3
			_emit({"t": "telegraph", "unit": e, "cells": e.telegraph.duplicate()})
			_log("The %s raises its pick high..." % e.name)
		else:
			_attack(e, e.basic, [hero])
			if e.kind == "standard" and malice >= PRESS_COST and not over and not hero.dead and adjacent(e.cell, hero.cell):
				malice -= PRESS_COST
				_emit({"t": "malice_spend", "name": "Press the Attack", "value": malice})
				_log("Malice: the %s presses the attack." % e.name)
				_attack(e, e.basic, [hero])
		_spend("main")


func sees_hero(e: Combatant) -> bool:
	return dist(e.cell, hero.cell) <= SIGHT and level.line_of_sight(e.cell, hero.cell)


func _hero_hidden() -> bool:
	for e in enemies_of(hero):
		if sees_hero(e) or dist(e.cell, hero.cell) <= 2:
			return false
	return true


## Is `c` directly opposite one of e's allies, across Thomas? Standing there flanks him.
func _flanks(e: Combatant, c: Vector2i) -> bool:
	if not adjacent(c, hero.cell):
		return false
	var opposite := hero.cell * 2 - c
	var o := occupant(opposite)
	return o != null and o != e and o.team == e.team


## Walk up to `limit` squares toward `goal`, preferring squares beside Thomas that flank him.
func _approach(e: Combatant, limit: int, goal: Vector2i) -> void:
	var prev := reachable(e, limit)
	var best := e.cell
	var best_score := dist(e.cell, goal) * 100
	for c in prev:
		var score := dist(c, goal) * 100 + path_to(prev, e.cell, c).size()
		if goal == hero.cell and _flanks(e, c):
			score -= 60
		if score < best_score:
			best_score = score
			best = c
	if best != e.cell:
		_walk(e, path_to(prev, e.cell, best))


## Malice: when there are at least two Faithful and some aren't yet beside Thomas, they all surge up to 2 squares.
func _swarming_hymn() -> void:
	var flock: Array[Combatant] = []
	var far := false
	for u in enemies_of(hero):
		if u.style == "faithful":
			flock.append(u)
			if not adjacent(u.cell, hero.cell):
				far = true
	if flock.size() < 2 or not far or malice < HYMN_COST:
		return
	malice -= HYMN_COST
	_emit({"t": "malice_spend", "name": "Swarming Hymn", "value": malice})
	_log("Malice: the Faithful sing, and surge forward together.")
	for f in flock:
		if over:
			return
		if f.alive() and not f.prone and not adjacent(f.cell, hero.cell):
			_approach(f, 2, hero.cell)


## Run: as far from Thomas as it can get, out of his sight if possible. Out of sight and far enough, it escapes.
func _flee(e: Combatant) -> void:
	if e.prone:
		e.prone = false
		_emit({"t": "stand", "unit": e})
		_spend("maneuver")
	if budget.move > 0:
		var prev := reachable(e, budget.move)
		var best := e.cell
		var best_score := _flee_score(e.cell)
		for c in prev:
			var score := _flee_score(c)
			if score > best_score:
				best_score = score
				best = c
		if best != e.cell:
			_walk(e, path_to(prev, e.cell, best))
	if not e.alive() or over:
		return
	var d := dist(e.cell, hero.cell)
	if d > SIGHT or (d >= 4 and not level.line_of_sight(e.cell, hero.cell)):
		e.fled = true
		e.fleeing = false
		_emit({"t": "escape", "unit": e})
		_log("The %s limps away into the dark. It will be back." % e.name)
		_check_over()


func _flee_score(c: Vector2i) -> int:
	return dist(c, hero.cell) * 10 + (15 if not level.line_of_sight(c, hero.cell) else 0)


## The squares a telegraphed blow will land on: where Thomas stands and either side of him.
func _big_cells(e: Combatant) -> Array[Vector2i]:
	var dir := hero.cell - e.cell
	var side := Vector2i(-dir.y, dir.x)
	var out: Array[Vector2i] = []
	for c in [hero.cell, hero.cell + side, hero.cell - side]:
		if level.is_walkable(c) and c != e.cell:
			out.append(c)
	return out


func _big_attack(e: Combatant) -> void:
	var cells := e.telegraph.duplicate()
	e.telegraph.clear()
	_emit({"t": "telegraph_end", "unit": e})
	var reach := false
	for c in cells:
		if adjacent(e.cell, c):
			reach = true
	if not reach:
		_log("The %s's blow comes down on empty stone." % e.name)
		return
	_emit({"t": "smash", "unit": e, "cells": cells})
	var targets: Array[Combatant] = []
	for c in cells:
		var o := occupant(c)
		if o != null and o != e:
			targets.append(o)
	if targets.is_empty():
		_log("The pick bites into the floor where Thomas stood.")
		return
	_attack(e, e.big, targets)


func _cancel_telegraph(t: Combatant, why: String) -> void:
	if t.telegraph.is_empty():
		return
	t.telegraph.clear()
	_emit({"t": "telegraph_end", "unit": t})
	_log("The %s is %s; its swing is broken." % [t.name, why])


# ---------------------------------------------------------------- movement

func _walk(u: Combatant, path: Array) -> void:
	var first := true
	for nxt in path:
		if u.dead or over:
			return
		if first and u == active:
			_spend("move")
			first = false
		var from := u.cell
		for e in enemies_of(u):
			if e.free_strike_ready and not e.prone and e.dazed == 0 and adjacent(e.cell, from) and not adjacent(e.cell, nxt):
				e.free_strike_ready = false
				_emit({"t": "attack", "unit": e, "target": u})
				_log("%s strikes as %s pulls away." % [e.name, u.name])
				_damage(u, e.free_strike, false, 1)
				if u.dead or over:
					return
		if level.get_tile(nxt) == Level.Tile.DOOR_CLOSED:
			level.set_tile(nxt, Level.Tile.DOOR_OPEN)
			_emit({"t": "door", "cell": nxt})
		u.cell = nxt
		if u == active:
			budget.move -= 1
		_emit({"t": "move", "unit": u, "to": nxt})


## Forced movement straight away from `from`. Hitting a wall or a creature hurts: 1 damage per square left.
func _push(t: Combatant, from: Vector2i, n: int, pusher: Combatant = null) -> void:
	var dir := Vector2i(signi(t.cell.x - from.x), signi(t.cell.y - from.y))
	if dir == Vector2i.ZERO or n <= 0:
		return
	var path: Array[Vector2i] = []
	var slam := 0
	var other: Combatant = null
	for i in n:
		var nxt := t.cell + dir
		var o := occupant(nxt)
		if level.can_step(t.cell, dir) and o == null and level.get_tile(nxt) != Level.Tile.DOOR_CLOSED:
			t.cell = nxt
			path.append(nxt)
		else:
			slam = n - i
			other = o
			break
	if not path.is_empty():
		_emit({"t": "push", "unit": t, "path": path})
		_cancel_telegraph(t, "knocked off balance")
	if slam > 0:
		_emit({"t": "slam", "unit": t, "cell": t.cell + dir})
		if other != null:
			_log("The %s is slammed into the %s." % [t.name, other.name])
		else:
			_log("The %s is slammed into the wall." % t.name)
		if pusher != null and pusher.perks.has("weight_behind_it"):
			slam += 2
		_damage(t, slam, false, 1)
		if other != null:
			_damage(other, slam, false, 1)
		if pusher != null:
			_hammers_due(pusher, "slam")


# ---------------------------------------------------------------- attacks and damage

func _roll(bonus: int, edges: int) -> Dictionary:
	var d1: int
	var d2: int
	if not forced_rolls.is_empty():
		var f: Array = forced_rolls.pop_front()
		d1 = f[0]
		d2 = f[1]
	else:
		d1 = rng.randi_range(1, 10)
		d2 = rng.randi_range(1, 10)
	return PowerRoll.resolve(d1, d2, bonus, edges)


## One power roll applied to every target. Returns true on a crit.
func _attack(u: Combatant, ab: Dictionary, targets: Array) -> bool:
	var edges := 0
	if u.prone:
		edges -= 1
	if u.injuries.has("arm"):
		edges -= 1
	if targets.size() == 1 and targets[0].prone:
		edges += 1
	if targets.size() == 1 and targets[0].dazed > 0 and u.perks.has("ringing_blows") and ab.get("weapon", "") == "mace":
		edges += 1
	if targets.size() == 1 and u.team != hero.team and _flanks(u, u.cell) and targets[0] == hero:
		edges += 1
	var r := _roll(u.might, edges)
	_emit({"t": "roll", "unit": u, "ability": ab, "roll": r})
	var mod := ""
	if r.edges > 0:
		mod = " with an edge"
	elif r.edges < 0:
		mod = " with a bane"
	_log("%s: %s%s, %d. %s%s." % [u.name, ab.name, mod, r.total, "CRITICAL, " if r.crit else "", TIER_WORDS[r.tier - 1]])
	for t in targets:
		if t.dead or over:
			continue
		_hit(u, t, ab, r)
	return r.crit


func _hit(u: Combatant, t: Combatant, ab: Dictionary, r: Dictionary) -> void:
	var eff: Dictionary = (ab.tiers[r.tier - 1] as Dictionary).duplicate()
	var mace: bool = ab.get("weapon", "") == "mace"
	if mace and u.perks.has("weight_behind_it"):
		if ab.id == "heavy_blow" and r.tier == 2:
			eff.push = 1
		if int(eff.get("push", 0)) > 0:
			eff.push = int(eff.push) + 1
	_emit({"t": "attack", "unit": u, "target": t})
	if u == hero and ab.get("weapon", "") != "":
		_emit({"t": "landed", "weapon": ab.weapon})
	if eff.get("crush", false) and (t.kind == "minion" or t.kind == "standard"):
		t.crushed = true
		_emit({"t": "hit", "unit": t, "dmg": maxi(1, t.stamina), "crit": true, "tier": 3})
		_log("The %s's skull gives way." % t.name)
		_kill(t)
		return
	_damage(t, int(eff.get("dmg", 0)), r.crit, r.tier)
	if t.dead:
		return
	if eff.has("dazed"):
		t.dazed = maxi(t.dazed, int(eff.dazed))
		_log("The %s reels, dazed." % t.name if t != hero else "Thomas reels, dazed.")
	if eff.has("slowed"):
		t.slowed = maxi(t.slowed, int(eff.slowed))
	if eff.get("prone", false) and not t.prone:
		t.prone = true
		_emit({"t": "prone", "unit": t})
		_log("%s goes down." % ("Thomas" if t == hero else "The " + t.name))
		_cancel_telegraph(t, "knocked down")
	if int(eff.get("push", 0)) > 0:
		_push(t, u.cell, int(eff.push), u)
	if injuries_on and ab.injury_part != "" and not t.dead:
		var chance: int = (ab.injury as Array)[r.tier - 1]
		if mace and u.perks.has("bone_deep") and chance > 0:
			chance += 15
		if chance > 0 and rng.randi_range(1, 100) <= chance:
			_injure(t, ab.injury_part)
			if not t.dead and mace and u.perks.has("bone_deep"):
				t.dazed = maxi(t.dazed, 1)
			_hammers_due(u, "injury")


## Capstone: extra Resolve when Thomas injures an enemy or slams one into something.
func _hammers_due(u: Combatant, why: String) -> void:
	if u != hero or not u.perks.has("hammers_due"):
		return
	u.resolve += 1
	_emit({"t": "resolve", "value": u.resolve})
	_log("The Hammer's Due: +1 Resolve.")


func _damage(t: Combatant, dmg: int, crit: bool, tier: int) -> void:
	if dmg <= 0 or t.dead:
		return
	var excess := 0
	if t.kind == "minion" and dmg > t.stamina:
		excess = dmg - t.stamina
	t.stamina -= dmg
	_emit({"t": "hit", "unit": t, "dmg": dmg, "crit": crit, "tier": tier})
	if t == hero:
		if not t.hurt_this_round:
			t.hurt_this_round = true
			t.resolve += 1
			_emit({"t": "resolve", "value": t.resolve})
		if t.stamina <= -t.max_stamina / 2:
			_kill(t)
		elif t.stamina <= 0 and not t.dying:
			t.dying = true
			_emit({"t": "dying", "unit": t})
			_log("Thomas is dying. Catch your breath, or finish this quickly.")
	elif t.stamina <= 0:
		_kill(t)
	if excess > 0:
		for o in units:
			if o != t and o.alive() and o.kind == "minion" and o.team == t.team and adjacent(o.cell, t.cell):
				_log("The blow carries on into another of them.")
				_damage(o, excess, false, tier)
				break


func _injure(t: Combatant, part: String) -> void:
	if t.dead or t.injuries.has(part):
		return
	t.injuries.append(part)
	if part == "head":
		t.dazed = maxi(t.dazed, 1)
	elif part == "torso":
		t.bleeding = true
	_emit({"t": "injury", "unit": t, "part": part})
	var what: String = {"head": "a head wound", "arm": "a broken arm", "leg": "a broken leg", "torso": "a deep, bleeding wound"}[part]
	_log("%s suffers %s." % ["Thomas" if t == hero else "The " + t.name, what])


func _kill(t: Combatant) -> void:
	if t.dead:
		return
	t.dead = true
	t.telegraph.clear()
	_emit({"t": "death", "unit": t, "crushed": t.crushed})
	if t == hero:
		_log("Thomas Wren is dead.")
	else:
		_log("The %s is dead." % t.name)
	_check_over()


func _check_over() -> void:
	if over:
		return
	if hero.dead:
		over = true
		winner = "enemies"
	elif enemies_of(hero).is_empty():
		over = true
		winner = "hero"
		_log("The fight is over.")
	if over:
		_emit({"t": "end", "winner": winner})


# ---------------------------------------------------------------- events

func _emit(d: Dictionary) -> void:
	_ev.append(d)


func _log(text: String) -> void:
	_emit({"t": "log", "text": text})


func _flush() -> Array:
	var e := _ev
	_ev = []
	return e
