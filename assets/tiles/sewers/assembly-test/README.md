# Sewer assembler v0.1 — working topology prototype

Implemented 29 October 2026. Open `test-sewers.command` at the repository root or `scenes/sewer_generation.tscn` in Godot. R/Right: next seed; Left: previous; L/N/H: low/normal/high water; S: compare generic rooms; T: optional old-MVP floor/water textures; P: dry AStar route. This scene actually runs the new assembler in Godot. The default topology view is deliberate: it verifies architecture and navigation independently of unapproved art.

## Implemented grammar

- Start from a drainage trunk and perpendicular upstream/service branches, rather than scattering generic rooms.
- Stamp five purpose-labelled modules per level from seven initial families: circular cistern, rounded junction, settling basin, sluice chamber, upstream outfall, maintenance chamber and pump chamber. Seeded choices change families, pool footprints, basin shapes, branch lengths and dressing while preserving the trunk/branch graph. These are grid masks with rounded/elliptical silhouettes, not finished curved masonry sprites.
- Join explicit opposing ports. Every port declares cell position, width (7 cells), waterline, wall-face depth and bank height. These dimensions are initial renderer handoff values (48px wall face / 8px bank height), not measurements recovered from the concept. All modules share them; approved production art may require coordinated changes.
- Reserve dry maintenance banks around blocked deep water. Two supported bridge decks preserve connected water beneath them via explicit metadata. Level movement and AStar agree that deep water is blocked, including after a runtime tile edit.
- Generate low, normal and high water layouts while preserving a connected dry network. This regenerates a static layout; it does not animate a tide or simulate fluid/gate pressure.
- Place nonblocking pipe/torch fixtures only beside masonry, drains at collection points, and cosmetic cracked-wall markers without changing collision. Sluice markers declare an open state; gate actuation is not implemented. No random rubble obstructs required routes.
- Export each module's purpose, variant, origin, footprint, anchor, allowed transform, ports, clear-cell mask and solid-cell mask; plus global connections, water-under cells, bridges and dressing in `SewerLevel.assembly`. `SewerAssembler.restore()` preserves sewer movement semantics across save/load.

## Verification

The Godot audit runs seeds 1–1000 in all three water states: **3,000 assemblies**. `audit.json` records the final result, unique assembly/geometry counts and engine version. It checks deterministic tiles/metadata, connected dry navigation, connected drainage including under bridges, sealed map boundaries, opposing/aligned compatible ports, actual drainage and dry banks at mouths, supported walkable bridge decks, valid wall-mounted fixtures, unchanged cracked-wall collision and sewer-aware save/load reachability.

`tests/test_sewer_lab.gd` checks all three states have a dry route, generic/sewer comparison, deterministic return and runtime water mutation updating AStar. With `-- --capture` it records `low.png`, `normal.png` and `high.png`: real 1280 × 800 Godot viewport captures, one static frame per file, no animation rows or facing metadata. The existing generic viewer test and all 43 original tests also pass. Tested with Godot 4.7.2 Compatibility, not separately with declared Godot 4.6.

Commands: `godot --headless --path . -s tests/audit_sewers.gd` and `godot --headless --path . -s tests/test_sewer_lab.gd`. For actual renderer captures, omit `--headless` and append `-- --capture` to the viewer test.

## Remaining work

This is an initial reusable-piece grammar, **not the promised full 30-archetype library**. It has a bounded five-module trunk/branch topology, not arbitrary graph growth or room counts. Add further room purposes, genuine 90-degree curved tunnel modules, alternate graph patterns, sluice operation, stateful hazards and dedicated biome transitions before treating it as a complete biome generator.

The assembler is available in the inspection scene; the original default procedural game and fixed-backdrop sewer fight remain unchanged. It has not been wired into a generated combat encounter. Finished wall/arch/corner art, modular sprite assembly, foreground occlusion and final prop/collision approval remain separate work. T uses earlier prototype textures and does not certify concept fidelity. The six-biome shared connection standard and other five biome grammars remain outstanding.
