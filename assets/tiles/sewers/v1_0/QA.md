# Export validation — 28 October 2026

Result: export checks passed. Godot import and gameplay validation **not run**; no Godot executable was available. `validation.json` distinguishes the skipped engine check from passing export checks.

## Tests performed

1. Open every one of the 68 manifest exports as RGBA; compare actual dimensions with the manifest. All 55 terrain tiles are exactly 32 × 32. Check that alpha contains only 0 or 255 and transparent pixels have RGB (0,0,0). Every isolated sprite contains transparency, including the arch aperture at (32,60).
2. For every asset, crop its declared region out of its declared atlas and compare all RGBA bytes against the individual export. Check the file's SHA-256 against the manifest. All match. Terrain sheet is 256 × 224, with eight 32px columns. Sprite sheet is 256 × 384, with four 64 × 96 storage columns. The unused cells remain transparent.
3. Compare right/left and bottom/top border pixels for every ordered pair within each four-tile floor/water family: 64 comparisons, including self-repeat. All match exactly. Different materials share a boundary within their family; this does not mean floor and open water are interchangeable.
4. Enumerate each horizontal and vertical adjacent pair of water cells. Their surrounding neighbourhood has ten independently dry/wet cells. Enumerate all 1024 surroundings for each orientation, normalize the two masks and compare the touching RGBA edges. **2048 compatible bank-edge comparisons pass exactly.** This checks every physically compatible pair, rather than demanding that arbitrary incompatible shoreline tiles match.
5. For every bank with a cardinal dry bit, compare that entire edge to the opposite edge of the canonical floor. All match. Boundary equality is a strict pixel test, not proof of artistic quality or lack of visible repetition in a large room.
6. Flood-fill the preview plans with cardinal neighbours, treating floor cells and explicitly declared bridge cells as walkable. Corridor: 122 cells in one component; junction: 97 in one component; cistern: 120 in one component. Decorative sprites, proposed collision, outside entry modules and future water-level states are excluded. This is a raster assembly check, not a navmesh test.
7. Visually inspect the generated source, exported terrain/sprite atlases, native arch, and nearest-neighbour 2× corridor, junction and cistern previews. The small props have hard silhouettes. The repeated floor pattern and stepped cistern silhouette are visible limitations, recorded for review. Source art is clearly separated from the exports.

## Processing recipe

The built-in generator returned a 1254 × 1254 source laid out in four equal columns and rows. Round fractional cell boundaries, inset 3px, sample with nearest-neighbour (32px for terrain, 64px intermediate for isolated objects). Quantize RGB channels downward to multiples of eight. Alpha below 160 becomes transparent black; all other alpha becomes 255. Terrain holes are backed with opaque dark stone. Shared opposite-border profiles are taken from the canonical dry floor or first water tile, including common corner pixels. Sprite silhouettes are fitted to the sizes listed in the manifest, with an explicitly cleared open arch aperture. No smoothing is used.

The shore set is generated from all normalized eight-neighbour masks. For each water pixel, take its minimum distance to any flagged cardinal edge or isolated flagged diagonal corner. Distances below 6 use the canonical floor pixel, [6,7) use dark edging, [7,8) use a restrained waterline, and the remainder use canonical water. Border coordinates are 0 and 31, preserving identical profiles across compatible neighbours. This produces 47 distinct masks.

Temporary build and verification helpers were used outside the repository; no executable code is delivered in this art-only PR. The manifest, source image, exact generation prompt, processing recipe, preview plans and validation results are the handoff evidence.

## Required engine review

Import the actual atlases at native size. Inspect nearest filtering, alpha edges over light and dark backgrounds, padding, integer scaling, wall layering, collision at the feet, arch clearance, and transitions between water/land. Walk the three plans with the actual player and proposed prop collision. Review repetitive surfaces and corner joins before accepting the visual quality. Do not mark this pack engine-verified based on the image checks.
