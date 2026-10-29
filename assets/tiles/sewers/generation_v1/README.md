# Sewers generation kit — draft job 9 study

This is an **unfinished companion** to approved `../v1_0/`, not a replacement. Job 9 remains unchecked. Do not wire this study into the published game yet.

34 new static sprites cover directional wall studies, convex/recessed corners, end caps, a pillar, optional junction caps, paired door states and stairs. `manifest.json` lists every PNG, size, origin, region, source crop and checksum. It also references all 68 existing approved assets without copying or modifying them: floors, all 47 normalized bank masks, water variants, bridges and props.

## Acceptance gaps

- Side walls repeat visible cap edges; wall corners and straight sections do not yet form seamless generated boundaries. Direction names describe intended placement, not a verified terrain solver.
- North and south wall studies both show faces. The newly merged Outflow brief explicitly calls for north faces and top-only other walls; apply that camera convention in the next revision where appropriate.
- North open door aperture is 17px minimum across y55–69, versus an 18px approved Thomas silhouette. South is 21px. Enlarge the north opening before acceptance; do not solve this with character scaling.
- T/cross pieces are optional flat plan caps, not finished upright junctions. Collision, sorting, door traversal and import in Godot have not been tested.

This full generated-wall set needs another focused art pass. The assembly exposes the faults; it is not evidence of acceptance. Complete this pass before moving to job 10. Job 12 now points at `design/art-briefs/outflow/BRIEF.md`, merged via #19; that room painting is a separate deliverable and is not attempted here.

## Files and layout

| File/folder | Frame size | Storage rows and occupied counts |
| --- | --- | --- |
| `walls/` | 32×64 | 17 separate PNGs, 1 row/1 frame each |
| `walls_atlas.png` | 32×64 | 8, 8, 1; seven trailing empty cells; 256×192 canvas |
| `caps/` | 32×32 | 5 separate PNGs, 1 row/1 frame each |
| `caps_atlas.png` | 32×32 | 5; 160×32 canvas |
| `doors/` | 64×80 | 8 separate PNGs, 1 row/1 frame each |
| `doors_atlas.png` | 64×80 | closed N/E/S/W, then open N/E/S/W; 256×160 canvas |
| `stairs/` | 32×32 | 4 separate PNGs, 1 row/1 frame each |
| `stairs_atlas.png` | 32×32 | down N/E/S/W; 128×32 canvas |
| `manifest.json` | — | Exact individual files, dimensions, origins and atlas regions |
| `validation.json` | — | Export checks and measured apertures; not gameplay QA |
| `previews/` | — | Native and nearest 2× assembly, placement data, README |
| `production/` | — | Generated masters, exporter, preview assembler, enlarged atlases, README |

Atlas rows are storage, never animation. No gaps between atlas cells. Empty cells are fully transparent. Exported sprites have binary alpha and one shared palette of at most 63 RGB colours. Source masters are retained as production references and are not runtime pixel assets.

Walls use bottom-centre origin (16,64). Doors use (32,72), a one-cell logical footprint and visual overhang into neighbouring walls. They need ground/foreground sorting and collision supplied by Claude after the art is accepted; never infer collision from visible alpha. Stairs use centre (16,16). Directions and corner semantics are in the manifest. Door open/closed pairs use shared masonry-pier registration rather than independent bounding-box centring.

Godot 4.7: nearest sampling, no smoothing. Approved v1_0 stays byte-for-byte unchanged. No code changes are included.
