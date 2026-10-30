# Job15a — room integration production

Read against merged `ART_JOBS.md` house style and `design/art-briefs/animation/BRIEF.md` on2026-10-30. Built-in image generation supplied material studies and rounded normal-map studies; no API/CLI fallback was used. Full prompts are retained beside the sources.

Diffuse studies are material/value references, not drop-in poses: some generated attack studies move internal details. The final colour conversion retains ORIGINAL pixel clusters and exact alpha, transfers the study's value distribution, and quantizes to the shared room palette. Thomas uses a common value curve across all three sheets. Julian explicitly approved muted-red accents for scarf and blood; the room palette has no reds. Contact-dark grading changes only existing bearing pixels, never adds shadow geometry. The original native raster grain is preserved, with no scaling of runtime figures relative to room pixels.

Generated normal studies are nearest-registered per frame to the original alpha bounds, masked by the exact original binary alpha, and normalized into positive-Z unit vectors. Empty cells stay empty. Small gaps in source study coverage extend the nearest valid normal colour before masking. This is a simplified normal treatment at the existing resolution; the exact pose/detail comes from the unchanged diffuse structure. Normal maps encode +R right, +G up, +B forward. Generated studies are large source atlases, not runtime frame-size exports; the registration JSON records sampled cells and native bounds.

House checks: (1)local coloured edges, no pure-black outline; (2)room palette with approved red exception; (3)native wear/texture clusters retained; (4)value separation reviewed against paving, original limb gaps; (5)damp existing contact pixels, no new shadow; (6)neutral albedo; (7)matching non-flat normal volumes; (8)job15a keeps64×64/root32,56.80×80 begins job15. Props retain their individual sizes.

This folder audits all18 job14 props and supplies normals for the15 world sheets. The3 inventory icons are UI-only. Their geometry/state order and the recently redrawn body poses are unchanged. `export.py` applies the room palette to existing generated art rather than repainting its texture. Its runtime outputs and exact frame/row counts are all listed in `../../README.md`. Source masters each contain one static atlas; requested state layout is in the companion prompt and sampled cells in `registration.json`.

## Reproduction and reviews

Run `assets/characters/thomas/production/room-fit/export.py`, then `assets/props/sewers/production/house-style/export.py`, then Thomas's `room-fit/validate.py`, with Python/Pillow. Original earlier-stage exporters must be followed by these steps or they overwrite the current pass. No game code is edited.

Room comparison: before left, after right, identical native pixel density and placements. Light-review columns: original, neutral current albedo, light from left, light from right. Props' normal-light-review has neutral/left/right columns in manifest order, excluding UI icons. These are compositing/controlled-normal reviews, not engine screenshots. Actual lantern strength and mirrored normal response remain an in-game review.

## File inventory

| File | Format / role |
| --- | --- |
| `.gdignore` | Exclude production files from Godot imports |
| `bandage-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `barrel-before.png` | 64×32; original diffuse atlas, native frame counts in runtime README |
| `barrel-normal-master.png` | 1774×887; one static generated source atlas; use registration/prompt for state sampling |
| `barrel-normal-prompt.txt` | Full built-in generation/edit prompt |
| `bones_1-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `bones_1-normal-master.png` | 1536×1024; one static generated source atlas; use registration/prompt for state sampling |
| `bones_1-normal-prompt.txt` | Full built-in generation/edit prompt |
| `bones_2-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `bones_2-normal-master.png` | 1262×1246; one static generated source atlas; use registration/prompt for state sampling |
| `bones_2-normal-prompt.txt` | Full built-in generation/edit prompt |
| `bones_3-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `bones_3-normal-master.png` | 1254×1254; one static generated source atlas; use registration/prompt for state sampling |
| `bones_3-normal-prompt.txt` | Full built-in generation/edit prompt |
| `crate-before.png` | 64×32; original diffuse atlas, native frame counts in runtime README |
| `crate-normal-master.png` | 1774×887; one static generated source atlas; use registration/prompt for state sampling |
| `crate-normal-prompt.txt` | Full built-in generation/edit prompt |
| `debris_1-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `debris_1-normal-master.png` | 1536×1024; one static generated source atlas; use registration/prompt for state sampling |
| `debris_1-normal-prompt.txt` | Full built-in generation/edit prompt |
| `debris_2-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `debris_2-normal-master.png` | 1402×1122; one static generated source atlas; use registration/prompt for state sampling |
| `debris_2-normal-prompt.txt` | Full built-in generation/edit prompt |
| `debris_3-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `debris_3-normal-master.png` | 1774×887; one static generated source atlas; use registration/prompt for state sampling |
| `debris_3-normal-prompt.txt` | Full built-in generation/edit prompt |
| `diffuse-review.png` | 512×2304; one static nearest-sampled review atlas/image |
| `export.py` | Mechanical registration, palette conversion or validation/review script |
| `grate_ew-before.png` | 64×128; original diffuse atlas, native frame counts in runtime README |
| `grate_ew-normal-master.png` | 887×1774; one static generated source atlas; use registration/prompt for state sampling |
| `grate_ew-normal-prompt.txt` | Full built-in generation/edit prompt |
| `grate_key-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `grate_ns-before.png` | 128×64; original diffuse atlas, native frame counts in runtime README |
| `grate_ns-normal-master.png` | 1774×887; one static generated source atlas; use registration/prompt for state sampling |
| `grate_ns-normal-prompt.txt` | Full built-in generation/edit prompt |
| `hymn_sheet-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `hymn_sheet-normal-master.png` | 1254×1254; one static generated source atlas; use registration/prompt for state sampling |
| `hymn_sheet-normal-prompt.txt` | Full built-in generation/edit prompt |
| `letter-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `letter-normal-master.png` | 2172×724; one static generated source atlas; use registration/prompt for state sampling |
| `letter-normal-prompt.txt` | Full built-in generation/edit prompt |
| `miner_tag_body-before.png` | 64×32; original diffuse atlas, native frame counts in runtime README |
| `miner_tag_body-normal-master.png` | 1774×887; one static generated source atlas; use registration/prompt for state sampling |
| `miner_tag_body-normal-prompt.txt` | Full built-in generation/edit prompt |
| `normal-light-review.png` | 768×1920; one static nearest-sampled review atlas/image |
| `registration.json` | Registration / file-check records |
| `salve-before.png` | 32×32; original diffuse atlas, native frame counts in runtime README |
| `satchel_body-before.png` | 128×32; original diffuse atlas, native frame counts in runtime README |
| `satchel_body-normal-master.png` | 1774×887; one static generated source atlas; use registration/prompt for state sampling |
| `satchel_body-normal-prompt.txt` | Full built-in generation/edit prompt |
| `valve-before.png` | 128×32; original diffuse atlas, native frame counts in runtime README |
| `valve-normal-master.png` | 2164×727; one static generated source atlas; use registration/prompt for state sampling |
| `valve-normal-prompt.txt` | Full built-in generation/edit prompt |
| `README.md` | This inventory and house-style audit |
