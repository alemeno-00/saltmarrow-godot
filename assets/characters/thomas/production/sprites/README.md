# Pixel export candidates — review required

| File | Canvas / frame | Rows and populated counts | Facing | Status |
| --- | --- | --- | --- | --- |
| `standing-candidate.png` | 64×64 | 1 row, 1 still | Three-quarter right, slightly elevated | Scale/alignment proof, not an idle animation or completed body sheet |
| `steady-portrait-candidate.png` | 128×128 | 1 row, 1 portrait | Chest up, three-quarter right | Canonical steady portrait candidate, health-state set incomplete |

Both are genuine transparent PNGs, binary alpha (0/255), 31 opaque colours, hard pixel edges, no text. Generated masters were mechanically exported using nearest-neighbour sampling, binary-alpha normalization and deterministic palette reduction. They are not claimed to be hand-pixelled or approved for the game.

The standing silhouette is x23–40, y10–55 inclusive, root (32,56); the bottom sole includes x32 on y55. Empty hands. Ground footprint fits the 32×32 bottom-centre square. Full soles, scarf and coat need art review at 1× before animation; the scar/ear notch is too small to certify from this still. Native silhouette reads lean; simplify noisy coat pixels and compare camera pitch with the eventual dungeon before approval.

Do not rename the still to `body.png`: job 1 requires 37 frames over seven rows. Do not copy it four times and call that breathing. No runtime code imports these candidates in this PR. See the production plan for animation layout, proposed timings and the exact remaining checklist.
