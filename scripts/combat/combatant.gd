class_name Combatant
extends RefCounted
## Anyone in a fight: Thomas or an enemy. Plain data; the Battle changes it.

var name := ""
var team := "enemy"
var kind := "standard"   # hero, standard, minion
var style := ""          # which drawing to use
var pos := Vector2(16, 16)   # where it stands, in pixels (the middle of its feet); fights are measured from here
## The square it stands in. Setting it puts the creature in the middle of that square.
var cell: Vector2i:
	get:
		return MovementRules.cell_of(pos)
	set(value):
		pos = MovementRules.centre(value)
var max_stamina := 10
var stamina := 10
var might := 0
var agility := 0
var resource := "fury"   # how Thomas gains extra Resolve: fury (when hurt) or shadow (striking one that can't see him)
var bleed := 0           # damage bleeding does each turn (2 unless a wound is worse)
var gained_this_round := false   # Shadow: already took his extra Resolve this round
var speed := 5
var free_strike := 2
var basic: Dictionary = {}
var abilities: Array = []
var big: Dictionary = {}   # a telegraphed attack, if it has one
var perks: Array[String] = []   # passives learned
var wades := false      # the Drowned: water does not slow it

var dazed := 0       # rounds left
var slowed := 0      # rounds left
var prone := false
var bleeding := false
var injuries: Array[String] = []
var dying := false
var dead := false
var crushed := false

var resolve := 0
var recoveries := 0
var recovery_value := 0
var hurt_this_round := false
var free_strike_ready := true
var telegraph: Dictionary = {}   # a big blow being raised: the band on the floor it will land on (Battle.band)
var big_cooldown := 0

var fleeing := false     # broke and is running
var fled := false        # got away; gone from the fight, may come back
var fled_once := false   # only runs once
var group := -1         # which band it belongs to; a band fights together
var state := "idle"      # outside a fight: idle, patrolling, suspicious (stopped, staring), investigating (going to look),
                         # hunting (coming for Thomas) or searching (going to where he was seen)
var route: Array[Vector2i] = []   # a patrol leader's waypoints (room centres), walked back and forth
var route_i := 0                  # the waypoint it is heading for
var route_dir := 1                # +1 along the route, -1 back
var target := Vector2i.ZERO
var alert := 0.0          # outside a fight: how close it is to spotting Thomas (0 unaware .. 1 spotted)
var resume_state := ""    # what it goes back to after investigating a noise or a glimpse
var wait := 0.0           # seconds left standing still (staring, or looking about)
var surprised := false    # caught unaware when the fight began: no free strikes, attacks on it have an edge (round 1)


## How the fight log names it at the start of a sentence: "Garrick", "Thomas", or "The Drowned Miner".
func title() -> String:
	return name if kind == "hero" or kind == "solo" else "The " + name


## The same, mid-sentence: "Garrick", or "the Drowned Miner".
func the() -> String:
	return name if kind == "hero" or kind == "solo" else "the " + name


## Still in the fight: not dead and hasn't run off.
func alive() -> bool:
	return not dead and not fled


## Its body's radius in pixels: big creatures take up more room.
func radius() -> float:
	return MovementRules.px(MovementRules.LARGE_RADIUS if kind == "solo" else MovementRules.BODY_RADIUS)


func move_speed() -> int:
	if slowed > 0 or injuries.has("leg"):
		return mini(2, speed)
	return speed


func health_ratio() -> float:
	return float(stamina) / float(max_stamina)


## How hurt it looks, in words. No numbers on enemies.
func health_word() -> String:
	if dead:
		return "dead"
	if dying:
		return "dying"
	var r := health_ratio()
	if r >= 1.0:
		return "unhurt"
	if r > 0.6:
		return "hurt"
	if r > 0.3:
		return "wounded"
	return "badly wounded"


func condition_words() -> Array[String]:
	var w: Array[String] = []
	if dazed > 0:
		w.append("dazed")
	if slowed > 0:
		w.append("slowed")
	if prone:
		w.append("prone")
	if bleeding:
		w.append("bleeding")
	for i in injuries:
		w.append({"head": "head wound", "arm": "broken arm", "leg": "broken leg", "torso": "deep wound"}[i])
	if not telegraph.is_empty():
		w.append("winding up a big blow")
	if fleeing:
		w.append("running")
	return w
