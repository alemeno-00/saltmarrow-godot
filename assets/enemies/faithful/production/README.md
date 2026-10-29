# Production sources

All masters are variable-gutter reference canvases, not runtime grids. Right facing throughout.

| File | Layout |
| --- | --- |
| standing-master.png | Generated source animation poses; see final row table in ../README.md |
| reactions-master.png | Generated source animation poses; see final row table in ../README.md |
| body-2x.png | 128×128 preview cells, same populated counts as final body.png |
| validation.json | Canvas, 64×64 frame, root, row counts and binary alpha report |

Built-in imagegen prompts: cold wet gothic fantasy, complete separated right-facing sprites, fixed anatomy scale, no guns/text/grid/smoothing, transparent backgrounds. Miner: wet slate workcoat, brown apron, helmet amber lamp, two-handed iron pick, pearly eyes, throat light, salt crust; animations requested in three passes (standing reactions; tell/attack/prone/get-up; limp/flee/death variants). Faithful: thin smiling barefoot adult, dirty off-white chapel smock, dark star-metal pin, pearly eyes, throat light and salt hem; four standing action rows followed by four reaction/death rows. Every row name/count is recorded in ../README.md.

Export uses alpha threshold128, nearest-neighbour sampling, fixed source scale per pass, shared47-colour palette and clears hidden transparent RGB. Final size/counts/alpha checked and enlarged sheets visually inspected. Engine timing remains for Claude.

Acceptance review: the Faithful brief specifies a star-metal pin without a required shape. The falling-star shape belongs to Ellen's description; it is not an additional Faithful requirement. The small dark pin in this sheet meets the Faithful brief. Earlier pin-only variants were discarded because they changed some poses without improving the runtime read. Job5 is delivered with the existing animation sheet unchanged.
