# Generated sewer fight v0.1

Open `play-generated-sewer.command` at the repository root, or `scenes/generated_sewer_fight.tscn` in Godot. The launcher imports project resources before opening the scene, including on a fresh checkout. The older `play-sewer.command` and default main scene remain available for comparison.

This scene connects SewerAssembler's actual cells and metadata to Claude's inherited Game/Battle, HUD, movement, enemy AI, abilities and effects. R advances the seed and regenerates the level and encounter. The exported `water_state` property selects low/normal/high before launching; normal is the default. Existing fight controls apply: movement keys or highlighted cells, adjacent-enemy click to strike, 1–5 abilities, F careful step, Q stand, B catch breath, Enter end turn, wheel zoom.

## What is now real

- The generated SewerLevel, rather than a fixed map or image, supplies collision and AStar paths. Deep water is blocked, bridges are dry, and the service branch is reachable.
- One miner and three Faithful spawn deterministically on four distinct dry cells reachable from Thomas, within sight-trigger range. Spawn ranking uses dry path length and seeded ordering. The encounter starts through the existing sight/initiative code, not a replacement combat engine.
- `sewer_tile_view.gd` draws actual 32px terrain PNGs, compatible shoreline tiles, wall faces, bridge deck pieces and fixture sprites from the assembly. It does not load the flattened corridor benchmark or generated gameplay illustration.
- `fight-start.png` and `fight-after-strike.png` are actual 1280 × 720 Godot captures. One static frame each, no animation rows or facing convention applies to these evidence images.

## Verification

`audit.json`: 300 combinations (100 seeds × three water states), zero placement failures. Checks cover count, dry cells, reachability, no overlaps, sight eligibility and deterministic placement. The underlying assembler's separate 3,000-case audit remains applicable.

The end-to-end scene smoke test passes spawning, sight-triggered combat, hero turn after enemy initiative, generated renderer/map, blocked channel, a dry route to the service chamber, actual movement, strike damage/playback, fresh-actor restart and seed advancement. It exercises the same game methods as input handlers; manual mouse/keyboard play remains a separate review. It also ran with Godot 4.7.2's graphical Compatibility renderer for captures. Original suite: 43 passed. The fixed-backdrop encounter remains covered by the same test script without the generated flag.

Commands: `godot --headless --path . -s tests/audit_sewer_encounters.gd`; `godot --headless --path . -s tests/test_sewer_scene.gd -- --generated`. For actual graphics captures omit `--headless` and append `--capture` after the argument separator.

## Remaining limits

**Prototype art only.** The terrain/props are the earlier MVP exports and the actors/UI are Claude's placeholders. This is NOT concept-fidelity approval. Walls are basic edge caps/front faces, with no complete curved orientation kit or foreground actor occlusion. Torch/water images are static, there is no dynamic light or sluice animation, and the bridge deck reuses a repeated texture region. Further art work is required before this resembles the approved benchmark.

The seven-family assembler still uses a bounded five-module graph. It is not a full 30-archetype biome or arbitrary topology generator. No hydraulic simulation, biome transitions or other five biome grammars are added here. Automated placement and one exercised combat sequence do not certify encounter fairness or victory/death balance across seeds. Deep-water push damage and environmental interactions are not implemented. Godot 4.6 was not separately tested.
