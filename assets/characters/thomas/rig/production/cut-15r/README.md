# Job15-R — exact approved-model cut and historical fit audit

Julian approved the whole south model on2026-10-31 and selected the warmer dark-brown coat. `../model-s.png` is the approved model with that requested colour change. It remains one80×80 frame,52px tall, south-facing, feet root(40,72). Runtime parts are now delivered as ../../s.png and ../../s_n.png; this folder preserves their source masks and review evidence.

## Files

- `approved-charcoal-model.png`: one80×80 south model before the requested coat warming; approval provenance only, not another option.
- `approved-model-normal.png`: one80×80 matching normal before warming; identical to the current model normal because colour alone changed.
- `approval.json`: Julian's exact choice, coat ramp, changed-pixel count and approved warm-model checksum. Only180 coat pixels changed RGB; alpha, all other materials and normals are unchanged.
- `current-idle-placements.json`: eleven part placements from the real Godot4.7.2 `Rig.placements(RigPose.idle(0), south, (40,72))`, using unchanged main revision9765aee scripts in a temporary project. This is numerical evidence, not an in-game screenshot or final bind pose.
- `audit_template.py`: checks approved scarf pixels against the current torso cell using the template renderer's inverse nearest-neighbour sampling. No art is changed.
- `template-fit.json`: fit result and eight scarf pixels that cannot fit the current torso placement. It does not claim an animation or full parts validation.
- `.gdignore`: excludes review/audit files from game imports.

## Historical handoff — resolved by merged PR57

The current torso cell is24×24, pivot(12,22), placed at model(40,46.279...) in idle(0). At zero torso rotation, its last representable model row is47. The approved scarf reaches row51; eight scarf pixels on rows48–51 would fall outside that torso cell. The satchel/lantern also extend below this boundary. The brief assigns scarf and hip kit to the torso.

Please calibrate the template/source bind placement to the approved80×80 whole model before the cut. A lower torso bind anchor or different pivot/bounds needs an explicit rig/template decision; it must not silently change the approved model. The idle pose is not a defined source bind pose, so simply claiming a pixel-perfect source reassembly would not prove it fits the current game placements. Keep torso and carried kit intact, preserve the long skirt and two legs, and supply calibrated bind anchors for the eleven cells.

`assets/AGENTS.md` requires preserving documented pivots and flagging incompatible templates instead of silently changing the model or rig. At that stage runtime `rig/s.png` and `s_n.png` were left unchanged and job15-R stayed unchecked. The current delivery below resolves this historical handoff.


## Step2 delivered after PR55 merged

The calibrated `design/art-briefs/animation/rig/bind_s.json` now fits the approved model. Torso square is(28,29,24,24), pivot(12,21), at model(40,50). All91 scarf/strap/satchel/lantern pixels remain together on the torso; the skirt owns the lower coat panels through model row62. Two narrow trouser regions and both wrapped shins/boots are separate legs. All681 opaque model pixels belong to exactly one part.54 copied pixels provide hidden joint overlap (12 extend the same leg two rows upward;42 duplicate existing joint pixels); no visible source pixel or normal was repainted. Bind composition equals both approved images pixel for pixel.

### Current delivery files

- `export_cut.py`: deterministic ownership masks, bound-checked copies into the eleven24×24 cells, and explicitly hidden overlap copies from approved pixels. Writes runtime ../../s.png and ../../s_n.png,264×24, one row, south facing.
- `ownership.png`: one80×80 label frame, cell index+1 per visible approved pixel;0 transparent. This is diagnostic data, not painted art.
- `ownership.json`: part ids, visible-pixel counts, and every added overlap coordinate/occluder. No invented fill or rescaling.
- `bind-placements.json`: calibrated eleven-part bind placements from unchanged Godot Rig/RigPose. The earlier current-idle-placements.json belongs to the old failed template.
- `render_check.gd`: art-review driver for unchanged main Rig.compose/RigPose. Run in an isolated temporary Godot project with those scripts; the repo path is the user argument. Writes bind diffuse/normal, four16-frame motion strips, placements and check results under assets/.
- `render_motion.gd`: art-review driver for unchanged main RigMotion, rendering four seconds of idle, starting, walking, stopping and settling at60Hz, sampled every fourth step.
- `validate_cut.py`: repeatable provenance, format, unchanged source pixel ownership, kit ownership, hidden-overlap, frame-boundary and sampled connectivity checks.
- `export_previews.py`: nearest-neighbour packing and room composites of rendered motion frames. No art is painted.
- `motion-placements.json`: actual per-part placements for16 samples each of idle/walk/sneak/limp.
- `godot-check.json`: actual engine version,0 differing diffuse and0 differing normal bind pixels, sample counts and scope.
- `validation.json`: hashes, ownership/overlap accounting, exact alpha/format checks, sampled connectivity and protected reference checks.
- `previews/`: excluded from imports with its own README; bind comparison, parts, motion strips/boards and floor loops.

### Verification and practical limits

The supplied tools/rig/rig_template.gd checker was run unchanged in a temporary project for both diffuse and normal: each reports0 pixels differ.64 base-pose samples (idle, walk, sneak and limp) were rendered with real Rig.compose; the body remains one8-connected alpha component in every sample. This checks for detached pieces, not complete visual or anatomical correctness. The additional60 RigMotion transition samples exercise the actual easing/springs and also remain one8-connected component; a knee gap found during this check was fixed with one additional hidden overlap row. Room loops have no simulated game lights, shadows or movement across the floor.

The approved whole-model files are unchanged. Claude owns activating this south rig and sending Julian an in-game walk to approve. Do not start the remaining directions until that review. No code, scenes or studio files were changed; the only external-assets edit is ticking the delivered15-R job checkbox.
