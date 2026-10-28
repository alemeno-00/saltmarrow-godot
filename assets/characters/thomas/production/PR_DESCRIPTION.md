# Thomas Wren: art production plan, class concepts and verified pixel candidates

Ready-to-use draft PR description. Branch: `art/thomas-wren-production`; target: `main`.

Thomas has no production character art on the source main branch. This first tranche creates a dedicated workstream under `assets/characters/thomas/production/`: canonical portrait/turnaround proposal, five distinct costume silhouettes, transparent native pixel candidates and a precise remaining checklist.

Delivered: canonical front/right-three-quarter/back reference proposal; Fury/Shadow/Elementalist/Censor/Talent costume lineup; one 128×128 right-facing steady portrait candidate; one 64×64 right-facing standing still rooted at (32,56); unchanged supplied concept board and generated masters; exact imagegen prompts, export utility, inventory/hashes and review previews. The animation manifest plans 37 body frames (4/6/6/3/6/6/6) and 17 mace frames (3/3/3/8), with proposed timings and review gates.

Validation passed: exact native image sizes, alpha 0/255, 31 opaque colours, nonempty contained silhouettes, sole y55/root (32,56), 32 px footprint bounds, original reference preserved byte-for-byte, manifest totals and assets-only change boundary. Visual previews were inspected. No Godot tests apply because there are no game-code changes.

This is not a finished animation set. No animation frames/sheets are delivered, so motion, loops, grip continuity and engine clipping remain unvalidated. ART_JOBS jobs 1–3 stay unchecked, and incomplete art does not occupy final runtime filenames. Hair length, scar contrast, ear notch and sprite pixel cleanup need review; Fury needs a fuller short beard and Talent needs a restrained uncanny close-up. Five native class portraits, complete health states and reconciled variant turnarounds remain pending.

All painted references are explicitly concept only. The canonical sheet's large portrait faces left and has unresolved anatomical asymmetry; use the right-facing native portrait candidate for portrait-layout review. Original individual class images from the referenced chat were inaccessible; the newly supplied composite is available and preserved unchanged.

Claude handoff: engine integration remains separate. Decide scar/satchel treatment when mirroring and the careful-step maul versus weapon-free base-body contract. Talent's Star-like signs are optional art proposals; Mind remains safe under existing story rules. No scripts/scenes/tests/workflows or master job-list changes.

Start with `README.md`, `PRODUCTION_PLAN.md` and `qa/CONCEPT_REVIEW.md`. Keep as draft; no merge without user approval.
