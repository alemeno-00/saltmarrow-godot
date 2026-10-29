# Sewer map sections — first assembly test

Three newly generated room paintings based on the approved **Sewer Tileset v0.2**, registered into usable large Godot sections. This tests art-directed room assembly in place of independently random tiles. These are **new generated assets**, not cutouts or conversions of the original concept, and are pending visual approval.

Open `review-sewer-sections.command` at the repository root. **1 / 2** select the two arrangements; **Tab** switches between overview and following the player; **M** shows the collision grid. Existing arrows/WASD and click-to-walk controls apply. There are no enemies in this art/navigation study. The figure is the earlier temporary review sprite, unchanged; the other workflow owns the production character sheets.

| Section | PNG canvas | Ground grid | Purpose |
| --- | --- | --- | --- |
| Corridor | 1024×896 | 32×28 | Drainage spine, maintenance walks and supported crossing |
| Junction | 768×896 | 24×28 | Main channel with a curved, gated north service recess |
| Cistern | 1024×896 | 32×28 | Round basin, maintenance ring and two throat bridges |

The canvases include transparent space above/below some silhouettes. Their dimensions describe storage, not the wall's ground collision footprint. Different section widths are intentional. One PNG per layer, one static frame, no animation rows or facing variants.

## Assembly contract

Both layouts contain all three sections: **A: corridor → junction → cistern**, **B: cistern → corridor → junction**. Origins are top-left, snapped to 32px. No rotation or mirroring: wall perspective, wear and baked lighting are directional. The two layouts are examples of reordering a three-piece library, not a complete procedural dungeon system or 30 room archetypes.

Every west/east port uses the same ground rows: dry walks at rows 10–11 and 16–17, deep channel at rows 12–15. Registered 64px throat strips keep the exported edge pixels identical. A module starts where the previous module's canvas ends, with no overlap. The north branch in the junction is a **closed gated recess**, not a third interchangeable socket yet. Layout ends are open continuation boundaries; finished levels still need entrance/exit caps.

`manifest.json` contains each exact row of the authored navigation mask, dimensions, origins, ports, layer filenames, fixed bridge columns, registration landmarks and export hashes. `.` is safe dry floor, `~` blocked deep water, `#` blocked masonry/void/prop footprint. Ground collision comes from this mask, never PNG alpha. Curved boundaries use a conservative grid approximation that remains visible with M; visual collision/feet alignment still needs human walk-through review.

## Layers and import

Each section has `ground.png` and `foreground.png`, both its full canvas size. Ground includes fixed rear walls, floor, water and fixed dressing. Foreground is the separately extracted front wall, drawn above actors. `assembled.png` is their exact recomposition for inspection, not the texture drawn over the character. This is not a completely separated prop/lighting set: rear arches and fixed props are still baked into the ground painting.

RGBA PNG, binary alpha, zero RGB under transparent pixels. Import losslessly, disable mipmaps and repeat, and use nearest filtering. Runtime sections draw at native resolution; the camera controls magnification. No new TileSet resource is needed for this large-image prototype. The draw order is ground → existing actors/effects → section foreground. No main-scene or core-combat code was replaced.

The room paintings contain **static water and baked torch illumination**. Animated water, movable gates, relighting and independent prop replacement require further layer extraction or authored variants. This restriction trades some variation for a more controlled composition.

## Sources and reproducibility

`source/` preserves all three original built-in image-generator outputs and exact prompts. References were `../v1_0/source/approved-concept-v0_2.png` and the supporting `../benchmarks/corridor-v2.png`. The generator did not deliver the requested dimensions and exact socket positions. `tooling/build.py` therefore performs explicit nearest-neighbour registration between reviewed y landmarks, hard-alpha cleanup, native shared throat registration and foreground extraction. The manifest records those transformations; the source paintings remain untouched.

The cistern's two transparent bridges reuse the earlier generated `../fidelity-v2/props/bridge.png`, mechanically registered to 64×224. Those bridges connect the dry ring without allowing the actor through water or onto the central drain. Barrel and large fixture footprints are blocked where they overlap the walks.

Rebuild with `python3 tooling/build.py`, then run `python3 tooling/verify.py` (Pillow required). Import through Godot before running the scene. `tests/test_sewer_sections.gd` runs both actual arrangements, checks all dry cells, blocked water, matching ports and existing exploration movement through both joins and back on the lower walk. Append `-- --capture` using a graphical renderer to save genuine engine screenshots in `previews/`. Those PNGs are engine evidence, not generated scene mockups.

## Validation and remaining work

Asset checks pass: native dimensions; binary alpha/transparent RGB; ground and foreground do not overlap and exactly reconstruct assembled art; all nine ordered boundary pairs match. All six unrotated section orders have connected dry masks, while the game exposes two selected orders. Both engine arrangements pass navigation/movement checks in Godot 4.7.2 Compatibility. The original 43 gameplay tests also pass. Version 4.6 has not been tested.

These technical passes do not establish concept fidelity. Shared edge pixels do not guarantee continuous internal stone courses; join transitions, baked lighting differences, curved collision margins, fixed prop positions and character proportions remain visual review items. The test supports deciding whether this larger-section approach is preferable before making more rooms. Further production work includes branch connectors, entrance/exit caps, junction/cistern variants, animated water, separated interactive props and integration with the production character workflow.

## Character workflow coordination

See `SPRITE_INTEGRATION.md` for the shared frame/root, scale proof, eight-direction proposal, separate weapon registration and integration acceptance checklist. `previews/sprite-scale-comparison.png` compares the character workflow's current unapproved still at native and provisional review scale using real Godot captures. It is a comparison, not delivery of a new character or directional animation set. The inspected source hash and camera are recorded beside it.
