# Current15-R cut review previews

All images derive from the unchanged approved model or actual Godot Rig.compose output. No frames are repainted. South facing, raised room camera,80×80 frame, root(40,72). Nearest-neighbour enlargement only. These are mechanical review composites, not screenshots of the running game or lighting approval.

- `bind.png`, `bind_n.png`: one80×80 reconstructed bind frame each; exact diffuse and normal matches to the approved whole-model images.
- `bind-8x.png`: same bind frame enlarged8×,640×640.
- `model-and-bind-6x.png`: approved model on left, reconstructed bind on right; two80×80 panels enlarged6×,960×480.
- `parts-8x.png`, `parts-normal-8x.png`: runtime11 cells of24×24 repacked into4 columns×3 rows, last cell empty, enlarged8× to768×576. Reading order is runtime cell order; not animation frames.
- `idle-16.png`, `walk-16.png`, `sneak-16.png`, `limp-16.png`: each one row of16 samples,80×80 frames,1280×80 total. Rendered by unchanged Rig.compose/RigPose; no RigMotion easing in these four strips.
- `idle-8frames-4x.png`, `walk-8frames-4x.png`, `sneak-8frames-4x.png`, `limp-8frames-4x.png`: every second sample from the corresponding strip, four columns×two rows, enlarged4× to1280×640.
- `idle-floor-3x.gif`, `walk-floor-3x.gif`, `sneak-floor-3x.gif`, `limp-floor-3x.gif`: those16 samples over an unchanged192×192 junction-floor crop enlarged3× to576×576. Thomas stays at a fixed root to inspect limb motion; this does not test travel or foot sliding through a room. Loop lengths2.4s,0.8s,1.28s and1.04s respectively.
- `start-walk-stop-60.png`: one row of60 samples,80×80 frames,4800×80. Unchanged RigMotion simulated at60Hz over4s, sampled every fourth step:0.5s idle,2s moving at45px/s,1.5s stopping/settling. Root stays fixed for inspection.
- `start-walk-stop-floor-3x.gif`: same transition on the floor crop,576×576,4s loop. The loop restarts after settling.
- `.gdignore`: review media excluded from game imports.
