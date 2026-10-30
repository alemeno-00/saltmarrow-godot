# Thomas Wren — first production tranche

Environment coordination addendum: `SEWER_DIRECTION_HANDOFF.md` and `directional-manifest-proposal.json` preserve the compatibility contract and propose eight separately authored directions. Scale remains pending comparison in the actual sewer environment; no new directional art is delivered by that addendum.

Art-only review package, built from main f5926ca. No Godot code or runtime integration. No ART_JOBS completion claimed.

## Delivered

- `concepts/canonical-reference-v1.png`: portrait and front/three-quarter/back costume reference proposal.
- `concepts/five-variant-silhouettes-v2.png`: distinct Fury, Shadow, Elementalist, Censor and Talent full-body costume proposals, left to right.
- `sprites/steady-portrait-candidate.png`: native 128×128 transparent right-facing portrait, one frame.
- `sprites/standing-candidate.png`: native 64×64 transparent right-facing standing still, one frame, root (32,56).
- Unchanged generated masters, supplied concept board, exact prompts, art-export utility, validation results and nearest-neighbour previews.
- `PRODUCTION_PLAN.md` and `animation-manifest.json`: likeness rules, class distinctions, row/frame contracts, proposed timings, acceptance gates and ordered remaining checklist.

All files are under `assets/`. Every subfolder has its own README with layout, sizes and facing; the machine inventory records actual source dimensions/hashes. Built-in imagegen was used, followed by deterministic pixel export. The selected high-resolution concept images have opaque backgrounds and are not runtime assets.

## Readiness

The two native exports pass dimensions, transparency, palette and still-image alignment checks. They remain candidates: hair/scar/ear-notch and sprite cluster cleanup need art review. Animations, health states, five native backstory portraits and reconciled variant turnarounds remain unfinished. Full visual findings are in `qa/README.md` and `qa/CONCEPT_REVIEW.md`.

The supplied composite is accessible; original individual images from the earlier chat are not. Do not claim the composite's tiny rendered figures are sprite sheets.

The next production priority is canonical likeness approval, then the 37-frame weapon-free body sheet (job 1), 17 mace frames (job 2), mace ability rows (job 2b) and four health portraits (job 3). The master job list remains untouched until whole jobs pass. Final art approval and engine integration belong in review; no merge without user approval.
