# Verification

`export-and-validate.cjs` is an art-export utility, not Godot/game code. Requires Node.js and the `sharp` package. Run from any directory with `node path/to/export-and-validate.cjs` (make sharp available through NODE_PATH if not installed locally). It derives the two candidates from unchanged masters, checks exact canvas dimensions, binary alpha, ≤32 opaque colours, nonempty content, margins, sprite ground-square bounds and sole baseline, then produces `validation.json` and PNG review previews.

`standing-4x.png` and `portrait-4x.png` are nearest-neighbour enlarged previews of one still each. `standing-grid-4x.png` places the sprite on a 32 px grid before 4× enlargement. These opaque/background review previews are not deliverable sprite sheets. No animation rows or frame counts apply.

`inventory.json` records file sizes, dimensions, alpha ranges and hashes for all PNGs except the generated QA previews. Reference/concept/master files are not required to satisfy the runtime pixel contract.

## First-tranche result

- PASS: 64×64 standing and 128×128 portrait; binary alpha; 31 opaque colours; fully contained silhouettes; right-facing visual inspection. Sprite sole baseline y55, root (32,56), bbox x23–40/y10–55, within the 32 px ground footprint.
- PASS: portrait's scarf and near-side left cheek scar remain visible; no ornate armour, weapon or magic. Generated source hair remains longer/more tousled than the written army-short baseline: refine before likeness approval.
- REVIEW: portrait's ear notch is not reliably resolved. The scar is stronger than a faded healed scar; reduce its contrast in a subsequent art pass. Face remains sterner/more heroic than the requested ordinary weariness. All are candidates, not a final canonical lock.
- REVIEW: standing sprite has visible crown/shoulder planes but needs comparison with final dungeon camera pitch. Downsampling leaves noisy coat clusters; a pixel cleanup pass should simplify them. Facial identity/ear scar cannot be certified at 64 px from this still.
- NOT DELIVERED: animation frames/sheets. Motion, loop seams, gait, grip continuity and engine clipping have not been validated; dimension checks cannot stand in for those tests. The animation plan is complete enough to commission the next tranche.
- NOT DELIVERED: full health portrait set or five native backstory portraits. High-resolution class references are a separate concept deliverable.

See `CONCEPT_REVIEW.md` for per-sheet deviations; never use a prompt as evidence that a visual requirement was achieved.
