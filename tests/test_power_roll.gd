extends TestBase
## Draw Steel power rolls: tiers, edges, banes and crits.


func test_tiers() -> void:
	eq(PowerRoll.resolve(4, 5, 2, 0).tier, 1, "11 is tier 1")
	eq(PowerRoll.resolve(5, 5, 2, 0).tier, 2, "12 is tier 2")
	eq(PowerRoll.resolve(7, 7, 2, 0).tier, 2, "16 is tier 2")
	eq(PowerRoll.resolve(8, 7, 2, 0).tier, 3, "17 is tier 3")


func test_edge_and_bane() -> void:
	eq(PowerRoll.resolve(5, 4, 1, 1).total, 12, "an edge adds 2")
	eq(PowerRoll.resolve(5, 4, 1, 1).tier, 2, "and can lift the tier")
	eq(PowerRoll.resolve(6, 6, 1, -1).tier, 1, "a bane takes 2 away")
	eq(PowerRoll.resolve(5, 4, 1, 2).tier, 2, "a double edge lifts a whole tier")
	eq(PowerRoll.resolve(8, 8, 2, -2).tier, 2, "a double bane drops a whole tier")


func test_crit() -> void:
	var r := PowerRoll.resolve(10, 9, 0, -2)
	check(r.crit, "a natural 19 is a crit")
	eq(r.tier, 3, "a crit is always tier 3, even with banes")
	check(not PowerRoll.resolve(9, 9, 5, 0).crit, "a natural 18 is not a crit")
