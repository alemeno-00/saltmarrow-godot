class_name MovementRules
extends RefCounted
## Moving freely in metres, and how hits feel (design/quick-specs/free-movement-2026-10-30.md).
## One square of the level is 1.5 m. Bodies are circles that slide along walls; the level's squares stay the data.
## Every tuning value is here, so feel can be tuned in one place.

# ---- units
const METRES_PER_SQUARE := 1.5
const TILE := 32                                   # pixels per square
const PX_PER_METRE := TILE / METRES_PER_SQUARE

# ---- Thomas
const WALK_SPEED := 3.5          # m/s (playtest 2026-10-30: 3.0 felt slightly slow)
const ACCEL_TIME := 0.1          # s from standing to full speed
const STOP_TIME := 0.08          # s from full speed to standing
const HERO_RADIUS := 0.35        # m
const WATER_SLOW := 0.6          # speed in shallow water, for those who don't wade
const DEEP_SLOW := 0.4           # speed in waist-deep sewage (design/quick-specs/deep-sewage-tunnels-2026-10-30.md)
const ARRIVE := 3.0              # px: close enough to a path point to move on to the next
const STUCK_AFTER := 0.4         # s of trying to walk without getting anywhere before a click-walk gives up

# ---- the world while exploring
const SIGHT := 10.5              # m: how far an enemy notices Thomas with a clear sight line
const PATROL_SPEED := 1.6        # m/s
const HUNT_SPEED := 2.6          # m/s: hunters and searchers, a little slower than Thomas so he can get away
const ENEMY_RADIUS := 0.4        # m: a normal-size creature's body
const FOLLOW_GAP := 1.2          # squares: a patrol follower stops this close to its leader
const REPATH_EVERY := 0.4        # s between route updates for a creature chasing a moving goal
const RETURN_AFTER := 15.0       # s before a runaway comes back with friends

# ---- fights (phase B)
const BODY_RADIUS := 0.4         # m: a normal-size creature in a fight
const LARGE_RADIUS := 0.7        # m: Garrick (still inside one square)
const WATER_COST := 2.0          # metres of movement spent per metre waded, for those who don't wade
const DEEP_COST := 3.0           # the same in waist-deep sewage
const SHIFT := 1.5               # m: a careful step
const FLANK_ANGLE := 120.0       # degrees round the target between two attackers for a flank
const LOSE_WITHIN := 3.0         # m: enemies this close always know where Thomas is
const JOIN_WITHIN := 4.5         # m: bystanders this close hear the fight and join
const ESCAPE_UNSEEN := 6.0       # m: a runaway this far off and out of sight gets away
const FIGHT_WALK_SPEED := 5.0    # m/s: how fast moves play back in a fight
const STAND_OFF := 0.5           # m: the gap an enemy leaves when it walks up to strike

# ---- hit feel
const HITSTOP := [0.06, 0.09, 0.12]   # s of freeze for a weak / solid / strong hit
const SHAKE_BASE := 2.0
const SHAKE_PER_DAMAGE := 0.5
const WINDUP_PULL := 4.0         # px a striker draws back before the blow
const WINDUP_PAUSE := 0.12       # s of extra wind-up before a heavy blow
const STRIKE_LUNGE := 11.0       # px the striker drives forward on impact
const PUSH_TIME_PER_SQUARE := 0.06
const TURN_DUST_SPEED := 0.6     # fraction of top speed above which a sharp turn kicks up dust
const TURN_DUST_ANGLE := 100.0   # degrees: how sharp a turn has to be
const TURN_DUST_COOLDOWN := 0.25


static func px(metres: float) -> float:
	return metres * PX_PER_METRE


## The square a point in the world is in.
static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


## The middle of a square, in pixels.
static func centre(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)


## The new velocity after one frame of wanting to go `wish` (a direction, length 0..1) at `top` px/s:
## speeds up to `top` in ACCEL_TIME and stops in STOP_TIME.
static func steer(v: Vector2, wish: Vector2, top: float, delta: float) -> Vector2:
	if wish.length_squared() < 0.0001:
		return v.move_toward(Vector2.ZERO, top / STOP_TIME * delta)
	var want := wish.limit_length(1.0) * top
	return v.move_toward(want, top / ACCEL_TIME * delta)


## Move a circle of radius `r` (px) by `motion` through the level, sliding along walls and around other bodies.
## `bodies`: [centre, radius] pairs it may not overlap. Moves in small steps so it never passes through a wall.
static func slide(level: Level, from: Vector2, motion: Vector2, r: float, bodies: Array = []) -> Vector2:
	var steps := maxi(1, ceili(motion.length() / (r * 0.5)))
	var p := from
	for i in steps:
		p = push_out(level, p + motion / steps, r, bodies)
	return p


## Push a circle out of any wall square and any body it overlaps.
static func push_out(level: Level, p: Vector2, r: float, bodies: Array = []) -> Vector2:
	for _pass in 3:
		var moved := false
		var c := cell_of(p)
		for y in range(-1, 2):
			for x in range(-1, 2):
				var q := c + Vector2i(x, y)
				if level.is_walkable(q):
					continue
				var box := Rect2(Vector2(q * TILE), Vector2(TILE, TILE))
				var near := p.clamp(box.position, box.end)
				var d := p - near
				var dist := d.length()
				if dist >= r:
					continue
				if dist < 0.001:
					p = _out_of_box(p, box, r)
				else:
					p += d / dist * (r - dist)
				moved = true
		for b in bodies:
			var d: Vector2 = p - (b[0] as Vector2)
			var need: float = r + float(b[1])
			var dist := d.length()
			if dist < need and dist > 0.001:
				p = (b[0] as Vector2) + d / dist * need
				moved = true
		if not moved:
			break
	return p


## A centre that ended up inside a wall square leaves by the nearest side.
static func _out_of_box(p: Vector2, box: Rect2, r: float) -> Vector2:
	var left := p.x - box.position.x
	var right := box.end.x - p.x
	var up := p.y - box.position.y
	var down := box.end.y - p.y
	var least := minf(minf(left, right), minf(up, down))
	if least == left:
		return Vector2(box.position.x - r, p.y)
	if least == right:
		return Vector2(box.end.x + r, p.y)
	if least == up:
		return Vector2(p.x, box.position.y - r)
	return Vector2(p.x, box.end.y + r)


## Can a circle of radius `r` go straight from `a` to `b` without touching a wall (or any of `bodies`)?
static func clear_walk(level: Level, a: Vector2, b: Vector2, r: float, bodies: Array = []) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / 4.0))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if touches_wall(level, p, r) or overlaps(p, r, bodies):
			return false
	return true


## Does a circle at `p` overlap any of `bodies` ([centre, radius] pairs)?
static func overlaps(p: Vector2, r: float, bodies: Array) -> bool:
	for b in bodies:
		if p.distance_to(b[0] as Vector2) < r + float(b[1]) - 0.01:
			return true
	return false


static func metres(pixels: float) -> float:
	return pixels / PX_PER_METRE


## A route for a circle of radius `r` from `from` to `to` that goes round walls and bodies and cuts corners where
## the way is clear: the points to walk through, ending at `to`. Empty if there is no way.
static func route(level: Level, from: Vector2, to: Vector2, r: float, bodies: Array = []) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if from.distance_to(to) < 0.5:
		return out
	if clear_walk(level, from, to, r, bodies):
		out.append(to)
		return out
	var blocked: Array[Vector2i] = []
	for b in bodies:
		blocked.append(cell_of(b[0] as Vector2))
	var cells := level.find_path_avoiding(cell_of(from), cell_of(to), blocked)
	if cells.is_empty():
		return out
	var pts: Array[Vector2] = []
	for c in cells:
		pts.append(centre(c))
	pts[-1] = to
	# pull the string tight: from each point, jump to the furthest one in clear view
	var at := from
	var i := 0
	while i < pts.size():
		var j := pts.size() - 1
		while j > i and not clear_walk(level, at, pts[j], r, bodies):
			j -= 1
		out.append(pts[j])
		at = pts[j]
		i = j + 1
	return out


## What walking a route costs, in metres of movement: its length, with every metre in water counted WATER_COST
## times unless the walker wades.
static func route_cost(level: Level, from: Vector2, points: Array[Vector2], wades := false) -> float:
	var cost := 0.0
	var at := from
	for p in points:
		var n := maxi(1, ceili(at.distance_to(p) / 2.0))
		var piece := at.distance_to(p) / n
		for i in n:
			var mid := at.lerp(p, (i + 0.5) / n)
			cost += piece * _cost_factor(level, mid, wades)
		at = p
	return metres(cost)


static func _cost_factor(level: Level, p: Vector2, wades: bool) -> float:
	if wades:
		return 1.0
	match level.get_tile(cell_of(p)):
		Level.Tile.WATER:
			return WATER_COST
		Level.Tile.DEEP:
			return DEEP_COST
	return 1.0


## How much a square slows someone walking through it (1 on dry ground).
static func slow_in(level: Level, c: Vector2i, wades := false) -> float:
	if wades:
		return 1.0
	match level.get_tile(c):
		Level.Tile.WATER:
			return WATER_SLOW
		Level.Tile.DEEP:
			return DEEP_SLOW
	return 1.0


## The part of a route that `budget` metres of movement pays for (the same points, cut short).
static func trim(level: Level, from: Vector2, points: Array[Vector2], wades: bool, budget: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var left := px(budget)
	var at := from
	for p in points:
		var n := maxi(1, ceili(at.distance_to(p) / 2.0))
		for i in n:
			var a := at.lerp(p, float(i) / n)
			var b := at.lerp(p, float(i + 1) / n)
			var c := a.distance_to(b) * _cost_factor(level, (a + b) / 2.0, wades)
			if c > left + 0.001:
				# the budget runs out here: keep the part of this stretch it paid for
				var cut := a.lerp(b, clampf(left / c, 0.0, 1.0)) if c > 0.0 else a
				if cut.distance_to(at) > 0.01:
					out.append(cut)
				return out
			left -= c
		out.append(p)
		at = p
	return out


static func touches_wall(level: Level, p: Vector2, r: float) -> bool:
	var c := cell_of(p)
	for y in range(-1, 2):
		for x in range(-1, 2):
			var q := c + Vector2i(x, y)
			if level.is_walkable(q):
				continue
			var box := Rect2(Vector2(q * TILE), Vector2(TILE, TILE))
			if p.distance_to(p.clamp(box.position, box.end)) < r:
				return true
	return false


## Every square a circle overlaps (for opening the doors it walks into).
static func cells_touched(p: Vector2, r: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var c := cell_of(p)
	for y in range(-1, 2):
		for x in range(-1, 2):
			var q := c + Vector2i(x, y)
			var box := Rect2(Vector2(q * TILE), Vector2(TILE, TILE))
			if p.distance_to(p.clamp(box.position, box.end)) < r:
				out.append(q)
	return out
