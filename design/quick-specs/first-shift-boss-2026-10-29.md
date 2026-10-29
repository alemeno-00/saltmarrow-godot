# Quick Design Spec: The First Shift (Sewers boss)

**Type**: New Small System
**Scope**: The boss fight that ends the first version's run, its arena (the Outflow) and rising water. Not Mara's reward or any town scene: the town is out of the first version.
**GDD Reference**: `design/game-brief.md` (MVP item 6, build order step 3). No GDD at `rigor: minimal`.
**Date**: 2026-10-29
**Estimated Implementation**: 3–4 days

## Overview

At the bottom of the Sewers, the outflow room holds **Garrick**, Mara's night-shift foreman and the first man into the new seam. He never came back up. He is now a huge Drowned: salt-crusted, pearl-eyed, dragging a length of lift chain. While he fights, the sluice gates flood the room. Thomas wins by reading his wind-ups, keeping to dry ground, shutting the gates, and slamming him into walls. When Garrick dies his brass tally tag drops, and picking it up wins the run.

## Core Rules

1. **The arena.** The deepest Sewers level always contains one fixed room, the **Outflow**, generated with the rest of the level: two sluice gates set in its walls and a channel of water down its middle. Garrick waits there alone. That level has no stairs down; the Outflow takes their place.
2. **A new enemy kind: `solo`.**
   - Garrick never breaks and runs (only `standard` enemies flee).
   - Execution's skull crush does not kill him (it only crushes minions and standard enemies); Execution deals its normal damage.
   - Forced movement moves him at most 1 square, whatever the push distance.
3. **Pick and Chain** (his basic attack): one adjacent target. 4 / 7 / 10 damage. Torso injury 0 / 10 / 20%.
4. **Lift-Chain Sweep** (his telegraphed blow):
   - Wind-up turn: the target squares darken: Thomas's square and the two squares on each side of it across Garrick's facing, five in a row (walls excluded). It lands on his next turn on everyone still in those squares, if any of them is within 2 squares of Garrick.
   - 8 / 12 / 16 damage; every hit knocks the target prone.
   - Cooldown 3 rounds; 2 once Garrick is at half Stamina or less.
   - Knocking him prone, or pushing him, during the wind-up breaks the swing (existing rule).
5. **Rising water.**
   - At the start of each enemy phase, while at least one gate is open, every Outflow floor square next to a water square becomes water. Water stops spreading once it covers 60% of the room's floor.
   - Entering a water square costs 2 squares of movement. Garrick ignores this.
   - A creature that starts its turn prone in water takes 2 damage (drowning).
6. **Sluice gates.** Thomas can shut a gate he stands next to as his main action. With both shut, the water stops rising; it does not drain. The enemy side can spend 4 Malice to reopen one gate (**Open the Sluice**), on Garrick's turn.
7. **Slams.** When Garrick is slammed into a wall or a gate he takes normal slam damage and is also dazed for 1 round.
8. **Winning.** When Garrick dies, his brass tally tag drops on his square and the fight ends. Walking onto the tag shows the win screen and ends the run as won. Carrying the tag back to Mara waits for the town.

## Tuning Knobs

| Knob | Default | Range | Category | Rationale |
|------|---------|-------|----------|-----------|
| Garrick Stamina | 60 | 45–80 | curve | Three Drowned Miners' worth; Thomas is about level 4 (33 Stamina) by depth 3 |
| Might / speed / free strike | 3 / 4 / 4 | — | feel | Slow but hits hard |
| Pick and Chain damage | 4 / 7 / 10 | — | curve | A step above the Miner's 3 / 5 / 8 |
| Sweep damage | 8 / 12 / 16 | — | curve | Lethal if ignored, survivable once |
| Sweep cooldown | 3, then 2 at ≤50% | 2–4 | feel | Gets more dangerous as he weakens |
| Water rise per round | 1 square outward | 0–2 | gate | Pressure without a hard timer |
| Water cap | 60% of the floor | 40–80% | gate | Dry ground always remains |
| Water movement cost | 2 | 1–3 | feel | Slows Thomas, not Garrick |
| Drowning damage | 2 per turn | 1–4 | feel | Being prone in water is the real danger |
| Open the Sluice cost | 4 Malice | 3–6 | curve | About one spend every few rounds |
| Bottom depth (Outflow level) | 3 | 2–5 | gate | Short enough for the first version |

`.claude/docs/coding-standards.md` wants gameplay values in external data under `assets/data/`. `assets/` belongs to ChatGPT (`AGENTS.md`), so these stay as named constants in the code, the way enemy stats do now (`scripts/combat/bestiary.gd`, `abilities.gd`). Move them when the code side has a data folder of its own.

## Acceptance Criteria

- [ ] The deepest Sewers level contains the Outflow with Garrick, two gates and a water channel, and no stairs down. *(test)*
- [ ] Garrick never flees, and Execution never crushes him. *(test)*
- [ ] The Sweep is telegraphed one turn ahead and hits all five marked squares; knocking him prone or pushing him during the wind-up cancels it. *(test)*
- [ ] Water spreads one square outward per enemy phase while a gate is open, and stops at the cap or when both gates are shut. *(test)*
- [ ] Entering water costs Thomas 2 movement; starting a turn prone in water deals 2 damage. *(test)*
- [ ] A slam into a wall or gate dazes Garrick for 1 round. *(test)*
- [ ] Killing Garrick drops the tag; walking onto it shows the win screen. *(test + retained screenshot)*
- [ ] Feel (playtest): reading the wind-ups and staying out of the water decides the fight; a level-4 Thomas wins about half the time on a first try.
- [ ] No regression: other levels, the Drowned Miner and the Faithful behave as before; the existing tests still pass.

## Art needed

Added to `ART_JOBS.md`: Garrick's sprite sheet and portrait, sluice gates (open and shut), floor turning to water, and the brass tally tag.

## Systems Index

This system is below systems-index tracking threshold — quick spec is sufficient.
