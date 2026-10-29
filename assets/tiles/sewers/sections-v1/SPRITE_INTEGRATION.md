# Sewer / character coordination contract

The user approved the larger sewer-section look and asked the environment and sprite workflows to coordinate scale and directional movement. This is a shared integration proposal, not a declaration that character sheets are complete.

## Authoritative inputs

- Environment: `sections-v1` corridor, junction and cistern, actual Godot captures in `previews/`, original approved Sewer Tileset v0.2 for style/camera. Orthogonal 32px movement cells, slightly elevated top-down. No isometric rotation or perspective convergence.
- Character workflow: **Create Thomas Wren art workstream**, local worktree `work/thomas-wren-art`, production notes under `assets/characters/thomas/production/`. It owns likeness, costume, body/weapon sheets and animation. Do not edit or regenerate its character exports from the sewer branch.
- Source frames remain 64×64, feet/root (32,56), transparent hard-edged pixels. Existing right-facing compatibility sheets retain their documented layout. Review weapons remain separate from the canonical base body.

## Scale and anchor

One movement cell is 32 world pixels. Camera zoom applies to the entire world; do not judge scale from a screenshot's displayed size. The standing candidate inspected during handoff has a 46px visible body in its 64px frame. The sewer's earlier temporary figure has a 48px source body displayed at 1.25, giving a 60px visible world body. That enlargement is provisional and must not be silently baked into source sheets.

Use the actual environment at the same camera and foot position to compare 1× native source against the current 1.25× review display. `previews/sprite-native.png` and `sprite-review-scale.png` are actual Godot probes of the other workflow's candidate, not newly generated character art or final integration. No character source PNG is copied into this branch. The user must review the final scale before a full animation set is locked; keep body proportions consistent across directions and classes rather than resizing individual poses to their bounding boxes.

Actor ground position is cell centre + (0,12) in the current renderer. For display scale s, draw top-left = ground_position − (32,56)×s, frame size = (64,64)×s. Keep the root fixed in every frame; let walking contact points move naturally, and don't force crouching, crawling or death silhouettes to standing height. Keep the supported foot footprint inside the walkable square. Do not use weapon reach, scarf overhang or a tall sprite's full rectangle as collision.

At 1.25×, source pixels do not map uniformly to whole world pixels. This is a comparison with the existing review setting, not a final production pixel-density decision. Prefer a deliberate shared native scale once the artist and user compare it in the scene. Do not compensate by changing the 32px navigation grid or section art independently.

## Directional movement

The game permits 8-way steps. Current `ActorView` only has facing +1/−1, updated from horizontal movement; a right-only sheet cannot depict north/south walking correctly. Keep that compatibility output, and define directional assets separately instead of silently changing ART_JOBS rows.

Proposed order and vectors (screen y increases down): N (0,−1), NE (1,−1), E (1,0), SE (1,1), S (0,1), SW (−1,1), W (−1,0), NW (−1,−1). Use a real away-facing silhouette for north, toward-facing silhouette for south and intermediate diagonals. Preserve the last nonzero facing at idle. Visual direction follows actual successful movement; failed steps should not reset animation or slide the feet. Diagonals must use the movement system's existing timing/normalization, not an animation-driven positional offset.

The artist must declare direction coverage and whether any angles are mirrored. Do not silently swap scar/ear/scarf asymmetry, weapon hand or attachment sockets by mirroring a sheet. Document direction IDs, row/frame counts, fps, loop/one-shot status, root and weapon sockets in the directional manifest. Base bodies and weapons must use the same facing and animation phase. No eight-direction animation is claimed delivered until those frames exist and are reviewed.

## Integration acceptance

First compare an idle and walk strip in front of the junction, on a straight maintenance walk, on a supported bridge and around the cistern curve. At the same camera, inspect native and intended display size, all eight facings, foot planting, stride speed, stop/start transitions, diagonal travel, idle facing retention, socket registration and front-wall occlusion. Then exercise real movement with collision enabled. Keep dark clothing readable beside wet stone without baking environment-specific orange illumination into every sprite.

Movement-facing selection and animation playback require a later isolated integration change; this handoff does not claim the current left/right renderer already does it. Production combat/reaction rows remain the character workflow's responsibility. No merge is authorized by this coordination request.

## Reproduce the scale probe

Run Godot graphically with `--path <repo> --script res://assets/tiles/sewers/sections-v1/tooling/scale_probe.gd -- --sprite=/absolute/path/to/standing-candidate.png`. It uses the actual section renderer, the same camera and the same ground position for both captures. The supplied still remains a review candidate. Its original worktree and manifest are the authority for source provenance and readiness.
