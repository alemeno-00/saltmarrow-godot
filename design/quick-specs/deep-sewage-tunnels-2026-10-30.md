# Quick Design Spec: Deep Sewage Tunnels

**Type**: Addition (to the Sewers room kit and room contents)
**Status**: APPROVED by Julian, 2026-10-30: the recommended first set (lurkers with their tell, drag under, the
ledge). The other ideas stay here for later.
**System**: Sewers levels, movement, stealth, enemies
**GDD Reference**: `design/game-brief.md`; `design/quick-specs/sewer-room-kit-2026-10-29.md`; `design/quick-specs/free-movement-2026-10-30.md`
**Date**: 2026-10-30

## Change Summary

Long tunnels where the floor is under waist-deep sewage: slow, loud, blind below the surface. A new square type,
**deep sewage**, joins shallow water. Art: job 18 (the tunnels) and 13d (a grime pass on every existing room).

## Motivation

Julian, after the first playtest: the Sewers should look grimier, and there should be long tunnels of waist-high
sewage with gameplay of their own, "like enemies that pop up from the water for ambush attacks". It feeds the
brief's "dread" pillar: a stretch of the level you dread crossing, and choose whether to.

## The square

- **Deep sewage**: walkable. Characters are drawn cut off at the waist with a ring of ripples round them.
- Moving costs **3×** (shallow water is 2×); exploring speed **40 %**. Those who wade (the Drowned) move at full speed.
- **Loud**: wading is heard twice as far as walking (feeds the coming sneaking rules).
- **Going prone in it** means going under: drowning damage at the start of every turn until you stand.
- Nothing lying in it can be seen: bodies, items and *things waiting*.

## Ideas for what happens in the tunnels (pick some)

1. **Lurkers (the ambush Julian asked for).** A Drowned lies under the surface. It can't be seen, but its spot
   shows a tell for those who look: slow bubbles, a ring of scum that doesn't drift. When Thomas comes within 2 m
   it rises, and the fight starts with a **surprise round** for it. Spotting the tell first (walking slowly past,
   or a perk) turns it round: Thomas gets the surprise round instead, which ties straight into Daggers' Backstab.
2. **Drag under.** A lurker's attack can grab: Thomas is pulled prone into the sewage (drowning) unless he breaks
   free with his move. Pushing an enemy into deep sewage does the same to it.
3. **Marsh gas.** Pockets of gas bubble up in places, shown by a shimmer. A lit lantern or brazier knocked into it
   (the Daggers' Throw, a push, a missed swing near a wall lamp) sets off a flash: fire damage and a push in a
   circle. Dangerous, and a weapon if you set it off in the right place.
4. **The sluice and the tide.** A valve at one end drains or floods the tunnel. Drained, the lurkers lie exposed
   and stranded (easy kills, and their loot); flooded, the tunnel is a wall of water that cuts off whatever is
   following you. One of the room-contents puzzles (`room-contents-2026-10-30.md`, part 4) could be this.
5. **The ledge.** Some tunnels keep a narrow raised ledge along one side: dry and quick, but one body wide, so
   anyone on it can be pushed off into the sewage, and it is where the Faithful wait to do the pushing.
6. **Leeches.** Wading more than a few metres can leave a leech on Thomas: a little bleeding until he spends a
   maneuver (or a bandage) to pull it off. A small cost for taking the deep route.
7. **Drifting things.** The current carries bodies and debris slowly downstream: moving cover that blocks sight
   lines, and now and then a body with something worth taking.
8. **Sound in the tunnel.** Splashing carries: noise in a tunnel alerts everything along it, so a fight in one is
   rarely just one fight.

## Recommended first set

Lurkers with their tell (1), drag under (2) and the ledge (5): together they make the ambush Julian described,
give careful players a counter, and need only one new enemy behaviour. Gas (3) and the sluice (4) come with the
puzzles; leeches and drifting things later.

## Depends on

- Free movement phase B (fights in metres), for surprise rounds that start mid-movement.
- The sneaking spec (coming next), for noise and spotting tells.
- Claude: new tunnel blockouts with a deep-sewage colour; the deep-sewage square in `Level`; wading drawn
  waist-deep; the lurker's behaviour. ChatGPT: art job 18 and a lurker's rise-from-the-water animation (to add to
  the art list once this is approved).

## Acceptance Criteria (once ideas are chosen)

- [ ] Deep-sewage tunnels appear in generated Sewers levels, reachable but avoidable.
- [ ] Crossing one is slower and louder, and its cost shows on the movement path.
- [ ] A lurker cannot be seen before it rises, but its tell can.
- [ ] Spotting the tell first gives Thomas the surprise round.
