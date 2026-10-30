class_name StealthRules
extends RefCounted
## Sneaking (design/quick-specs/sneaking-2026-10-30.md): what enemies see and hear, how fast they notice Thomas,
## and his lantern. Every tuning value is here. The maths is pure, so it can be tested on its own.
##
## An enemy sees in a cone the way it faces, and all round when it is close or already after him. While Thomas is
## in sight its spotting meter fills: fast close up and in light, slow far off, in the dark, or while he sneaks. At
## half it is suspicious and comes to look; full, it has spotted him and the fight starts. Noise makes it suspicious
## too.

# ---- sight
const CONE_ANGLE := 100.0        # degrees: how wide an enemy's view is
const AROUND := 2.0              # m: closer than this it notices him whichever way it faces
const CONE_SHOW := 15.0          # m: cones are drawn for enemies this close to Thomas
const FILL_FAST := 0.4           # s to fill the meter: close, lit, walking
const FILL_SLOW := 4.0           # s to fill it: far, dark, sneaking
const DRAIN := 0.25              # meter lost per second out of sight
const SUSPICIOUS_AT := 0.5       # meter at which it stops and comes to look

# ---- what makes him harder to see (shares of the way from FILL_FAST to FILL_SLOW)
const FAR_SHARE := 0.4           # at the edge of sight
const DARK_SHARE := 0.35         # in complete darkness
const SNEAK_SHARE := 0.25        # sneaking

# ---- cover
const COVER_REACH := 1.5         # m: a crouched Thomas this close behind a crate or barrel is hidden by it
const WATER_HIDE := 1.4          # crouched in water, the meter takes this many times as long to fill

# ---- sneaking and noise
const SNEAK_SPEED := 0.5         # share of walking speed
const NOISE_WALK := 4.0          # m: walking is heard this far
const NOISE_SNEAK := 1.0         # m: sneaking
const NOISE_WADE := 2.0          # wading carries this many times further
const NOISE_RELIGHT := 3.0       # m: striking a light
const WALL_MUFFLE := 0.5         # noise through a wall carries this share as far

# ---- what a suspicious enemy does
const SUSPICIOUS_WAIT := 1.2     # s it stands and stares before coming to look
const SEARCH_LOOK := 2.5         # s it looks about at the spot before going back
const LOOK_ABOUT := Vector2(3.0, 6.0)   # s between an idle enemy's turns of the head
const TURN_SPEED := 2.5          # rad/s an enemy turns its head

# ---- the lantern
const LANTERN_LIGHT := {"lit": 1.0, "shuttered": 0.45, "out": 0.0}   # how much his own lantern lights him
const SHUTTERED_RADIUS := 1.5    # squares of light when shuttered
const SHUTTERED_ENERGY := 0.6
const RELIGHT_TIME := 2.0        # s to strike a light again, standing still


## Is `to` inside the view of something at `from` facing `look`? (Distance and walls are checked separately.)
## `alert`: it is already after him, and looks all round.
static func in_view(from: Vector2, look: Vector2, to: Vector2, alert := false) -> bool:
	var d := to - from
	if alert or MovementRules.metres(d.length()) <= AROUND:
		return true
	if look.length() < 0.01 or d.length() < 0.01:
		return true
	return absf(rad_to_deg(look.angle_to(d))) <= CONE_ANGLE / 2.0


## Is a crouched Thomas at `hider` hidden from `watcher` by a crate or barrel just in front of him (within
## COVER_REACH, on the line between them)?
static func behind_cover(level: Level, watcher: Vector2, hider: Vector2) -> bool:
	var to := watcher - hider
	var reach := minf(MovementRules.px(COVER_REACH), to.length())
	var dir := to.normalized()
	var d := 4.0
	while d <= reach:
		if level.get_tile(MovementRules.cell_of(hider + dir * d)) == Level.Tile.COVER:
			return true
		d += 4.0
	return false


## How light it is where Thomas stands, 0 (black) to 1: his own lantern, or the room's lights near him.
static func light_at(p: Vector2, lights: Array[Vector2], lantern: String) -> float:
	var best: float = LANTERN_LIGHT.get(lantern, 1.0)
	var reach := Lighting.LANTERN_RADIUS * MovementRules.TILE
	for l in lights:
		best = maxf(best, clampf(1.0 - p.distance_to(l) / reach, 0.0, 1.0))
	return best


## Seconds an enemy `dist` metres away, seeing him, takes to fill its meter.
static func fill_time(dist: float, light: float, sneaking: bool) -> float:
	if dist <= AROUND:
		return FILL_FAST
	var hidden := clampf(dist / MovementRules.SIGHT, 0.0, 1.0) * FAR_SHARE + (1.0 - clampf(light, 0.0, 1.0)) * DARK_SHARE
	if sneaking:
		hidden += SNEAK_SHARE
	return lerpf(FILL_FAST, FILL_SLOW, clampf(hidden, 0.0, 1.0))


## How far his footsteps carry, in metres.
static func noise_radius(sneaking: bool, wading: bool) -> float:
	return (NOISE_SNEAK if sneaking else NOISE_WALK) * (NOISE_WADE if wading else 1.0)


## Does a noise of `radius` metres at `at` reach something at `listener`? Through a wall it carries half as far.
static func hears(level: Level, at: Vector2, listener: Vector2, radius: float) -> bool:
	var d := MovementRules.metres(at.distance_to(listener))
	if d > radius:
		return false
	return d <= radius * WALL_MUFFLE or level.line_of_sight(MovementRules.cell_of(at), MovementRules.cell_of(listener))
