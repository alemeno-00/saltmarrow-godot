# Source and export record

Generated with the built-in image-generation tool, using the approved v1_0 terrain and sprite atlases as style references. Prompt specifications: transparent isolated pixel-art components, wet slate/charcoal/brown masonry with moss, fixed upper-left illumination, hard edges, no text or background. These initial studies predate reading the new Outflow neutral-light/top-only-wall brief.

- Walls: twelve components in three rows of four; boundary N/E/S/W, outer NE/SE/SW/NW, inner NE/SE/SW/NW.
- Junctions: four end caps N/E/S/W, four T junctions missing N/E/S/W, cross and pillar. Flat junctions were kept separate from upright walls.
- Doors: two rows of four directions, closed then open; retain masonry piers and registration across states.
- Stairs: four descending stairwells N/E/S/W, two by two.

`export.py` extracts alpha-connected silhouettes, thresholds alpha at 128, registers pairs, samples nearest to the delivery grid, quantizes a shared 63-colour palette and clears hidden RGB. It does not paint pixels. `preview.py` assembles existing exports for review. Both require Python and Pillow; run from any directory.

Each image below is one static reference image, one row and one frame. Source grids are conceptual components, not runtime animation strips.

| File | Canvas | Role |
| --- | --- | --- |
| caps-3x.png | 480×96 | nearest 3× atlas preview |
| doors-3x.png | 768×480 | nearest 3× atlas preview |
| doors-master.png | 1774×887 | generated master |
| junctions-master.png | 1024×1536 | generated master |
| stairs-3x.png | 384×96 | nearest 3× atlas preview |
| stairs-master.png | 1536×1024 | generated master |
| walls-3x.png | 768×576 | nearest 3× atlas preview |
| walls-master.png | 1024×1536 | generated master |

- `export.py`: reproducible export and validation.
- `preview.py`: review assembly only.
- `.gdignore`: exclude production references from import.
