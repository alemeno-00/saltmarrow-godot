class_name Combatant
extends RefCounted
## Anyone in a fight: Thomas or an enemy. Plain data; the Battle changes it.

var name := ""
var team := "enemy"
var kind := "standard"   # hero, standard, minion
var style := ""          # which drawing to use
var cell := Vector2i.ZERO
var max_stamina := 10
var stamina := 10
var might := 0
var speed := 5
var free_strike := 2
var basic: Dictionary = {}
var abilities: Array = []
var big: Dictionary = {}   # a telegraphed attack, if it has one
var perks: Array[String] = []   # passives learned

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
var telegraph: Array[Vector2i] = []
var big_cooldown := 0

var fleeing := false     # broke and is running
var fled := false        # got away; gone from the fight, may come back
var fled_once := false   # only runs once
var state := "idle"      # outside a fight: idle, hunting (coming for Thomas) or searching (going to where he was seen)
var target := Vector2i.ZERO


## Still in the fight: not dead and hasn't run off.
func alive() -> bool:
	return not dead and not fled


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
