# Room-event art — job14b

Painted for the raised room camera and shared sewer palette, with Julian's2026-10-31 approval for three small pearly-blue accent colours: RGB(125,151,159),(178,201,210),(209,224,235). These accents are confined to frost and the watcher's two eye pixels. This is a local event-art palette exception, not a change to the rooms or other characters.

| File | Frame size | Layout | Facing / surface |
| --- | --- | --- | --- |
| `watcher.png` |80×80| One row,1 frame | South; feet-root(40,72),58px tall |
| `watcher_n.png` |80×80| One row,1 matching normal frame | OpenGL green-up |
| `star_frost.png` |32×32| One row,6 frames;192×32 total | Patches lying on the floor |
| `star_frost_n.png` |32×32| Same6 frames, exact alpha | Low-relief crystal facets |

The watcher is a complete static whole figure: too thin, long hanging arms, narrow separate legs, planted feet and a featureless face with two pearl points. Its58px height is the explicit event brief's exception to Thomas's52px. Camera and stance were reviewed against the current south idle guide and approved Thomas. No skeleton parts or animation frames are delivered. Four quiet room-grey values form the body; the damp bottom row is darker. The game supplies fading.

Frost frames progress from83,147,204,215,339 to403 opaque pixels (8.11% through39.36% of each tile), with increasingly joined patches and open floor between them. Each patch has a completely transparent1px border in diffuse and normal, so it repeats through empty wrap boundaries with no chopped crystal. These are repeatable patches; their borders do not form a continuous crystal sheet. `production/previews/frost-repeat-4x.png` shows each repeated3×3 on the actual paving.

All runtime PNGs use binary alpha and material-coloured edges, without black outlines, smoothing, cast shadows or baked directional light. Connected clusters replace dither/noise. Frost uses the approved pearl accents; the body uses room colours. Both normal maps have exact diffuse alpha and normalized positive-z vectors. House style rules1–9 were checked through palette/format tests and native room/cast review; rule10's whole-figure workflow is respected, with no cutting involved.

## Claude handoff

`RoomEventFx` currently draws primitive stand-ins and does not load these textures. Replace the watcher shapes with `watcher.png`, drawn with top-left(-40,-72) relative to the existing foot-position anchor. Keep the event timing/fade; use the painting's RGB with opacity rather than multiply it by the old stand-in's grey tint. Use the matching normal map through the existing lighting support.

For frost, each frame region is(i*32,0,32,32), i0–5, ordered by density. Spread/melt patches over floor positions using the existing effect timing and room clipping. The old2px fleck positions are much denser than32px patches; replacing every old fleck with a full tile would stack the art excessively. Check patch spacing, density progression and glints in-game. The game can animate opacity/placement; the six painted frames are density variants.

Current previews are mechanical composites with unchanged room pixels, including a42%-opacity watcher example and a fade using the current0.35s in/0.9s hold/0.25s out timing. They do not test actual game lights, visibility distance, normals under those lights or code activation. No scripts/scenes/studio files changed. Sources, full built-in image-tool prompts, export coordinates, colour approval and validation are in `production/`.
