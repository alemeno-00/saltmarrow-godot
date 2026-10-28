# Sewer fidelity v2 — layered art review

**Unapproved visual candidate.** This is a working Godot corridor with separate textures, sprites and wear layers. `godot-corridor.png` is captured from the engine; it is not a generated scene illustration. `godot-corridor-clean.png` has the same paving without wear. `overlay-review.png` shows each exported decal over a checker and over paving at its suggested opacity.

Open `review-sewer-art.command` at the repository root. **O** toggles wear; **Tab** toggles the existing combat HUD. Existing movement/combat controls apply. This is a fixed art acceptance corridor, not a replacement for the procedural sewer renderer. The old generated-fight scene still uses its earlier art.

## What is usable here

- Eight paving assemblies: six 128×64, one 96×64 and one 64×64. Large irregular flags, long service slabs, repair strips, grooves and smaller infill. Each spans multiple 32px movement cells. Twelve 32×32 fallback floors remain for small thresholds.
- Eight genuinely transparent overlays: cracks 128×64; damp 96×64; salt 64×64; moss 96×64; chips 64×64; silt 64×64; repair 96×64; seep 128×32. They have irregular silhouettes and no backing floor. Suggested opacity is in the manifest; alpha coverage ranges from 2.3–12.2% of their canvas. These are deliberately sparse details, not collision or hazard indicators.
- Three 128×128 wall modules, an integrated 128×128 arch, 32×128 piers/pipes, 32×16 bank face, and earlier smaller proportion studies. The tall walls assemble generated brick courses rather than stretching the brick pixels vertically.
- Four 64×64 water substrates, sampled as fixed 32px quadrants in a 2×2 block. Change variant per block; independently random quadrants would break the pattern. Static, not animation.
- Bridge 64×160, drain 64×64 and torch 32×48, with transparent silhouettes.
- Three static right-facing 64×64 character frames. Feet registered at (32,56); the review renders frames at 80×80 for a 60px visible body, preserving the feet at local (0,12). This larger proportion is a user-requested review adjustment, not a change to the repository's 64px source-frame standard. These are not finished animation sheets or ART_JOBS deliveries.

57 exports total, including unselected early proportion studies. The manifest marks selections, dimensions, origin, native atlas region and hash. Both atlases store native pixels without resizing; allocation starts on 32px boundaries. The 48px torch height occupies a 64px storage slot.

## Assembly and layering

Draw the paving assemblies first, then sparse wear, raised banks/walls, props, actors and effects. Keep the floor slabs independent of the movement grid. Choose differently sized assemblies along a walk; don't scatter 1-cell floor variations as the main surface. In this corridor the maintenance walks are two cells deep, with a three-cell drainage channel and a supported crossing.

Place damp below pipes, seepage and salts near wall feet, moss in wet joints, and silt toward drainage. Place repair patches and cracks across selected surfaces rather than on every tile. Do not rotate direction-sensitive bevels or runnels arbitrarily. Do not cover navigation cues or put decorative dark damage where it could read as a hole. O toggles the eight wear types only; paving relief remains visible.

Paving pieces share a dark mortar edge. Exact edge equality is tested, but this does **not** certify seamless internal stone layouts under arbitrary rearrangements. Some assembly boundaries remain visible in this candidate. Water and floor families have matching opposite boundaries; water block sampling and native atlas extraction are tested separately.

## Godot conventions and collision

PNG RGBA, hard binary source alpha, zero RGB under transparent pixels. Use lossless import, nearest filtering, mipmaps off and repeat disabled. Runtime decal opacity supplies subtle blending; source silhouettes remain hard. Native atlas regions exclude allocated padding; use the manifest region dimensions, not an entire storage slot. No TileSet resource is supplied by this revision.

Overlay and paving origins are top-left. Masonry origins are bottom-centre; the custom review renderer uses top-left drawing explicitly, so convert from the manifest origin when placing a Sprite2D. Props use bottom-centre; actors use (32,56). Never derive a ground collision box from the full tall wall or sprite canvas. Wear has no collision. Deep water is blocked; the bridge has one clear lane in column 19 with decorative rails outside it. Arch opening aligns with clear cell (26,7), while its adjoining piers are blocked. Other room placements need their own authored ground masks.

## Provenance and verification

`source/` contains **new built-in-generated** material families, figures, props, paving and decals, with exact prompts in `source/PROMPTS.md`. The approved Sewer Tileset v0.2 and `../benchmarks/corridor-v2.png` were visual references. None of these exports is claimed as a cutout or pixel conversion of the approved concept. Mechanical export operations—cropping, nearest registration, hard-alpha cleanup, shared boundary normalization and native atlas packing—are in `tooling/`.

Rebuild with `python3 tooling/build.py` (requires Pillow). Run `Godot --headless --path <repo> --script res://tests/capture_fidelity.gd` for the physical checks. For actual screenshots run the same command with a graphical renderer and append `-- --capture`; then run `python3 tooling/review_sheet.py` for the catalogue and pixel-change report. `validation.json` and `engine-validation.json` record checks. The existing 43 core tests pass.

## Remaining before production acceptance

User visual review is still required. This corridor does not prove exact concept fidelity. Rounded corners, curved junctions/cistern masonry, a complete directional bank/transition kit, animated water, character motion/reaction sheets and their lighting/scale need further work. Floors now use broad shapes and wear, but finite module repetition and the dark figures still need assessment. Integration of this material family into the procedural renderer and 30 sewer archetypes is not delivered by this isolated scene. No main scene, core combat rule or default project configuration was replaced.
