# South walk production archive

All character frames face south, 80 × 80 at game size and 320 × 320 for 4× painting. Sources/previews are excluded from Godot import by `.gdignore`.

| File/folder | Layout / purpose |
| --- | --- |
| `walk_s_4x.png` | 2560 × 320, 8 × 320 × 320 diffuse painting frames in one row |
| `walk_s_n_4x.png` | Same eight-frame row, independent normal paintings with exact final diffuse alpha |
| `walk_s.png` | 640 × 80, eight 80 × 80 palette-snapped diffuse walk frames |
| `walk_s_n.png` | Same eight-frame row, palette-snapped normal maps |
| `15w-step-a/` | Approved keys 1,3,5,7; immutable artwork and original review records; see its README |
| `15w-step-b/` | Approval record, independent in-betweens 2,4,6,8, eight normal sources, export/check records and complete-loop previews; see its README |
| `.gdignore` | Excludes this archive from game imports |

The supplied `tools/pose_guides/walk_guides.gd -- shrink` made both game-size rows, using the approved model palettes (with `normal` for normals). `15w-step-b/assemble_runtime.py` copies the six idle model frames and these eight walk frames into the two runtime sheets beside this folder. The unchanged upstream checker passes all eight actual runtime frames; see `15w-step-b/guide-check.txt`.
