# Thomas — south painted locomotion (job 15-W)

South-facing only, from the rooms’ raised camera. Frame 80 × 80; nominal floor root (40,72). PNG, binary alpha, exact approved model palette. Heads and boots retain their corresponding supplied guide pixels. These files do not alter the approved model or rig parts.

| File | Size | Row 1 | Row 2 |
| --- | --- | --- | --- |
| `s.png` | 640 × 160 | 6 identical approved-model idle frames; 2 transparent padding cells | 8 painted walk frames, left to right |
| `s_n.png` | 640 × 160 | Same layout, approved-model normals | Matching 8 walk normal maps, green up |

Suggested playback matches the existing animation brief: idle 6 fps (all six copies identical), walk 10 fps (0.8-second loop). No wounded walk, sneak, careful-step or attack rows are delivered here. `production/` contains the painting rows, sources, prompt archive, checks and previews; its README lists those files. Unrelated `test/` art is not part of this delivery.

## Claude handoff

The current `ActorView._draw_sheet()` gives the rig priority. Prefer this painted south sheet for **idle and walk** when available, retaining the existing fallbacks for other actions and directions. `Sheet.directions()` currently registers five rows unconditionally; this delivery has only two, so register only delivered rows rather than sampling rows 3–5. Keep normal-map pairing and current grounding/shadows. No code is changed in this art PR. Review the resulting walk in game before expanding to other directions.
