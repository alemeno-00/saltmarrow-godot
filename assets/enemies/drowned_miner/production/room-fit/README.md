# Job15a — room integration production

Read against merged `ART_JOBS.md` house style and `design/art-briefs/animation/BRIEF.md` on2026-10-30. Built-in image generation supplied material studies and rounded normal-map studies; no API/CLI fallback was used. Full prompts are retained beside the sources.

Diffuse studies are material/value references, not drop-in poses: some generated attack studies move internal details. The final colour conversion retains ORIGINAL pixel clusters and exact alpha, transfers the study's value distribution, and quantizes to the shared room palette. Thomas uses a common value curve across all three sheets. Julian explicitly approved muted-red accents for scarf and blood; the room palette has no reds. Contact-dark grading changes only existing bearing pixels, never adds shadow geometry. The original native raster grain is preserved, with no scaling of runtime figures relative to room pixels.

Generated normal studies are nearest-registered per frame to the original alpha bounds, masked by the exact original binary alpha, and normalized into positive-Z unit vectors. Empty cells stay empty. Small gaps in source study coverage extend the nearest valid normal colour before masking. This is a simplified normal treatment at the existing resolution; the exact pose/detail comes from the unchanged diffuse structure. Normal maps encode +R right, +G up, +B forward. Generated studies are large source atlases, not runtime frame-size exports; the registration JSON records sampled cells and native bounds.

House checks: (1)local coloured edges, no pure-black outline; (2)room palette with approved red exception; (3)native wear/texture clusters retained; (4)value separation reviewed against paving, original limb gaps; (5)damp existing contact pixels, no new shadow; (6)neutral albedo; (7)matching non-flat normal volumes; (8)job15a keeps64×64/root32,56.80×80 begins job15. Props retain their individual sizes.

Runtime file/frame inventories are in `../../README.md`. Original character frames remain64×64, foot origin32,56; diffuse and normal atlas row counts match exactly. `*-input-2x.png` are nearest review inputs, not runtime assets. Generated colour/normal masters are single static source atlases; companion prompts and registration JSON describe their intended layouts and actual sampling. Per-row GIFs use256×256 preview frames, with frame counts reported below.

## Reproduction and reviews

Run `assets/characters/thomas/production/room-fit/export.py`, then `assets/props/sewers/production/house-style/export.py`, then Thomas's `room-fit/validate.py`, with Python/Pillow. Original earlier-stage exporters must be followed by these steps or they overwrite the current pass. No game code is edited.

Room comparison: before left, after right, identical native pixel density and placements. Light-review columns: original, neutral current albedo, light from left, light from right. Props' normal-light-review has neutral/left/right columns in manifest order, excluding UI icons. These are compositing/controlled-normal reviews, not engine screenshots. Actual lantern strength and mirrored normal response remain an in-game review.

## File inventory

| File | Format / role |
| --- | --- |
| `.gdignore` | Exclude production files from Godot imports |
| `body-before.png` | 384×1024; original diffuse atlas, native frame counts in runtime README |
| `body-colour-master.png` | 768×2048; one static generated source atlas; use registration/prompt for state sampling |
| `body-colour-prompt.txt` | Full built-in generation/edit prompt |
| `body-fitted-2x.png` | 768×2048; one static nearest-sampled review atlas/image |
| `body-input-2x.png` | 768×2048; one static nearest-sampled review atlas/image |
| `body-light-review.png` | 1024×768; one static nearest-sampled review atlas/image |
| `body-normal-master.png` | 768×2048; one static generated source atlas; use registration/prompt for state sampling |
| `body-normal-prompt.txt` | Full built-in generation/edit prompt |
| `body-registration.json` | Registration / file-check records |
| `body-row-1.gif` | 256×256; 4 frames; row animation review |
| `body-row-10.gif` | 256×256; 2 frames; row animation review |
| `body-row-11.gif` | 256×256; 4 frames; row animation review |
| `body-row-12.gif` | 256×256; 6 frames; row animation review |
| `body-row-13.gif` | 256×256; 6 frames; row animation review |
| `body-row-14.gif` | 256×256; 6 frames; row animation review |
| `body-row-15.gif` | 256×256; 6 frames; row animation review |
| `body-row-16.gif` | 256×256; 6 frames; row animation review |
| `body-row-2.gif` | 256×256; 6 frames; row animation review |
| `body-row-3.gif` | 256×256; 3 frames; row animation review |
| `body-row-4.gif` | 256×256; 3 frames; row animation review |
| `body-row-5.gif` | 256×256; 3 frames; row animation review |
| `body-row-6.gif` | 256×256; 3 frames; row animation review |
| `body-row-7.gif` | 256×256; 3 frames; row animation review |
| `body-row-8.gif` | 256×256; 4 frames; row animation review |
| `body-row-9.gif` | 256×256; 4 frames; row animation review |
| `README.md` | This inventory and house-style audit |
