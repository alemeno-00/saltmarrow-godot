class_name Battle
extends RefCounted
## One fight under Draw Steel rules, measured in metres (design/quick-specs/free-movement-2026-10-30.md, phase B).
## Pure logic with no drawing: every action returns a list of events for the view to play back.
##
## Everyone stands where they are (Combatant.pos, in pixels; one 32 px square is 1.5 m). Movement is a budget in
## metres along routes that go round walls and bodies; water costs double. Reach is measured edge to edge between
## bodies. Big blows land on a band drawn on the floor. Pushes slide along the line of the blow.
##
## A round: Thomas takes his turn (move, maneuver, main action), then every enemy takes theirs.
## Thomas gains 2 Resolve at the start of each of his turns, and 1 more the first time he is hurt each round (Fury).
##
## The enemy side has Malice (Draw Steel's villain resource): it grows every round, and is spent on
## Swarming Hymn (the Faithful surge forward together) and Press the Attack (a standard enemy strikes twice).
## Enemies flank: an enemy on the far side of Thomas from an ally attacks with an edge.
## Attacked from hiding, the enemies who hadn't spotted Thomas are surprised for the first round: no free strikes,
## and attacks against them have an edge.
## A badly hurt standard enemy breaks and runs; if it gets out of sight it escapes, and will come back.
## If no enemy can see Thomas at the end of their turns, twice in a row, he has lost them and the fight ends.

const TIER_WORDS := ["weak", "solid", "strong"]
const HYMN_COST := 4
const PRESS_COST := 5
const FLEE_AT := 0.3
const SQ := MovementRules.METRES_PER_SQUARE   # one square of Draw Steel distance, in metres
const HYMN_SURGE := 2                          # squares the Faithful surge with the Swarming Hymn
# The First Shift (design/quick-specs/first-shift-boss-2026-10-29.md)
const SLUICE_COST := 4      # Malice to reopen a sluice gate
const DROWN_DAMAGE := 2     # starting a turn prone in water
const WATER_CAP := 0.6      # water stops rising once it covers this much of the arena

var level: Level
var units: Array[Combatant] = []
var hero: Combatant
var round := 0
var active: Combatant
var budget := {"move": 0.0, "maneuver": 0, "main": 0}   # move in metres
var over := false
var winner := ""
var rng := RandomNumberGenerator.new()
var forced_rolls: Array = []   # queued [d1, d2] pairs, used by tests
var injuries_on := true
var malice := 0
var last_seen := Vector2.ZERO  # where the enemies last saw Thomas, in pixels
var bystanders: Array[Combatant] = []   # enemies on the level not in the fight; they join if they see Thomas
var hidden_rounds := 0   # enemy turns in a row that ended with no one seeing Thomas
var arena := Rect2i()    # the Outflow, when this is the boss fight: water rises here while a gate is open

var _ev: Array = []


func setup(l: Level, h: Combatant, enemies: Array, seed_value: int) -> void:
	level = l
	hero = h
	units = [h]
	for e in enemies:
		units.append(e)
	rng.seed = seed_value
	_settle()


## Bodies that overlap where the fight started are nudged apart (and out of walls); Thomas stays put.
func _settle() -> void:
	for u in units:
		if u == hero:
			continue
		u.pos = MovementRules.push_out(level, u.pos, u.radius(), bodies_except(u))


## Draw Steel: roll a d10, 6 or more and the heroes go first.
func roll_initiative() -> bool:
	return rng.randi_range(1, 10) >= 6


func start(hero_first: bool) -> Array:
	_ev = []
	round = 1
	malice = 1
	last_seen = hero.pos
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


# ---------------------------------------------------------------- distances and bodies

## Squares apart, counting diagonals as one (for the level's squares, not for fight rules).
static func dist(a: Vector2i, b: Vector2i) -> int:
	var d := (a - b).abs()
	return maxi(d.x, d.y)


static func adjacent(a: Vector2i, b: Vector2i) -> bool:
	return dist(a, b) == 1


## Metres between two creatures' bodies, edge to edge.
static func gap(a: Combatant, b: Combatant) -> float:
	return MovementRules.metres(a.pos.distance_to(b.pos) - a.radius() - b.radius())


## Is `b` within `a`'s reach (in squares of Draw Steel distance: reach 1 is 1.5 m, edge to edge)?
static func in_reach(a: Combatant, b: Combatant, reach := 1.0) -> bool:
	return gap(a, b) <= reach * SQ + 0.001


## The same, as if `a` stood at `at`.
static func in_reach_from(a: Combatant, at: Vector2, b: Combatant, reach := 1.0) -> bool:
	return MovementRules.metres(at.distance_to(b.pos) - a.radius() - b.radius()) <= reach * SQ + 0.001


static func reach_of(ab: Dictionary) -> float:
	return float(ab.get("reach", ab.get("range", 1)))


## The creature standing in square `c`, if any.
func occupant(c: Vector2i) -> Combatant:
	for u in units:
		if u.alive() and u.cell == c:
			return u
	return null


## The creature whose body is under point `p` (a click), if any.
func unit_at(p: Vector2) -> Combatant:
	var best: Combatant = null
	var best_d := INF
	for u in units:
		var d := u.pos.distance_to(p)
		if u.alive() and d <= u.radius() + 8.0 and d < best_d:
			best = u
			best_d = d
	return best


func enemies_of(u: Combatant) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for o in units:
		if o.alive() and o.team != u.team:
			out.append(o)
	return out


## Every other living body in the fight, as [centre, radius] (what a route must go round).
func bodies_except(u: Combatant) -> Array:
	var out: Array = []
	for o in units:
		if o != u and o.alive():
			out.append([o.pos, o.radius()])
	return out


## The route `u` would walk to `to`, round walls and bodies; empty if there is none.
func plan(u: Combatant, to: Vector2) -> Array[Vector2]:
	return MovementRules.route(level, u.pos, to, u.radius(), bodies_except(u))


## Metres of movement a route costs `u`.
func cost(u: Combatant, points: Array[Vector2]) -> float:
	return MovementRules.route_cost(level, u.pos, points, u.wades)


## What moving Thomas toward `to` would do, for the route preview: the whole route, the part his movement pays for,
## its cost, and the enemies who would get a free strike as he leaves their reach.
func move_preview(to: Vector2) -> Dictionary:
	var out := {"points": [] as Array[Vector2], "reach": [] as Array[Vector2], "cost": 0.0, "strikes": [] as Array[Combatant]}
	if not is_hero_turn() or hero.prone:
		return out
	var dest := MovementRules.push_out(level, to, hero.radius(), bodies_except(hero))
	var pts := plan(hero, dest)
	out.points = pts
	out.cost = cost(hero, pts)
	out.reach = MovementRules.trim(level, hero.pos, pts, hero.wades, budget.move)
	out.strikes = _free_strikers(hero, out.reach)
	return out


## The enemies who would strike `u` as it walks `points` and leaves their reach.
func _free_strikers(u: Combatant, points: Array[Vector2]) -> Array[Combatant]:
	var out: Array[Combatant] = []
	var at := u.pos
	for p in _samples(u.pos, points):
		for e in enemies_of(u):
			if not out.has(e) and _may_strike(e) and in_reach_from(u, at, e) and not in_reach_from(u, p, e):
				out.append(e)
		at = p
	return out


## A route broken into small steps (about 4 px), for free strikes, doors and costs along the way.
static func _samples(from: Vector2, points: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var at := from
	for p in points:
		var n := maxi(1, ceili(at.distance_to(p) / 4.0))
		for i in n:
			out.append(at.lerp(p, float(i + 1) / n))
		at = p
	return out


func _may_strike(e: Combatant) -> bool:
	return e.free_strike_ready and not e.prone and e.dazed == 0 and not e.surprised


func meets_needs(t: Combatant, ab: Dictionary) -> bool:
	var needs: Array = ab.needs
	if needs.is_empty():
		return true
	return (needs.has("dazed") and t.dazed > 0) or (needs.has("prone") and t.prone) or (needs.has("dying") and t.dying)


## Enemies this ability could hit right now.
func valid_targets(u: Combatant, ab: Dictionary) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for e in enemies_of(u):
		if in_reach(u, e, reach_of(ab)) and (ab.target == "adjacent_all" or meets_needs(e, ab)):
			out.append(e)
	return out


## Empty if the ability can be used now, otherwise the reason it can't.
func cannot_use(u: Combatant, ab: Dictionary) -> String:
	if int(ab.cost) > u.resolve:
		return "Not enough Resolve."
	if budget[ab.action] <= 0:
		return "No main action left this turn."
	return ""


# ---------------------------------------------------------------- big blows: a band on the floor

## The band a big blow will land on: across where Thomas stands, 1.5 m deep and as wide as `width` squares either
## side of him (1 unless the blow says), facing the way the blow comes from.
func band(e: Combatant) -> Dictionary:
	var dir := hero.pos - e.pos
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var w := int(e.big.get("width", 1))
	return {"centre": hero.pos, "dir": dir, "half_w": MovementRules.px((2 * w + 1) * SQ / 2.0), "half_d": MovementRules.px(SQ / 2.0)}


## Does a body of radius `r` at `p` touch the band?
static func in_band(b: Dictionary, p: Vector2, r := 0.0) -> bool:
	var local := p - (b.centre as Vector2)
	var dir: Vector2 = b.dir
	var q := Vector2(local.dot(dir), local.dot(dir.orthogonal()))
	var near := Vector2(clampf(q.x, -b.half_d, b.half_d), clampf(q.y, -b.half_w, b.half_w))
	return q.distance_to(near) <= r + 0.001


## Metres from a body to the nearest edge of a band (0 if it touches).
static func band_gap(b: Dictionary, u: Combatant) -> float:
	var local := u.pos - (b.centre as Vector2)
	var dir: Vector2 = b.dir
	var q := Vector2(local.dot(dir), local.dot(dir.orthogonal()))
	var near := Vector2(clampf(q.x, -b.half_d, b.half_d), clampf(q.y, -b.half_w, b.half_w))
	return maxf(0.0, MovementRules.metres(q.distance_to(near) - u.radius()))


# ---------------------------------------------------------------- Thomas's actions

## Step one square's length in a direction (the keys, in a fight).
func hero_step(dir: Vector2i) -> Array:
	if not is_hero_turn() or budget.move <= 0.0 or hero.prone:
		return []
	var to := hero.pos + Vector2(dir) * MovementRules.TILE
	if not level.is_walkable(MovementRules.cell_of(to)):
		return []
	return hero_move_to_point(to)


## The keys in a fight: a short straight step toward a point, sliding along walls, as far as his movement pays for.
func hero_nudge(to: Vector2) -> Array:
	if not is_hero_turn() or hero.prone or budget.move <= 0.0:
		return []
	var dest := MovementRules.slide(level, hero.pos, to - hero.pos, hero.radius(), bodies_except(hero))
	if dest.distance_to(hero.pos) < 0.05:
		return []
	var pts := MovementRules.trim(level, hero.pos, [dest] as Array[Vector2], hero.wades, budget.move)
	if pts.is_empty():
		return []
	_walk(hero, pts)
	return _flush()


func hero_move_to(c: Vector2i) -> Array:
	return hero_move_to_point(MovementRules.centre(c))


## Walk toward a point, as far as his movement reaches.
func hero_move_to_point(to: Vector2) -> Array:
	if not is_hero_turn() or hero.prone or budget.move <= 0.0:
		return []
	var dest := MovementRules.push_out(level, to, hero.radius(), bodies_except(hero))
	var pts := MovementRules.trim(level, hero.pos, plan(hero, dest), hero.wades, budget.move)
	if pts.is_empty():
		return []
	_walk(hero, pts)
	return _flush()


## Click an enemy out of reach: walk up to it (if his movement gets him there), then strike with the ability.
func hero_close_and_strike(idx: int, t: Combatant) -> Array:
	if not is_hero_turn() or t == null or t.team == hero.team:
		return []
	if not in_reach(hero, t, reach_of(hero.abilities[idx])):
		var spot := _spot_beside(hero, t, budget.move)
		if spot.is_empty():
			_log("Too far to reach this turn.")
			return _flush()
		_walk(hero, spot)
		if over or hero.dead:
			return _flush()
	var ev := _flush()
	ev.append_array(hero_ability_on(idx, t))
	return ev


## Use an ability on the creature in square `c` (or on everyone in reach, for those that hit all).
func hero_ability(idx: int, c: Vector2i) -> Array:
	return hero_ability_on(idx, occupant(c))


func hero_ability_on(idx: int, t: Combatant) -> Array:
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
		if t == null or t.team == hero.team or not t.alive():
			_log("Choose an enemy.")
		elif not in_reach(hero, t, reach_of(ab)):
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


## Careful step (a maneuver): up to 1.5 m in a straight line, without giving anyone a free strike.
func hero_shift(c: Vector2i) -> Array:
	return hero_shift_to(MovementRules.centre(c))


func hero_shift_to(to: Vector2) -> Array:
	if not can_shift():
		return []
	var dest := MovementRules.push_out(level, to, hero.radius(), bodies_except(hero))
	if dest.distance_to(hero.pos) > MovementRules.px(MovementRules.SHIFT) + 0.5:
		dest = hero.pos + (dest - hero.pos).normalized() * MovementRules.px(MovementRules.SHIFT)
	if dest.distance_to(hero.pos) < 1.0 or not MovementRules.clear_walk(level, hero.pos, dest, hero.radius(), bodies_except(hero)):
		return []
	_open_doors_on(hero, [dest] as Array[Vector2])
	hero.pos = dest
	_emit({"t": "move", "unit": hero, "points": [dest] as Array[Vector2], "to": hero.cell})
	_spend("maneuver")
	return _flush()


func can_shift() -> bool:
	return is_hero_turn() and not hero.prone and budget.maneuver > 0


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


## Is Thomas within reach of square `c` (a gate in the wall)?
func _reaches_square(u: Combatant, c: Vector2i) -> bool:
	var box := Rect2(Vector2(c * MovementRules.TILE), Vector2(MovementRules.TILE, MovementRules.TILE))
	return MovementRules.metres(u.pos.distance_to(u.pos.clamp(box.position, box.end)) - u.radius()) <= SQ + 0.001


## Shut a sluice gate within reach. Uses the main action.
func hero_shut_gate(c: Vector2i) -> Array:
	if not is_hero_turn() or not level.gates.has(c) or level.get_tile(c) != Level.Tile.GATE_OPEN:
		return []
	if not _reaches_square(hero, c):
		_log("Too far from the gate.")
		return _flush()
	if budget.main <= 0:
		_log("No main action left this turn.")
		return _flush()
	level.set_tile(c, Level.Tile.GATE_SHUT)
	_emit({"t": "gate", "cell": c, "open": false})
	_log("Thomas hauls the sluice gate shut." if level.gates.any(func(g): return level.get_tile(g) == Level.Tile.GATE_OPEN) else "Thomas hauls the last gate shut. The water stops rising.")
	_spend("main")
	return _flush()


## The nearest open sluice gate within Thomas's reach, or (-1, -1).
func gate_in_reach() -> Vector2i:
	for g in level.gates:
		if level.get_tile(g) == Level.Tile.GATE_OPEN and _reaches_square(hero, g):
			return g
	return Vector2i(-1, -1)


func hero_end_turn() -> Array:
	if not is_hero_turn():
		return []
	_end_turn(hero)
	_enemy_phase()
	return _flush()


# ---------------------------------------------------------------- turns

func _begin_turn(u: Combatant) -> void:
	active = u
	budget = {"move": u.move_speed() * SQ, "maneuver": 1, "main": 1}
	_emit({"t": "turn", "unit": u})
	if u == hero:
		u.resolve += 2
		_emit({"t": "resolve", "value": u.resolve})
	u.big_cooldown = maxi(0, u.big_cooldown - 1)
	if u.bleeding or (u.dying and u == hero):
		_log("%s bleeds." % u.name)
		_damage(u, 2, false, 1)
	if u.prone and not u.dead and level.get_tile(u.cell) == Level.Tile.WATER:
		_log("%s is under the water, drowning." % u.name)
		_damage(u, DROWN_DAMAGE, false, 1)


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
				budget[k] = 0.0 if k == "move" else 0
		if kind != "move":
			budget.move = 0.0


func _enemy_phase() -> void:
	malice += 1 + floori(round / 2.0)
	_emit({"t": "malice", "value": malice})
	_rise_water()
	for o in bystanders.duplicate():
		if o.alive() and (sees_hero(o) or MovementRules.metres(o.pos.distance_to(hero.pos)) <= MovementRules.JOIN_WITHIN):
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
		u.surprised = false   # surprise lasts only the first round
	_begin_turn(hero)


func _enemy_act(e: Combatant) -> void:
	if e.kind == "standard" and not e.fleeing and not e.fled_once and e.health_ratio() <= FLEE_AT and not hero.dying:
		e.fleeing = true
		e.fled_once = true
		_cancel_telegraph(e, "breaking")
		_emit({"t": "flee", "unit": e})
		_log("%s breaks and runs." % e.title())
	if e.fleeing:
		_flee(e)
		return
	if e.kind == "solo":
		_open_sluice()
	if not e.telegraph.is_empty():
		_big_attack(e)
		_spend("main")
		return
	if e.prone:
		e.prone = false
		_emit({"t": "stand", "unit": e})
		_log("%s gets up." % e.title())
		_spend("maneuver")
	if hero.dead or over:
		return
	var sees := sees_hero(e)
	if sees:
		last_seen = hero.pos
	var knows := sees or MovementRules.metres(e.pos.distance_to(hero.pos)) <= MovementRules.LOSE_WITHIN
	if not in_reach(e, hero, reach_of(e.basic)) and budget.move > 0.0:
		if knows:
			_approach(e, budget.move)
		else:
			_go_toward(e, budget.move, last_seen)
		if not e.alive() or over:
			return
	if in_reach(e, hero, reach_of(e.basic)) and budget.main > 0:
		if not e.big.is_empty() and e.big_cooldown <= 0:
			e.telegraph = band(e)
			e.big_cooldown = int(e.big.get("cooldown", 3))
			if e.health_ratio() <= 0.5:
				e.big_cooldown = int(e.big.get("cooldown_hurt", e.big_cooldown))
			_emit({"t": "telegraph", "unit": e, "band": e.telegraph.duplicate()})
			_log(String(e.big.get("tell", "%s raises its pick high...")) % e.title())
		else:
			_attack(e, e.basic, [hero])
			if e.kind == "standard" and malice >= PRESS_COST and not over and not hero.dead and in_reach(e, hero, reach_of(e.basic)):
				malice -= PRESS_COST
				_emit({"t": "malice_spend", "name": "Press the Attack", "value": malice})
				_log("Malice: the %s presses the attack." % e.name)
				_attack(e, e.basic, [hero])
		_spend("main")


func sees_hero(e: Combatant) -> bool:
	return MovementRules.metres(e.pos.distance_to(hero.pos)) <= MovementRules.SIGHT and level.line_of_sight(e.cell, hero.cell)


func _hero_hidden() -> bool:
	for e in enemies_of(hero):
		if sees_hero(e) or MovementRules.metres(e.pos.distance_to(hero.pos)) <= MovementRules.LOSE_WITHIN:
			return false
	return true


## Would `e`, standing at `at`, flank Thomas: in reach of him, with an ally also in reach more than FLANK_ANGLE
## round him?
func _flanks(e: Combatant, at: Vector2) -> bool:
	if not in_reach_from(e, at, hero):
		return false
	var mine := at - hero.pos
	for o in units:
		if o != e and o.alive() and o.team == e.team and in_reach(o, hero):
			if absf(rad_to_deg(mine.angle_to(o.pos - hero.pos))) >= MovementRules.FLANK_ANGLE - 0.01:
				return true
	return false


## Spots beside `t` that `u` could walk to with `limit` metres: the route to the best one (shortest, flanking
## preferred when `u` is an enemy going for Thomas), or empty.
func _spot_beside(u: Combatant, t: Combatant, limit: float) -> Array[Vector2]:
	var bodies := bodies_except(u)
	var ring := u.radius() + t.radius() + MovementRules.px(MovementRules.STAND_OFF)
	var best: Array[Vector2] = []
	var best_score := INF
	for i in 16:
		var p := t.pos + Vector2.RIGHT.rotated(TAU * i / 16.0) * ring
		if MovementRules.touches_wall(level, p, u.radius()) or MovementRules.overlaps(p, u.radius(), bodies):
			continue
		var pts := MovementRules.route(level, u.pos, p, u.radius(), bodies)
		if pts.is_empty():
			continue
		var c := cost(u, pts)
		if c > limit + 0.001:
			continue
		var score := c - (100.0 if u != hero and t == hero and _flanks(u, p) else 0.0)
		if score < best_score:
			best_score = score
			best = pts
	return best


## Walk up to Thomas: to a spot beside him it can reach (flanking if it can), or as far toward him as `limit` allows.
func _approach(e: Combatant, limit: float) -> void:
	var spot := _spot_beside(e, hero, limit)
	if not spot.is_empty():
		_walk(e, spot)
	else:
		_go_toward(e, limit, hero.pos)


## Walk as far toward a point as `limit` metres allow, stopping before bumping into anyone.
func _go_toward(e: Combatant, limit: float, goal: Vector2) -> void:
	var others := bodies_except(e).filter(func(b): return (b[0] as Vector2).distance_to(goal) > 1.0)
	var pts := MovementRules.route(level, e.pos, goal, e.radius(), others)
	pts = MovementRules.trim(level, e.pos, pts, e.wades, limit)
	pts = _stop_short(e, pts)
	if not pts.is_empty():
		_walk(e, pts)


## The part of a route before `u` would bump into another body.
func _stop_short(u: Combatant, points: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var bodies := bodies_except(u)
	var last := u.pos
	for p in _samples(u.pos, points):
		if MovementRules.overlaps(p, u.radius(), bodies):
			break
		last = p
	if last.distance_to(u.pos) < 1.0:
		return out
	# keep the route's own corners up to where it stops
	var at := u.pos
	for p in points:
		if _on_segment(last, at, p):
			out.append(last)
			return out
		out.append(p)
		at = p
	return out


static func _on_segment(q: Vector2, a: Vector2, b: Vector2) -> bool:
	var ab := b - a
	if ab.length() < 0.001:
		return q.distance_to(a) < 0.5
	var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return q.distance_to(a + ab * t) < 0.5


## Malice: when there are at least two Faithful and some aren't yet beside Thomas, they all surge up to 2 squares.
func _swarming_hymn() -> void:
	var flock: Array[Combatant] = []
	var far := false
	for u in enemies_of(hero):
		if u.style == "faithful":
			flock.append(u)
			if not in_reach(u, hero):
				far = true
	if flock.size() < 2 or not far or malice < HYMN_COST:
		return
	malice -= HYMN_COST
	_emit({"t": "malice_spend", "name": "Swarming Hymn", "value": malice})
	_log("Malice: the Faithful sing, and surge forward together.")
	for f in flock:
		if over:
			return
		if f.alive() and not f.prone and not in_reach(f, hero):
			_approach(f, HYMN_SURGE * SQ)


## Run: as far from Thomas as it can get, out of his sight if possible. Out of sight and far enough, it escapes.
func _flee(e: Combatant) -> void:
	if e.prone:
		e.prone = false
		_emit({"t": "stand", "unit": e})
		_spend("maneuver")
	if budget.move > 0.0:
		var bodies := bodies_except(e)
		var best: Array[Vector2] = []
		var best_score := _flee_score(e.pos)
		for i in 16:
			for k in [1.0, 0.66, 0.33]:
				var p: Vector2 = e.pos + Vector2.RIGHT.rotated(TAU * i / 16.0) * MovementRules.px(budget.move * k)
				if not level.is_walkable(MovementRules.cell_of(p)) or MovementRules.touches_wall(level, p, e.radius()) or MovementRules.overlaps(p, e.radius(), bodies):
					continue
				var pts := MovementRules.route(level, e.pos, p, e.radius(), bodies)
				if pts.is_empty() or cost(e, pts) > budget.move + 0.001:
					continue
				var score := _flee_score(p)
				if score > best_score:
					best_score = score
					best = pts
		if not best.is_empty():
			_walk(e, best)
	if not e.alive() or over:
		return
	var d := MovementRules.metres(e.pos.distance_to(hero.pos))
	if d > MovementRules.SIGHT or (d >= MovementRules.ESCAPE_UNSEEN and not level.line_of_sight(e.cell, hero.cell)):
		e.fled = true
		e.fleeing = false
		_emit({"t": "escape", "unit": e})
		_log("%s limps away into the dark. It will be back." % e.title())
		_check_over()


func _flee_score(p: Vector2) -> float:
	return MovementRules.metres(p.distance_to(hero.pos)) * 10.0 + (15.0 if not level.line_of_sight(MovementRules.cell_of(p), hero.cell) else 0.0)


func _big_attack(e: Combatant) -> void:
	var b := e.telegraph.duplicate()
	e.telegraph = {}
	_emit({"t": "telegraph_end", "unit": e})
	if band_gap(b, e) > reach_of(e.big) * SQ + 0.001:
		_log("%s's blow comes down on empty stone." % e.title())
		return
	_emit({"t": "smash", "unit": e, "band": b})
	var targets: Array[Combatant] = []
	for o in units:
		if o != e and o.alive() and in_band(b, o.pos, o.radius()):
			targets.append(o)
	if targets.is_empty():
		_log("The pick bites into the floor where Thomas stood.")
		return
	_attack(e, e.big, targets)


func _cancel_telegraph(t: Combatant, why: String) -> void:
	if t.telegraph.is_empty():
		return
	t.telegraph = {}
	_emit({"t": "telegraph_end", "unit": t})
	_log("%s is %s; the swing is broken." % [t.title(), why])


# ---------------------------------------------------------------- the Outflow

func _gate_open() -> bool:
	return level.gates.any(func(g): return level.get_tile(g) == Level.Tile.GATE_OPEN)


## While a sluice gate stands open, the water in the arena spreads one square outward each round.
func _rise_water() -> void:
	if not arena.has_area() or not _gate_open():
		return
	var fresh := level.flood_step(arena, WATER_CAP)
	if fresh.is_empty():
		return
	_emit({"t": "flood", "cells": fresh})
	_log("The sluices roar. The water rises.")


## Malice: the boss hauls a shut gate open again.
func _open_sluice() -> void:
	if not arena.has_area() or malice < SLUICE_COST:
		return
	for g in level.gates:
		if level.get_tile(g) == Level.Tile.GATE_SHUT:
			malice -= SLUICE_COST
			level.set_tile(g, Level.Tile.GATE_OPEN)
			_emit({"t": "malice_spend", "name": "Open the Sluice", "value": malice})
			_emit({"t": "gate", "cell": g, "open": true})
			_log("Malice: the sluice gate grinds open again.")
			return


# ---------------------------------------------------------------- movement

## Walk a route. Leaving an enemy's reach gives it a free strike; doors on the way open; the walker's movement pays
## for every metre. Plays as "move" events, broken where a free strike lands.
func _walk(u: Combatant, points: Array[Vector2]) -> void:
	if u == active:
		_spend("move")
	var walked: Array[Vector2] = []
	for p in _samples(u.pos, points):
		if u.dead or over:
			break
		for e in enemies_of(u):
			if _may_strike(e) and in_reach(u, e) and not in_reach_from(u, p, e):
				_emit_walk(u, walked)
				walked = []
				e.free_strike_ready = false
				_emit({"t": "attack", "unit": e, "target": u})
				_log("%s strikes as %s pulls away." % [e.name, u.name])
				_damage(u, e.free_strike, false, 1)
				if u.dead or over:
					return
		_open_doors_on(u, [p] as Array[Vector2])
		if u == active:
			budget.move = maxf(0.0, budget.move - MovementRules.route_cost(level, u.pos, [p] as Array[Vector2], u.wades))
		u.pos = p
		walked.append(p)
	_emit_walk(u, walked)


func _emit_walk(u: Combatant, walked: Array[Vector2]) -> void:
	if not walked.is_empty():
		_emit({"t": "move", "unit": u, "points": walked.duplicate(), "to": u.cell})


func _open_doors_on(u: Combatant, points: Array[Vector2]) -> void:
	for p in points:
		for c in MovementRules.cells_touched(p, u.radius()):
			if level.get_tile(c) == Level.Tile.DOOR_CLOSED:
				level.set_tile(c, Level.Tile.DOOR_OPEN)
				_emit({"t": "door", "cell": c})


## Forced movement: n squares' worth (1.5 m each) straight along the line from `from` through the target. Hitting a
## wall or a creature hurts: 1 damage for each square's worth left over.
func _push(t: Combatant, from: Vector2, n: int, pusher: Combatant = null) -> void:
	var dir := t.pos - from
	if dir.length() < 0.01 or n <= 0:
		return
	dir = dir.normalized()
	if t.kind == "solo":
		n = mini(n, 1)   # too heavy to drive far
	var total := MovementRules.px(n * SQ)
	var moved := 0.0
	var other: Combatant = null
	var stopped := false
	var path: Array[Vector2] = []
	while moved < total - 0.01:
		var step := minf(2.0, total - moved)
		var nxt := t.pos + dir * step
		other = _body_at(t, nxt)
		if other != null or MovementRules.touches_wall(level, nxt, t.radius()) or _closed_door_ahead(nxt, dir, t.radius()):
			stopped = true
			break
		t.pos = nxt
		moved += step
		if path.is_empty() or path[-1].distance_to(nxt) >= 4.0:
			path.append(nxt)
	if moved > 0.0 and (path.is_empty() or path[-1] != t.pos):
		path.append(t.pos)
	if not path.is_empty():
		_emit({"t": "push", "unit": t, "points": path})
		_cancel_telegraph(t, "knocked off balance")
	var left := total - moved
	if stopped and left > 2.0:
		var slam := ceili(left / MovementRules.TILE - 0.001)
		_emit({"t": "slam", "unit": t, "at": t.pos + dir * t.radius()})
		if other != null:
			_log("%s is slammed into %s." % [t.title(), other.the()])
		else:
			_log("%s is slammed into the wall." % t.title())
		if pusher != null and pusher.perks.has("weight_behind_it"):
			slam += 2
		_damage(t, slam, false, 1)
		if t.kind == "solo" and not t.dead:
			t.dazed = maxi(t.dazed, 1)
			_emit({"t": "status", "unit": t})
			_log("%s's own weight drives him into it. He reels, dazed." % t.title())
		if other != null:
			_damage(other, slam, false, 1)
		if pusher != null:
			_hammers_due(pusher, "slam")


## Another creature whose body a body of `u`'s size at `p` would overlap.
func _body_at(u: Combatant, p: Vector2) -> Combatant:
	for o in units:
		if o != u and o.alive() and p.distance_to(o.pos) < u.radius() + o.radius() - 0.01:
			return o
	return null


func _closed_door_ahead(p: Vector2, dir: Vector2, r: float) -> bool:
	return level.get_tile(MovementRules.cell_of(p + dir * r)) == Level.Tile.DOOR_CLOSED


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
	if targets.size() == 1 and targets[0].surprised:
		edges += 1   # caught unaware (sneaking spec): an edge until the first round ends
	if targets.size() == 1 and targets[0].dazed > 0 and u.perks.has("ringing_blows") and ab.get("weapon", "") == "mace":
		edges += 1
	if targets.size() == 1 and u.team != hero.team and _flanks(u, u.pos) and targets[0] == hero:
		edges += 1
	var r := _roll(u.might, edges)
	_emit({"t": "roll", "unit": u, "ability": ab, "roll": r, "at": (targets[0] as Combatant).pos if not targets.is_empty() else u.pos})
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
		_log("%s's skull gives way." % t.title())
		_kill(t)
		return
	_damage(t, int(eff.get("dmg", 0)), r.crit, r.tier)
	if t.dead:
		return
	if eff.has("dazed"):
		t.dazed = maxi(t.dazed, int(eff.dazed))
		_log("%s reels, dazed." % t.title())
	if eff.has("slowed"):
		t.slowed = maxi(t.slowed, int(eff.slowed))
	if eff.get("prone", false) and not t.prone:
		t.prone = true
		_emit({"t": "prone", "unit": t})
		_log("%s goes down." % t.title())
		_cancel_telegraph(t, "knocked down")
	if int(eff.get("push", 0)) > 0:
		_push(t, u.pos, int(eff.push), u)
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
			if o != t and o.alive() and o.kind == "minion" and o.team == t.team and in_reach(o, t):
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
	_log("%s suffers %s." % [t.title(), what])


func _kill(t: Combatant) -> void:
	if t.dead:
		return
	t.dead = true
	t.telegraph = {}
	_emit({"t": "death", "unit": t, "crushed": t.crushed})
	if t == hero:
		_log("Thomas Wren is dead.")
	else:
		_log("%s is dead." % t.title())
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
