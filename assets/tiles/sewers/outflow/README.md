# The Outflow — painted room and moving pieces

Job 12, painted from `design/art-briefs/outflow/outflow-blockout.png` and its BRIEF.md. The room is one complete background, exactly 448×352 pixels (14×11 squares at 32px). North wall face, other wall tops; quiet irregular flagstone floor, neutral ambient colour, three small amber glass panes without light pools. Characters, blood, tag and moving gates are absent from the background. The game supplies lighting and all gameplay.

## Runtime files

| File | Frame size | Rows / frame counts | Canvas |
| --- | --- | --- | --- |
| `outflow_room.png` | 448×352 | 1 / 1 | 448×352 |
| `sluice_open.png` | 32×32 | 1 / 4, loop | 128×32 |
| `sluice_shut.png` | 32×32 | 1 / 1, hold | 32×32 |
| `sluice_shutting.png` | 32×32 | 1 / 4, play once | 128×32 |
| `floor_flooding.png` | 32×32 | 1 / 4, play once and hold last | 128×32 |
| `tally_tag_floor.png` | 32×32 | 1 / 1 | 32×32 |
| `tally_tag_icon.png` | 32×32 | 1 / 1 | 32×32 |

All PNGs are RGBA, hard pixels, binary alpha, at most 32 opaque RGB colours per complete PNG. Frames run left to right with no gaps. Gates face down the north wall toward the room; the tag is a non-directional prop. No text or numerals. Icon has a dark silhouette outline. `manifest.json` lists exact sizes, origins, registration and SHA256 checksums. `validation.json` records export checks.

## Placement for Claude

All coordinates below are room-local pixels from the upper-left, +x right and +y down. Draw the room unscaled at the blockout origin. Godot 4.7: nearest texture filter; no smoothing.

- Gate overlay canvas top-lefts: **(96,0)** and **(320,0)**. Each is exactly one wall square. The moving iron/water occupies a 20×22 region at local (6,10) inside its transparent 32×32 canvas, leaving the painted stone arch visible. Use the same position for every state. Last shutting frame equals the shut PNG exactly.
- Floor/water channel: **x32–415, y160–191**. No water is painted outside it. Flood animation is an opaque replacement for a floor square; use its final frame as the flooded resting tile, rather than stamping the whole strip. Water advances from the top of the tile. Its measured coverage is 0%, 34%, 60%, 97%. Rotation to follow a spreading front is an integration choice.
- West entrance: **x0–31, y64–127**, fully open and opaque floor. Room floor occupies x32–415, y32–319 except the channel. No painted floor obstacles.
- Tag: centre its 32×32 canvas on the dropped-item square. The small floor view and larger HUD icon depict the same worn brass plate and cord.
- Suggested art timing for review: open 180ms/frame loop; shutting and flooding 220ms/frame once. Claude may tune these to the combat sequence.

Lantern **glass centres** for real light placement:

| Lantern | Pixel centre | Blockout cell (zero-based) |
| --- | --- | --- |
| West | **(48,15)** | (1,0) |
| Middle | **(241,15)** | (7,0) |
| East | **(400,15)** | (12,0) |

Glass is only a small amber material accent; add the actual amber light, darkness and flicker in the game. No code changes are included. This delivery checks art/grid export; Claude's in-game lighting screenshot and Julian's appearance approval remain separate acceptance steps.

## Review and provenance

`previews/` contains native-derived enlargements, animation GIFs, grid review and gates placed over the room. These are review images, not game backgrounds. `production/` retains generated masters, exact prompts, sampled blockout data and repeatable export/validation. Both reference folders have `.gdignore`.

Built-in image generation painted the room and pieces. The exporter mechanically registers observed source boundaries to the supplied blockout, samples nearest, and quantizes palettes; it does not draw substitute room art. All existing approved assets and code are unchanged.
