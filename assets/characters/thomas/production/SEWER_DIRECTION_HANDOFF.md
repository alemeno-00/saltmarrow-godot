# Thomas / sewer camera, scale and direction handoff

2026-10-29. Proposal only; no new sprites, animation completion or game-code changes.

## Environment evidence

Reviewed the actual Godot screenshots at sewer branch `art/sewer-playable-fight`, commit `678c6a5`: `assets/tiles/sewers/sections-v1/previews/cistern-detail.png`, `arrangement-a.png`, `arrangement-b.png`, plus the original `assets/tiles/sewers/v1_0/source/approved-concept-v0_2.png` and sections README/manifest. These files live in the sewer workstream; do not copy over or edit them from character production. The screenshots establish the current environment, not final Thomas proportions.

Camera contract: orthogonal 32×32 ground grid with slightly elevated top-down artwork. Never rotate the ground grid into isometric diamonds. Draw visible crowns and shoulder tops, consistent with paving, bridge decks and wall caps. North is screen up, east screen right. Water/foreground occlusion must not make boots appear to stand on blocked masonry or water.

## Scale and registration

Keep native frames 64×64 and root (32,56). The current standing candidate's visible silhouette is 46 px tall (y10–55); it is not a 64 px tall person. The original concept's approximately 48 px character cue is consistent as a starting point, not proof of final scale.

The sewer coordinator reports an older temporary review figure displayed at 1.25×, with an approximately 60-world-pixel body. This is provisional renderer scaling, not an instruction to enlarge Thomas's source or change the anchor. The sections scene and production Thomas are separate versions; do not infer one renderer's scale from another branch.

Pending coordinator comparison: put the same Thomas still in the actual environment at native 1× (46 px visible) and review 1.25× (57.5 px nominal visible), at identical ground anchors and camera zoom. Compare bridge clearance, two-cell dry walks, barrels/doors, foreground occlusion and face/scarf readability. Keep pixel filtering nearest; fractional display scale can produce uneven pixel sizes and needs review. Do not lock final proportions or animate the full set until this comparison is reviewed.

The reported sewer foot anchor is cell centre + (0,12). With frame root r=(32,56), draw top-left = foot_anchor − r at 1×; if scaled about the root, top-left = foot_anchor − scale*r. Do not apply scale only to the texture while leaving its root offset unscaled. Frame registration stays fixed across directions and poses. Crouch, crawl and death naturally lower the silhouette; do not stretch each pose back to standing height. Root is a ground registration point, not a requirement that both soles occupy it during every stride.

## Separate eight-direction proposal

Keep `animation-manifest.json` and the existing right-only/mirrored compatibility contract unchanged. A single right-facing still or walk does not provide eight-direction movement. Read-only inspection of `ActorView` confirms horizontal +/-1 facing updates; north/south facing selection needs a later code-owner change.

`directional-manifest-proposal.json` defines a separate future output: one body sheet per direction, seven animation rows each, 64×64 cells and the existing counts. Author all eight directions independently: N, NE, E, SE, S, SW, W, NW; no automatic mirrors. N must show true away-facing back/coat/satchel construction, S true toward-facing front/scarf, diagonals distinct oblique silhouettes. E/W must turn into their travel direction. The current slightly elevated right-facing candidate is only a compatibility reference; it is not automatically approved as E or SE.

All eight are required before claiming full coverage: 8×37 = 296 populated body cells, 384×448 per direction. Suggested staging after scale approval: eight one-frame pose proofs (8 cells); eight four-frame idle rows (32 cells); eight six-frame walks (48 cells); remaining five body animations (216 cells). Pose proofs are separate references, not extra animation frames. Total full body set remains 296, including idle and walk.

Preserve anatomical LEFT cheek scar/ear notch and the approved satchel/lantern/scarf attachments when turning. A scar hidden on a far cheek is correctly occluded, not moved to the near cheek. Back views must not invent a face. Decide exact satchel side/strap path and weapon-hand assignment in reconciled turnarounds before production; no side is silently inferred from inconsistent concepts.

Weapons remain separate registered layers, with the same canvas/root, direction/row/frame correspondence, and explicit per-frame hand/socket coordinates once poses exist. Socket entries are currently unmeasured; never invent working coordinates or mirror asymmetric grips. Foreground hand/weapon depth may differ by direction and needs code-owner integration after art proof review.

## Readiness and owner handoff

Ready: technical still exports and written contracts only. Pending: actual-environment scale comparison, approved turnarounds/asymmetry, eight directional pose proofs, every animation frame and socket registration. No directional sheets or socket measurements exist yet. No full set is labelled game-ready.

Character work stays under `assets/characters/thomas/`; sewer work stays under `assets/tiles/sewers/`. The sewer coordinator owns the environment scale comparison and its `SPRITE_INTEGRATION.md`; these character notes do not replace it. Claude owns later direction selection, keeping idle facing after movement, registration and layer selection. No code edits are made here.
