# Quick Design Spec: Room contents

**Type**: New Small System (five parts, built one at a time; each is under a week)
**Scope**: What fills the Sewers' rooms: enemies and patrols, lore drops and the journal, items and caches, puzzles, events, and clutter. Not included: shops, the bag grid, crafting, survival needs, the lantern as a resource, secret rooms, traps.
**GDD Reference**: `design/game-brief.md` (MVP item 8, build order step 5). Added after Julian's first playtest (2026-10-30): "most of the rooms were empty".
**Date**: 2026-10-30
**Estimated Implementation**: about 2–3 weeks across the five parts. This is above one quick spec's size: each part below is built and reviewed as its own step, with its own tests and screenshots, and a part that grows gets its own spec.

## Overview

When a level is built, each room rolls for its contents from a table for its type, using the level's own seed so a seed always gives the same contents. Contents sit on free floor squares, never in the two squares in front of a door. Lore Thomas finds goes into a journal that survives death, as the story says the story so far does.

## Core Rules

1. **Placement.** Contents use the level's seed. They go on walkable floor (not water, not stairs), never within the two squares in front of a door, never on the start square, never on an enemy.

2. **Part 1: Enemies and patrols** *(no new art)*
   - Groups wait in junctions, chambers and flooded rooms (75%, up from 60%), and in the stairs room half the time; never in the entry or within 15 steps of the start.
   - **One patrol per level:** a group that walks a loop through 2–4 connected rooms outside fights, one square per Thomas turn, and spots him like any other enemy.

3. **Part 2: Lore drops and the journal**
   - **1–2 lore drops per level**, plus one always in the lore room. Never in the entry.
   - **Kinds:** Ellen's letters (in story order: hopeful, then strange; worded for the life's backstory); a dead miner with his brass tally tag (one of Mara's missing shift, by name); hymn sheets and chapel notices.
   - **Reading:** step onto it and press E; a reading panel shows the text.
   - **The journal** (J) keeps every lore drop ever found. It survives death and new lives. A drop already in the journal can turn up again in a later life, marked as read.
   - The texts live in a data file of their own (`scripts/data/lore.gd` or similar), written with Julian.

4. **Part 3: Items and caches**
   - **The belt:** 4 slots, shown in the fight panel. No weight, no bag. A full belt leaves an item where it lies.
   - **Items:** *Salve* (restores 8 Stamina, uses a maneuver); *Bandage* (stops bleeding, uses a maneuver); *Grate key* (opens the locked grate, Part 4).
   - **Caches:** 2–3 per level in chambers, junctions and dead ends: a crate, a barrel, or a body with a satchel. Opening one (walk into it and press E) gives its item.
   - Items are lost on death (the journal is not).

5. **Part 4: Puzzles** *(one per level, picked at random from the two)*
   - **Sluice valve:** a valve wheel stands in one room; a flooded room elsewhere is full. Turning the valve (E, outside a fight) drains that room over a few turns, revealing a cache in its basin.
   - **Locked grate:** an iron grate blocks one connector off the main route; its key is in a cache elsewhere. Behind the grate: a cache or a lore drop.
   - Neither ever blocks the way to the exit.

6. **Part 5: Events** *(1–2 per level, each fires once, on entering its room)*
   - **Hymn through the walls:** when the nearest Faithful group is within about 12 squares, a line of hymn is heard (a banner and, later, sound).
   - **Something at the edge of the light:** a pale shape stands just beyond Thomas's lantern, then is gone.
   - **The Drowned rise:** in a flooded room, a Drowned Miner rises from the water as Thomas enters.
   - **Star frost:** salt frost spreads across the floor and the room's lanterns gutter for a moment.

7. **Clutter.** Bones, debris and the odd dead miner, placed lightly by rule on free floor; painted rooms carry most of the clutter themselves.

## Built (2026-10-30)

- **Part 1** (#33): enemies and the patrol.
- **Parts 3 and 4**: the belt (4 slots, keys 6-9 or click), salves and bandages (a maneuver in a fight), 2-3 caches
  per level in the crates and barrels that already stand as cover, and one puzzle per level: a locked grate across a
  tunnel to a quiet side room (key in a cache elsewhere, a cache behind it) or a sluice valve that drains a flooded
  room and reveals a satchel in its basin. Searching makes a little noise. Not yet: bodies with satchels as ordinary
  caches, saving caches and puzzles with the level.
- **Controls**, as in Baldur's Gate 3 (Julian, 2026-10-30): left-click does the obvious thing (walk, strike from the
  dark, search a crate, turn the valve, try the grate); right-click opens a menu of everything that can be done with
  what is under the mouse, in or out of a fight, with actions that can't be done now greyed out and the reason given;
  hovering picks out what can be used, with its name; the belt's slots can be clicked.
- **Still to build**: part 2 (lore and the journal; texts waiting for Julian), part 5 (events), clutter.

## Tuning Knobs

| Knob | Default | Range | Category | Rationale |
|------|---------|-------|----------|-----------|
| Rooms with a group | 75% | 50–90% | curve | Playtest: too few enemies |
| Patrols per level | 1 | 0–2 | feel | Something moves in the dark |
| Lore drops per level | 1–2 (+ lore room) | 0–3 | feel | Story without drowning in text |
| Caches per level | 2–3 | 1–5 | curve | Enough to matter, not a loot game |
| Belt slots | 4 | 2–6 | gate | Choices without a bag |
| Salve healing | 8 Stamina | 5–12 | curve | Same as a Recovery |
| Puzzles per level | 1 | 0–2 | feel | One thing to work out per level |
| Events per level | 1–2 | 0–3 | feel | Rare enough to unsettle |

Values live as named constants in the code (`assets/` belongs to ChatGPT).

## Acceptance Criteria

- [ ] Over 300 seeds: no content in a door's landing, on the start, on water or stairs; the same seed always gives the same contents. *(test)*
- [ ] Part 1: groups in 75% of eligible rooms within ±10% over 300 seeds; one patrol that walks its loop and spots Thomas. *(test)*
- [ ] Part 2: reading a drop adds it to the journal; the journal survives death and a new life. *(test)*
- [ ] Part 3: opening a cache puts its item on the belt; a full belt leaves it; salve and bandage work and use a maneuver; items are lost on death. *(test)*
- [ ] Part 4: the valve drains its room; the grate opens only with its key; neither blocks the exit (every level still reachable to the exit with the grate shut). *(test)*
- [ ] Part 5: each event fires once on entering its room; the Drowned rise adds a miner. *(test)*
- [ ] Feel (playtest): rooms feel worth entering; the dark feels inhabited.
- [ ] No regression: all existing tests pass.

## Art needed

Added to `ART_JOBS.md` (job 14): item icons (salve, bandage, grate key), caches (crate, barrel, satchel body; closed and opened), lore drops on the floor (letter, hymn sheet, a dead miner with his tag), a valve wheel, an iron grate (shut and open), bone and debris decals. Until they arrive, the game draws stand-ins.

## Systems Index

Below systems-index tracking threshold at `rigor: minimal`; this spec and the brief are the record.
