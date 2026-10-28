# Playable sewer fight — integration prototype

This is a real Godot scene that reuses Claude's Game, Battle, ActorView, Hero, EnemyView, combat HUD, movement and mace abilities from main commit `bc700be`. The integration adds a fixed encounter map and an art renderer through small subclasses; the original combat implementation and default main scene are unchanged.

Double-click `play-sewer.command` at the repository root on macOS with Godot installed. Alternatively run Godot with this project and `res://scenes/sewer_fight.tscn`. The default project launch still opens Claude's procedural scene. Tested with Godot 4.7.2, Compatibility renderer, on this machine; the project declares Godot 4.6, which was not separately tested.

## Controls

- Click a highlighted square or use WASD/arrows to move.
- Click an adjacent enemy to strike; 1–5 select mace abilities.
- F: careful step; Q: stand; B: catch breath; Enter: end turn.
- Mouse wheel: zoom. R: restart the fixed encounter with a new encounter seed.

Thomas faces one Drowned Miner and three Faithful. Movement, initiative, enemy AI, Resolve, Malice, injuries, damage, death and victory use Claude's existing rules. Placeholder character drawings and UI are inherited. No new combat rules or balance changes are introduced.

## Art and collision limits

`corridor-backdrop.png` is the generated corridor-v2 benchmark, copied unchanged: 1774 × 887, one static opaque frame, no animation rows, slightly angled top-down. It is actually imported and rendered in Godot, with runtime actors, movement highlights and combat effects above it. It is **one flattened backdrop, not a modular atlas assembly**. Painted torches, arches and props are static. There is no foreground occlusion layer, water animation or dynamically lit masonry. This is a playable art-direction test, not the finished sewer biome.

The grid stays 32 × 32. Authored dry cells align to the rear maintenance walk, two-cell timber crossing and narrow front walk. The inset grate is load-bearing. All off-route pixels, deep channel and masonry are blocked using the existing wall collision category; there is no swimming/flooding behaviour or water-entry damage. The right curved return, painted ladder and arch outfall are scenery rather than additional exits. The illustrative background's exact original grid was never production-registered, so this fixed registration needs human play review before expansion.

Character frames, equipment layers and animations from ART_JOBS remain outstanding. The background provenance and exact generation prompt are preserved in the adjacent `benchmarks` folder. Its generated player-containing gameplay simulation is not used by the engine.

## Verification

- Claude's existing suite: **43 passed, 0 failed**.
- `tests/test_sewer_scene.gd`: checks real scene instantiation, four enemies, sight-triggered Battle, hero turn after initiative, imported art renderer, blocked water/masonry, bridge route, inherited combat movement, actual strike damage/playback and fresh-actor restart via R.
- The same smoke test runs with the graphical renderer and saves `fight-start.png` / `fight-after-strike.png`. These are real Godot viewport captures, not generated pictures.
- Native UI automation was unavailable because Computer Use permissions were not granted. Gameplay was exercised through the scene's movement, click handler and keyboard-event handler by the engine smoke test; manual mouse/keyboard play remains for the user.

Run existing tests with `godot --headless --path . -s tests/run_tests.gd`; integration test with `godot --headless --path . -s tests/test_sewer_scene.gd`; real renderer captures with `godot --path . -s tests/test_sewer_scene.gd -- --capture`.

The user explicitly requested using Claude's code for a playable fight after the original art-only task. This branch confines integration to two new scripts, an inherited scene, a launcher and an isolated smoke test. No combat, movement, default scene or project-setting files are replaced.
