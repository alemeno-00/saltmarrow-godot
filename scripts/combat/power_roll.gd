class_name PowerRoll
extends RefCounted
## Draw Steel power rolls: 2d10 + a stat, read as three tiers.
## 11 or less is tier 1, 12 to 16 is tier 2, 17 or more is tier 3. A natural 19 or 20 is a crit (always tier 3).

const BANDS := ["11 or less", "12 to 16", "17 or more"]


static func tier_of(total: int) -> int:
	if total <= 11:
		return 1
	if total <= 16:
		return 2
	return 3


## edges: +1 is an edge (+2 to the roll), +2 a double edge (one tier better). Negative numbers are banes.
static func resolve(d1: int, d2: int, bonus: int, edges: int) -> Dictionary:
	var e := clampi(edges, -2, 2)
	var total := d1 + d2 + bonus
	var tier: int
	if absi(e) == 1:
		total += 2 * e
		tier = tier_of(total)
	else:
		tier = clampi(tier_of(total) + signi(e), 1, 3)
	var crit := d1 + d2 >= 19
	if crit:
		tier = 3
	return {"d1": d1, "d2": d2, "bonus": bonus, "edges": e, "total": total, "tier": tier, "crit": crit}
