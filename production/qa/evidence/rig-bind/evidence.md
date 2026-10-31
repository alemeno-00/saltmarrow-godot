# Rig fitted to the approved model (job 15-R, PR #55 handoff) — 2026-10-31

- The approved south model (`assets/characters/thomas/rig/production/model-s.png`, from #55) was measured: neck row 30,
  shoulders row 32 (x 33, 47), elbows row 40, hands row 48, hips row 50 (x 36, 44), knees row 59, ankles row 68, hem
  row 62. `RigPose` now uses those proportions; `RigPose.bind()` stands as painted.
- In the bind pose all 11 parts sit at angle 0 with pivots on whole pixels (`tests/test_rig.gd`).
- Fit audit against the model and its material ids: 91 scarf, strap, satchel and lantern pixels, 0 outside the torso's
  square (rows 29–52); 0 model pixels outside every part's square.
- `reference-cut-parts.png`: a rough mechanical cut by region (not the art cut; no joint overlap), only to prove the
  machinery. Put back together in the bind pose by `tools/rig/rig_template.gd -- check`: 0 pixels differ.
- `reference-cut-bind-idle-walk.png` (4 x): that rough cut in the bind pose, idle, and the first walk frames.
