# Sewers room kit — job 13 first batch

**22 runtime PNGs:** one painting for each of 12 rooms and 6 tunnels, plus 4 plain doorway seals. These follow the supplied blockouts and the approved Outflow method. More room variants follow after Julian approves this batch. This delivers job 13; it does not deliver flood variants (12b), Garrick (11), or Thomas prone/getting-up (7d).

## Runtime files

Each painting is one static frame on one row, with no margins or frame gaps. Origins are (0,0); map grid 32px. No runtime text, characters, blood, dropped items or moving gates.

| File | Frame / canvas size | Mirror left to right |
| --- | --- | --- |
| `entry/1.png` | 256×256 | no |
| `stairs/1.png` | 256×256 | no |
| `lore_a/1.png` | 256×256 | no |
| `lore_b/1.png` | 256×256 | no |
| `junction_a/1.png` | 384×384 | yes |
| `junction_b/1.png` | 384×384 | yes |
| `junction_c/1.png` | 384×384 | yes |
| `chamber_a/1.png` | 384×256 | yes |
| `chamber_b/1.png` | 384×256 | yes |
| `chamber_c/1.png` | 256×384 | no |
| `flooded_a/1.png` | 384×384 | yes |
| `flooded_b/1.png` | 384×384 | yes |
| `connector_ew/1.png` | 128×128 | no |
| `connector_ns/1.png` | 128×128 | no |
| `connector_ne/1.png` | 128×128 | no |
| `connector_nw/1.png` | 128×128 | no |
| `connector_es/1.png` | 128×128 | no |
| `connector_sw/1.png` | 128×128 | no |
| `sealed/north.png` | 64×64 | use as authored |
| `sealed/south.png` | 64×32 | use as authored |
| `sealed/west.png` | 32×64 | use as authored |
| `sealed/east.png` | 32×64 | use as authored |

## Placement and lighting

- Draw each `1.png` exactly at its corresponding blockout’s top-left. The blockouts under `scripts/levels/sewers/layouts/` remain the source of collision and room contents. No code or blockout changes are included.
- The north faces in rooms occupy 64px, other walls show tops. Tunnels retain their one-row north-face exception. The passages keep the actual middle-block positions, including the offset doors in eight-square rooms.
- Every layout README lists its exact doorway rectangles and actual lantern/brazier glass centres. There are **31 fixtures**. `manifest.json` contains the same coordinates and mirror flags. Mirrorable paintings use x′ = width−1−x for light pixel positions; never mirror eight-square rooms or rotate a room vertically.
- Art uses even ambient material colours; the game supplies darkness, amber light and flicker. Reserve bright amber palette entries for the actual glass. Rust/brass and material crevices remain restrained. No game-lighting screenshot is claimed here.
- Runtime PNGs use binary alpha and one shared palette of at most 32 opaque colours. Use nearest texture sampling and no smoothing in Godot 4.7. Empty alpha RGB is zeroed.

## How pieces meet

The paintings were made with the built-in image generator and registered to their blockouts using recorded nearest-sampled source boundaries. Tall or displaced generated source details were fitted to their prescribed cells; source masters and registration knots are retained. No procedural substitute room textures were drawn.

Plain wall-top strips come from three crops of the generated pump-room masonry. Three distinct crops of the authored gallery floor supply dry doorway pads, removing residual green guide tint. The outer **4px** of each active port uses common floor/masonry edge strips, including a mirrored corner crop, so opposite edges match. Matching pixels certify those four pixels, not continuous brick courses throughout neighbouring paintings. The original room interiors remain separate authored paintings. Review assembled joins for material scale and wall-course continuity.

## Checks and review

`validation.json` records 22 correct PNG sizes, shared palette limits, binary alpha, opaque walkable squares, expected water cells, clear dry doorway cells, fixture coordinates and **450 opposite-port comparisons**. It checks 18 layouts against the supplied blockout sizes. It does not prove prop silhouettes or collision automatically; use the grid overlays for visual review.

`previews/` contains native-derived contact sheets, 2× paintings, grid/light overlays, a turning assembly and a sealed-room example. `production/` contains generated masters, prompt specifications, sampled layout metadata, palette/registration data and repeatable export/check scripts. Both reference folders have `.gdignore`.

Claude still needs to load the paintings and seals, use the documented glass positions, and inspect them with the real lighting and water effects. Julian approves the batch’s appearance. No test, scene, script, project or studio files are changed by this PR.

## Other files

- `manifest.json`: inventory, SHA256 checksums, blockout paths, origins, ports, light positions, mirrorability and registration.
- `validation.json`: export and pixel-profile checks, including explicit limits.
- `sealed/README.md`, `production/README.md`, `previews/README.md`: complete folder inventories.
