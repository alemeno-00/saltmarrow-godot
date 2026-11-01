# Job 15-W — approved keys, full south walk delivery

Julian approved keys 1,3,5,7 on 2026-11-01: “yeah they look good”. `approval.json` records their SHA-256 hashes. The final walk uses their exact pixels unchanged. Four independent edits of their own supplied guides supply frames 2,4,6,8; eight independent normal-guide edits supply the normal paintings. No frame is generated from its neighbour. The upstream prompt is archived in `../15w-step-a/upstream-PROMPT.md`.

## Final layout and checks

`../../s.png` and `../../s_n.png`: 640 × 160; 80 × 80 frames. Row 1 is six exact approved-model copies plus two clear cells; row 2 is eight south walk frames, 10 fps. Root (40,72). See `../README.md` for the 2560 × 320 painting rows and 640 × 80 shrunken rows.

The unchanged supplied Godot 4.7.2 shrink/check tools produced the rows and checked the **actual complete delivered runtime sheet**. All eight frames PASS: outline overlap 88–91%, each anatomical sole at its own exact guide height, head match 100%. Unlike the historical Step A API driver, no placeholder guides stand in for finished walk frames. Binary alpha and exact diffuse/normal alpha match, model-only palettes, one-pixel guide envelopes, positive-Z unit normals (within 0.006), idle/padding layout, immutable approved keys and protected sources also pass `validate_delivery.py`. Numerical checks do not replace in-game art review. Local Godot emits restricted user-data/certificate warnings; the image commands return success and the checker prints PASS.

## Painting / registration limits

As accepted in Step A, each guide’s top 32 game rows and bottom 13 rows (from 67) are retained exactly, rather than accepting generated head/boot drift. The independent paintings clean up the middle body, coat and upper legs. Whole-figure nearest-neighbour bounding-box registration fits each larger generated source to its own guide; no individual limb is moved, rotated or mirrored. The one-pixel alpha envelope clips protrusions and restores missing original guide blocks. Three short original-guide connections restore detached wrist/fringe clusters in even frames; every coordinate is recorded in `registration.json`. The unchanged approved frame 5 retains a three-pixel guide edge cluster; it is recorded in `validation.json`, not silently repainted.

Normals use the same own-frame head/boot preservation, whole-figure fit and exact final diffuse alpha. Missing normal coverage is extended from the nearest existing normal in that same frame, then positive-Z vectors are normalized and snapped by the supplied tool to the approved normal palette. Counts and bounds are in `normal-registration.json`. No normal is copied from an adjacent walk frame.

## Reproduction

Use Python with Pillow for the archive utilities. Run `register_inbetweens.py`, `assemble_diffuse.py`, then the unchanged upstream `walk_guides.gd -- shrink` on `../walk_s_4x.png` to produce `../walk_s.png`. Refresh each `painted-NN-palette-4x.png` by enlarging the corresponding final game frame 4× with nearest neighbour. Run `register_normals.py`, then upstream shrink on `../walk_s_n_4x.png` to `../walk_s_n.png` with the trailing `normal` argument. Run `assemble_runtime.py`, upstream `-- check` on `../../s.png`, save its eight frame lines and PASS to `guide-check.txt`, then run `validate_delivery.py` and `export_previews.py`. Tool code remains unchanged outside assets.

## Claude handoff

Prefer the painted **south idle/walk** over the currently higher-priority rig. Only two rows exist: do not register/sample wounded-walk, sneak or careful-step rows 3–5 from this sheet. Preserve existing rig/legacy fallback for those actions and other directions. Keep normal maps and grounding active. In-game approval is still needed before more directions.

## File inventory

All `NN` numbers below are explicit frame positions in the final eight-frame row. Guide and registered painting images are single-frame 320 × 320 PNGs; raw generated sources retain their original canvas sizes and are not sprite sheets. No gaps occur in assembled rows. Each filename is listed below.

| File | Purpose / layout |
| --- | --- |
| `.gdignore` | Exclude sources from imports |
| `README.md` | This inventory and handoff |
| `approval.json` | User approval and immutable Step A key checksums |
| `assemble_diffuse.py` | Interleave approved keys and new even-frame paintings |
| `assemble_runtime.py` | Copy idle models and final walk rows into runtime sheets |
| `export_previews.py` | Mechanical boards and 10 fps room/neutral GIF composites |
| `frame-02-4x.png` | Constrained independent diffuse painting input to supplied shrink; 320 × 320 |
| `frame-02-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `frame-02-registered-edit-4x.png` | Whole-figure fitted edit before preservation/envelope constraints; 320 × 320 |
| `frame-02-source-v1.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `frame-04-4x.png` | Constrained independent diffuse painting input to supplied shrink; 320 × 320 |
| `frame-04-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `frame-04-registered-edit-4x.png` | Whole-figure fitted edit before preservation/envelope constraints; 320 × 320 |
| `frame-04-source-v1.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `frame-06-4x.png` | Constrained independent diffuse painting input to supplied shrink; 320 × 320 |
| `frame-06-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `frame-06-registered-edit-4x.png` | Whole-figure fitted edit before preservation/envelope constraints; 320 × 320 |
| `frame-06-source-v1.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `frame-08-4x.png` | Constrained independent diffuse painting input to supplied shrink; 320 × 320 |
| `frame-08-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `frame-08-registered-edit-4x.png` | Whole-figure fitted edit before preservation/envelope constraints; 320 × 320 |
| `frame-08-source-v1.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `guide-02-4x.png` | Exact corresponding upstream diffuse-guide crop; 320 × 320 |
| `guide-04-4x.png` | Exact corresponding upstream diffuse-guide crop; 320 × 320 |
| `guide-06-4x.png` | Exact corresponding upstream diffuse-guide crop; 320 × 320 |
| `guide-08-4x.png` | Exact corresponding upstream diffuse-guide crop; 320 × 320 |
| `guide-check.txt` | Actual eight-frame upstream checker result, PASS |
| `inbetweens-4x.png` | 1280 × 320, one row of four new even frames 2,4,6,8; 1280 × 320 |
| `limb-key-02-4x.png` | Exact anatomical left/right colour-key guide crop; reference only; 320 × 320 |
| `limb-key-04-4x.png` | Exact anatomical left/right colour-key guide crop; reference only; 320 × 320 |
| `limb-key-06-4x.png` | Exact anatomical left/right colour-key guide crop; reference only; 320 × 320 |
| `limb-key-08-4x.png` | Exact anatomical left/right colour-key guide crop; reference only; 320 × 320 |
| `normal-01-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-01-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-01-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-02-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-02-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-02-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-03-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-03-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-03-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-04-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-04-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-04-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-05-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-05-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-05-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-06-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-06-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-06-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-07-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-07-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-07-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-08-4x.png` | Registered independent normal painting; exact final diffuse alpha; 320 × 320 |
| `normal-08-prompt.txt` | Exact executed built-in image-tool prompt for this frame |
| `normal-08-source.png` | Original independent built-in image-tool output, one figure; source only; 1254 × 1254 |
| `normal-guide-01-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-02-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-03-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-04-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-05-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-06-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-07-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-guide-08-4x.png` | Exact corresponding upstream normal-guide crop; 320 × 320 |
| `normal-registration.json` | Normal bounds, preservation and same-frame extension counts |
| `painted-01-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-02-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-03-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-04-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-05-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-06-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-07-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `painted-08-palette-4x.png` | Final diffuse frame enlarged 4×; normal-painting reference; 320 × 320 |
| `register_inbetweens.py` | Own-guide registration, preservation masks and recorded guide repairs |
| `register_normals.py` | Own-guide normal registration, alpha alignment and normalization |
| `registration.json` | Diffuse bounds, source selection, clipped/restored/connection blocks |
| `validate_delivery.py` | Palette, alpha, layout, pose envelope, provenance and immutable-reference audits |
| `validation.json` | Final content audit including minor connected components |

`previews/` has its own complete inventory. All paintings face south.
