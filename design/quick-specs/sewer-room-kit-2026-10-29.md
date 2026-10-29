# Quick Design Spec: Sewer room kit

**Type**: New Small System
**Scope**: How Sewers levels (depths 1–3) are built from painted rooms and connecting pieces. Replaces the earlier spine-and-channel draft, which was never written. Not included: treasure, secret, puzzle and trap rooms (they need items, hidden doors, puzzle and trap rules), and other biomes.
**GDD Reference**: `design/game-brief.md` (MVP item 5, build order step 2, Level art). No GDD at `rigor: minimal`.
**Date**: 2026-10-29
**Estimated Implementation**: about a week of code; the art is separate. This is the top of quick-spec size: if it grows (changing water levels, room states), move it to a full design doc.

## Overview

A level is a set of rooms joined by connecting pieces, on one grid with one door standard. The generator picks room types and layouts, chains them, and picks a random painting for each layout. Until a layout has paintings, the game draws it with today's stand-in tiles, so the generator can be built and played before any art arrives. Painted rooms follow the method tested with the Outflow (`design/art-briefs/outflow/BRIEF.md`): ChatGPT paints over a blockout at game scale with neutral light; the game adds darkness and lantern light.

## Core Rules

1. **Blocks.** Room and connector sizes, walls included, are multiples of 4 squares: 8 × 8, 12 × 8, 8 × 12 and 12 × 12. Connectors are 4 squares across: wall, a 2-square walkway, wall. The Outflow is the one exception and keeps its own 14 × 11 layout (`design/quick-specs/first-shift-boss-2026-10-29.md`, `design/art-briefs/outflow/`).
2. **The door standard.** At most one door per side. A door is 2 squares wide, centred on its side. Each layout's data lists which sides have doors. A door is valid only if it faces a matching door in the next piece. Unused doors are walled off.
3. **The blockout is the data.** Each layout is a small image with one flat colour per square: wall face, wall top, floor, shallow water, door, lantern spot (the Outflow blockout's colours). The game reads it to build the room's squares; ChatGPT paints over the same image, so rules and painting come from one file.
4. **Room types for the first version:**

   | Type | Size | Layouts | Paintings each | Notes |
   |---|---|---|---|---|
   | Connectors: straight, bend, T, crossing, dead end | 4 × 4 to 4 × 12 | 5 shapes | 2 | Chained between rooms |
   | Entry (start, ladder up to town) | 8 × 8 | 1 | 2 | Always the first room |
   | Junction (central rooms) | 12 × 12 | 3 | 3 | Most fights happen here |
   | Chamber | 12 × 8 / 8 × 12 | 3 | 2 | Some with shallow water |
   | Flooded chamber / cistern | 12 × 12 | 2 | 2 | Water with a dry walkway around it |
   | Lore room | 8 × 8 | 2 | 1 | Story told through the setting; at most one per level |
   | Stairs down | 8 × 8 | 1 | 2 | Depths 1–2 |
   | Boss: the Outflow | 14 × 11 | 1 | 1 | Depth 3; already briefed (art job 12) |

   19 layouts and about 40 paintings, before mirroring.
5. **Mirroring.** A painting marked mirrorable may be flipped left to right as a free extra variant (needs neutral light and no text). Never top to bottom: the north wall shows its face.
6. **The generator.** Builds a tree of 8–12 rooms out from the entry, joined by connectors. The stairs (on depth 3, the Outflow) go at the end of the longest branch; at most one lore room per level; never the same layout twice in a row.
7. **Enemies** go in junctions and chambers, never in the entry, never within 15 steps of the start. The stairs room has a group half the time.
8. **A fresh world every life.** A new life picks a random seed; each depth's seed comes from that seed and the depth. A given seed always builds the same level, so tests stay exact.
9. **Saving** a level keeps which room, layout and painting went where.
10. **Art delivery.** Paintings go in `assets/tiles/sewers/rooms/<layout>/<variant>.png`, with a README per folder. Claude writes the blockouts and briefs; ChatGPT paints. Paintings are ordered only once the Outflow test is approved.

## Tuning Knobs

| Knob | Default | Range | Category | Rationale |
|------|---------|-------|----------|-----------|
| Rooms per level | 8–12 | 6–16 | gate | A run of three levels stays short |
| Branches from the main path | 2–4 | 1–5 | feel | Room to explore beyond the route down |
| Lore rooms per level | 0–1 | 0–2 | feel | Rare enough to notice |
| Chance a chamber is flooded | 30% | 0–60% | feel | Sewer character without slowing every fight |
| Chance of a mirrored painting | 50% | 0–100% | feel | Free variety |
| Enemy distance from the start | 15 steps | 8–25 | gate | A quiet start |
| Chance the stairs are guarded | 50% | 0–100% | feel | Less predictable |

Values live as named constants in the code, as with the boss: `assets/` belongs to ChatGPT, so `assets/data/` is not used.

## Acceptance Criteria

- [ ] Over 300 seeds, every level is fully reachable, every door meets a matching door, and no door opens into a wall. *(test)*
- [ ] Every placed room matches its blockout square for square, mirrored ones included. *(test)*
- [ ] No layout appears twice in a row; at most one lore room; the stairs or Outflow sit at the end of the longest branch. *(test)*
- [ ] A layout without paintings is drawn with stand-in tiles; one with paintings shows a random one. *(test + retained screenshot)*
- [ ] A new life gets a different layout; the same seed gives the same level. *(test)*
- [ ] Saving and loading keeps rooms and paintings. *(test)*
- [ ] The Outflow and all boss tests are unchanged. *(test)*
- [ ] Feel (playtest): levels feel varied over several runs; fights in junctions feel different from fights in chambers.
- [ ] No regression: all existing tests pass.

## Order of Work

1. The door standard, the blockout reader, and the generator, drawn with stand-in tiles (no art needed).
2. Blockouts and paint-over briefs for each layout, once the Outflow painting is approved.

## Systems Index

This system is below systems-index tracking threshold — quick spec is sufficient.
