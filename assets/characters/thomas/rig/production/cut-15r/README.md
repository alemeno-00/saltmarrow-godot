# Job15-R — approval and template-fit audit

Julian approved the whole south model on2026-10-31 and selected the warmer dark-brown coat. `../model-s.png` is the approved model with that requested colour change. It remains one80×80 frame,52px tall, south-facing, feet root(40,72). No parts sheet is delivered in this folder.

## Files

- `approved-charcoal-model.png`: one80×80 south model before the requested coat warming; approval provenance only, not another option.
- `approved-model-normal.png`: one80×80 matching normal before warming; identical to the current model normal because colour alone changed.
- `approval.json`: Julian's exact choice, coat ramp, changed-pixel count and approved warm-model checksum. Only180 coat pixels changed RGB; alpha, all other materials and normals are unchanged.
- `current-idle-placements.json`: eleven part placements from the real Godot4.7.2 `Rig.placements(RigPose.idle(0), south, (40,72))`, using unchanged main revision9765aee scripts in a temporary project. This is numerical evidence, not an in-game screenshot or final bind pose.
- `audit_template.py`: checks approved scarf pixels against the current torso cell using the template renderer's inverse nearest-neighbour sampling. No art is changed.
- `template-fit.json`: fit result and eight scarf pixels that cannot fit the current torso placement. It does not claim an animation or full parts validation.
- `.gdignore`: excludes review/audit files from game imports.

## Claude handoff before cutting

The current torso cell is24×24, pivot(12,22), placed at model(40,46.279...) in idle(0). At zero torso rotation, its last representable model row is47. The approved scarf reaches row51; eight scarf pixels on rows48–51 would fall outside that torso cell. The satchel/lantern also extend below this boundary. The brief assigns scarf and hip kit to the torso.

Please calibrate the template/source bind placement to the approved80×80 whole model before the cut. A lower torso bind anchor or different pivot/bounds needs an explicit rig/template decision; it must not silently change the approved model. The idle pose is not a defined source bind pose, so simply claiming a pixel-perfect source reassembly would not prove it fits the current game placements. Keep torso and carried kit intact, preserve the long skirt and two legs, and supply calibrated bind anchors for the eleven cells.

`assets/AGENTS.md` requires preserving documented pivots and flagging incompatible templates instead of silently changing the model or rig. Accordingly, runtime `rig/s.png` and `s_n.png` remain unchanged. Job15-R remains unchecked. After calibration, cut the same approved pixels, add only hidden joint overlap, prove source rest reassembly pixel-for-pixel, and inspect current idle/walk rendering before switching runtime art.
