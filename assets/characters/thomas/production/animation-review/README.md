# Job 1 animation study — rejected for runtime use

This is an unfinished imagegen study based on the approved standing-candidate.png. Do not wire these files into gameplay or rename the candidate to body.png. Approved source files are unchanged.

| File | Frame size | Rows / counts | Purpose |
| --- | --- | --- | --- |
| body-generated.png | No reliable cell grid; 1161×1355 source canvas | Intended 4, 6, 6, 3, 6, 6, 6 | Original transparent generated animation study |
| body-candidate.png | 64×64; 384×448 sheet | idle 4; walk 6; sneak 6; hurt 3; wounded walk 6; dying crawl 6; death 6 | Rejected export for inspection only |
| body-candidate-4x.png | 256×256 preview cells | Same seven rows and counts | Nearest-neighbour enlarged inspection sheet |
| validation.json | N/A | Per-cell bounds for 37 populated cells | Mechanical checks only; not animation approval |
| PROMPT.md | N/A | N/A | Generation prompt and export record |

All poses face right; the game mirrors them. Exported cells have a bottom-centre root at (32,56), with opaque bounds ending at y55. Bounding-box placement does not prove anatomical foot registration. Empty trailing cells are transparent. Candidate alpha is binary; pixels are sampled with nearest neighbour and reduced without dithering. Mechanical format checks pass, artistic acceptance does not.

## Why job 1 remains unchecked

- Walk does not alternate contact and passing poses clearly enough to be a convincing loop.
- Idle has too much pose and proportion drift from the approved still.
- Dying crawl becomes a collapse rather than a repeating dragging motion.
- The generated source did not honour a uniform grid. Automatic slicing catches fragments from adjacent rows, visible around wounded walk / crawl. It needs individually isolated frames and registered anatomy before delivery.
- Per-frame bounding-box scaling makes apparent body size vary. Production requires a fixed scale, stable pelvis/root and deliberate foot placement.
- Death needs a verified transition and held final pose in playback.

This is too large to honestly certify from a single generated sheet. Split the refinement into registered idle/walk, sneak/hurt/wounded walk, and crawl/death passes, then assemble the exact seven-row body.png only after playback review. Job 7c remains a later eighth row as requested. Jobs 2–8 have not been attempted: order is preserved while job 1 is unresolved. No boxes in ART_JOBS.md are ticked because no requested job is complete.

Claude handoff: no code change is needed or requested for this review study. When the final body.png passes review, Claude can wire its seven row counts from ART_JOBS.md. Do not load these study images.
