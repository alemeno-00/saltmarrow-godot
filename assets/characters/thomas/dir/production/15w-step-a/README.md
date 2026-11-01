# Job15-W — Step A key-frame review

Status: **approved by Julian on 2026-11-01: “yeah they look good”.** The four approved keys remain unchanged. This folder preserves the original Step A review, including its limited checker scope. The completed eight-frame walk, new in-betweens, normal paintings and runtime-sheet audit are delivered in `../15w-step-b/`; see its README. Job 15-W is ticked with that complete delivery. The source instructions are copied word for word as `upstream-PROMPT.md`.

## Review outputs

- `key-01-1x.png`, `key-03-1x.png`, `key-05-1x.png`, `key-07-1x.png`: four individual80×80 south-facing review frames, numbered by their final eight-frame positions.
- `keys-1x.png`: those four frames in order1,3,5,7, one320×80 row. **This is a four-key review row, not an eight-frame walk.**
- `key-01-4x.png`, `key-03-4x.png`, `key-05-4x.png`, `key-07-4x.png`: corresponding320×320 registered painting inputs to the supplied shrink tool; preserve guide head and boot regions.
- `keys-4x.png`: the four painting inputs in one1280×320 row.
- `key-01-palette-4x.png`, `key-03-palette-4x.png`, `key-05-palette-4x.png`, `key-07-palette-4x.png`: the actual palette-snapped80×80 outputs enlarged4× to320×320. These show exactly the pixels in the1× review frames.
- `previews/`: source-guide comparison, key contact sheet and native room comparison; its README lists every preview.

## Painting and protected regions

Each frame is a separate built-in image-tool edit of its own upstream guide, with its own anatomical colour key. No frame starts from another painted frame, and no limb is mirrored or rotated by the exporter. The approved model defines face, scarf, strap, bag, lantern, coat and palette. The first-painted standing reference was used only in the rejected initial frame1 attempt.

The image tool repeatedly changed head/boot placement. The final constrained edit therefore preserves the supplied guide's original top32 game-pixel rows and bottom13 rows (from67) exactly. This keeps the approved head and the supplied boots/sole placement unchanged; these areas were **not repainted**. The independent painted edit supplies the middle body, coat and upper-leg cleanup. Registration is a whole-figure bounding-box fit from the larger tool output back onto the original320×320 guide. No per-limb deformation or relocation is performed. A one-game-pixel alpha envelope clips seven protruding blocks in frame3 and preserves three original missing guide blocks in frame5; coordinates are recorded in `registration.json`. Review the preserved boot regions as well as the new painting before approving; numerical pose checks alone do not certify the desired painted look.

The unchanged Godot `walk_guides.gd -- shrink` converts the4× painting row to1× by majority blocks and the approved model's palette. The supplied checker reports:

| Frame | Outline overlap | Left sole | Right sole | Head match |
| --- | --- | --- | --- | --- |
|1|90%|74, guide74|71, guide71|100%|
|3|88%|72, guide72|74, guide74|100%|
|5|91%|71, guide71|74, guide74|100%|
|7|90%|74, guide74|72, guide72|100%|

All final alpha edges are binary; every opaque colour belongs to the approved model. The alpha silhouettes stay within one game pixel of their respective guides in both directions. The supplied checker needs an eight-frame/two-row sheet, so the isolated QA sheet in `/tmp` uses **unpainted upstream guides** at2,4,6,8 only to exercise the API; `guide-check.json` reports the four painted keys explicitly. That temporary sheet is not delivered or loaded by the game. `KEYS PASS` is not a claim that a full painted walk is complete.

## Source and audit files

- `guide-01-4x.png`, `guide-03-4x.png`, `guide-05-4x.png`, `guide-07-4x.png`: exact320×320 crops of the upstream painted guide.
- `limb-key-01-4x.png`, `limb-key-03-4x.png`, `limb-key-05-4x.png`, `limb-key-07-4x.png`: exact320×320 colour-key crops, anatomical left warm, right cool. Reference only.
- `normal-guide-01-4x.png`, `normal-guide-03-4x.png`, `normal-guide-05-4x.png`, `normal-guide-07-4x.png`: unchanged upstream normal-guide crops for the later normal-painting step; not newly painted maps.
- `approved-model-4x.png`: approved80×80 model enlarged4×, identity reference.
- `first-painted-style-8x.png`: protected first still enlarged8×, style-only reference for the initial discarded attempt.
- `upstream-PROMPT.md`, `frames.json`: unchanged upstream instructions and coordinates.
- `frame-01-prompt.txt`, `frame-03-prompt.txt`, `frame-05-prompt.txt`, `frame-07-prompt.txt`: prepared initial prompts; only frame1 initial prompt was executed.
- `frame-01-locked-prompt.txt`, `frame-03-locked-prompt.txt`, `frame-05-locked-prompt.txt`, `frame-07-locked-prompt.txt`: pose-lock revision; executed for selected frame1v2 and rejected frame3v1. The other two were prepared but superseded before execution.
- `frame-03-canvas-prompt.txt`, `frame-05-canvas-prompt.txt`, `frame-07-canvas-prompt.txt`: selected prompts with explicit screen-left/right sole rows, each containing the unchanged upstream common instructions and its own frame's paragraph.
- `frame-01-source-v1.png`, `frame-01-source-v2.png`, `frame-03-source-v1.png`, `frame-03-source-v2.png`, `frame-05-source-v1.png`, `frame-07-source-v1.png`: built-in generated sources. Selected:1v2,3v2,5v1,7v1. Early attempts are retained to document pose drift.
- `frame-01-registered-edit-4x.png`, `frame-03-registered-edit-4x.png`, `frame-05-registered-edit-4x.png`, `frame-07-registered-edit-4x.png`: registered independent edits before the guide-preservation masks, not the final keys.
- `register_keys.py`: binary-alpha cleanup, whole-figure registration, explicit preservation masks and one-pixel guide envelope. It does not invent poses, generate interposed frames or draw replacement body details.
- `check_keys.gd`: review driver for unchanged upstream checker in an isolated temporary Godot project, containing copied Rig/RigPose/walk_guides.gd and model/part resources. Repo path is its user argument.
- `guide-check.json`: actual checker output for the four keys and exact QA scope; Godot4.7.2.
- `export_previews.py`, `validate_keys.py`: mechanical review layouts and palette/alpha/guide-envelope/protected-reference checks.
- `registration.json`, `validation.json`: fixed source selection, bounds, mask regions, checksums and recorded Step A approval status.
- `.gdignore`: all source/review material excluded from Godot imports.

## Original approval gate and completed follow-up

The original Step A delivery stopped here for Julian's review; Julian has now approved these four keys. The following describes that original gate: Do not wire these four keys as a completed walk or substitute them for runtime sheets. After the keys are approved, paint2,4,6,8 as independent edits from their own guides, make the normal paintings over their corresponding guides, assemble the requested2560×320 painting rows and640×160 runtime sheets, and run the full supplied check. Existing model/parts, protected stills/portrait, scripts, scenes and studio files are unchanged. The original Step A changes were confined to this production folder. The completed delivery also adds the runtime sheets and ticks only job 15-W outside assets/.
