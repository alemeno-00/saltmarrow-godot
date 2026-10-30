class_name Items
extends RefCounted
## What Thomas can carry on his belt (design/quick-specs/room-contents-2026-10-30.md, part 3): four slots, no bag,
## no weight. Items come from caches and are lost when he dies; the belt goes down the stairs with him.

const BELT_SLOTS := 4
const SALVE_HEAL := 8          # Stamina a salve gives back (the same as a Recovery)
const SEARCH_NOISE := 3.0      # m: rummaging through a cache is heard this far
const REACH := 1.4             # squares: how close Thomas must be to search, turn or unlock something

const NAMES := {"salve": "Salve", "bandage": "Bandage", "grate_key": "Grate key"}
const TEXT := {
	"salve": "Salve: 8 Stamina back. A maneuver in a fight.",
	"bandage": "Bandage: stops bleeding. A maneuver in a fight.",
	"grate_key": "Grate key: opens this level's locked grate (E beside it).",
}
const ICON := "res://assets/props/sewers/%s.png"


static func icon(item: String) -> Texture2D:
	var path := ICON % item
	return load(path) if ResourceLoader.exists(path) else null
