# Drowned Miner

`body.png` and `body_n.png`: 64×64 frames, 384×1024 canvas, right facing, root (32,56). One row per animation; frames left to right without gaps, unused trailing cells transparent. Binary alpha and hard pixel edges.

| Row | Animation | Frames |
| --- | --- | --- |
| 1 | idle | 4 |
| 2 | walk | 6 |
| 3 | attack wind-up tell | 3 |
| 4 | attack | 3 |
| 5 | hurt | 3 |
| 6 | pushed back | 3 |
| 7 | wall slam | 3 |
| 8 | dazed | 4 |
| 9 | knocked prone | 4 |
| 10 | lying prone | 2 |
| 11 | getting up | 4 |
| 12 | limping walk | 6 |
| 13 | flee | 6 |
| 14 | death | 6 |
| 15 | dismembered death | 6 |
| 16 | skull crushed | 6 |

Loop idle, walk and other locomotion; loop dazed, lying prone or singing when present. Death variants are non-looping and hold the final frame. Suggested 6 fps generally, 4 fps idle/dazed/singing, 10 fps impacts. Claude should wire only populated counts. These sheets contain the complete character and weapon when present. No code changes included.

Generated with built-in imagegen; see production for sources and export report. Pearly eyes, faint throat light and salt at garment edges tie both enemies to the star.

## Job 15a house-style check

Checked: local material-coloured contour without pure black; the shared room palette and native texture clusters; lighter face/hands against darker clothing; existing limb gaps; damp dark contact pixels; neutral ambient albedo; matching rounded OpenGL normal map; unchanged64×64 frames/root32,56. No floor patch, bright rim or baked cast shadow. Julian approved a muted-red exception for blood. All other diffuse colours come from the rooms' `production/palette.json`. Original pose details and binary alpha are retained exactly.

`body_n.png` matches every populated and empty frame of `body.png`; +R right, +G up, +B forward, normalized positive-Z vectors. The existing game loader discovers it. Current sources, prompts, per-row GIFs and controlled left/right light reviews: `production/room-fit/README.md`. Shared export and validation scripts live in Thomas's `production/room-fit/`. These are art-file and compositing checks, not engine screenshots. Earlier production exporters are historical stages and overwrite this pass if run alone.
