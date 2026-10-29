# Godot generation audit and viewer

Tested 29 October 2026 with Godot 4.7.2's real Level.generate implementation. This tests the existing **generic** room-and-corridor generator, not six implemented biome generators. The sewer fight remains a fixed encounter; the art benchmark is a static backdrop and is not procedurally assembled.

## Open the viewer

Double-click `test-generation.command` at the repository root, or launch `res://scenes/generation_lab.tscn` in Godot. R / Right advances the seed; Left returns to the previous seed; T switches the diagnostic floor/water texture display; P toggles the route to the last room. Click a cell to inspect its tile and walkability. The default display shows topology with no simulated atmosphere obscuring the layout. The optional textures are the old MVP floor/water exports, not a claim of fidelity to the approved concept.

The data grid is 60 × 40 cells at the game's 32px standard; the viewer draws a 50% overview. White is dry floor, blue is currently walkable water, amber is a closed door, green is the starting cell, and cyan marks the actual AStar path. Room bounds are outlined. The viewer calls the same generator as the normal main scene and does not introduce alternative generation rules.

## Audit results

`audit.json` records **1,000 seeds (1–1000), 1,000 unique layouts, zero failing seeds**. All samples produced 12 rooms. Checks cover:

- Same-seed tiles, room bounds and start repeatability.
- Walkable start, valid tile values, sealed outer boundary and minimum room count.
- All walkable cells reachable using current movement rules.
- Room bounds and two-cell spacing.
- Reachable room centres and legal AStar steps, including diagonal corner restrictions.
- Tile/start save-load roundtrip and equivalent restored reachability.

The viewer smoke test also passes advancing the seed, returning to the identical previous map, toggling textures and rendering seeds 1, 7 and 42. `seed-1.png`, `seed-7.png` and `seed-42.png` are actual 1280 × 800 Godot viewport captures, one static frame each; no animation rows or sprite-facing metadata apply. These are diagnostic views, not image-generated predictions. Claude's existing suite still passes 43/43.

Run the audit with `godot --headless --path . -s tests/audit_generation.gd`. Run viewer checks with `godot --headless --path . -s tests/test_generation_lab.gd`; append `-- --capture` and omit `--headless` for graphical captures. These dedicated tools are separate from the original test runner. The audit overwrites its own report.

## What these passing tests do not establish

Water and closed doors count as walkable in the current Level rules. This audit does not certify dry-only connectivity, staged sluices/flooding, exits between floors, encounter balance, character clearance through art, or room-purpose realism. It checks the standard 60 × 40 map size, not arbitrary dimensions.

The current algorithm creates separated rectangular rooms joined by one-cell L-shaped corridors, adds loops/doors, then paints a small water patch in one room. It has no biome argument or distinct Ruins/Sewers/Mines/Fortress/Caves/Sunken grammar, no 30-archetype libraries, no sewer drainage-spine/circular-cistern assembly, and no transition modules. Those remain implementation work. Passing connectivity must not be presented as acceptance of the seven biome design principles.
