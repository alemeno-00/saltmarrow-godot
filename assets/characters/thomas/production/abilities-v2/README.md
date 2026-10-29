# Mace abilities — delivered job 2b

Built-in imagegen with the reviewed mace attack master as the identity, costume and weapon reference. Poses were generated in small grids rather than crowded horizontal strips. Alpha-connected silhouette extraction keeps a neighbouring figure out of each crop even when their bounding rectangles overlap. No pose is drawn or interpolated by the exporter.

| File | Layout / frames |
| --- | --- |
| skull_crack-master.png | Source grid: 2 rows of 4 poses, 8 total |
| knee_breaker-master.png | Source grid: 2 rows of 4, 8 total |
| shatter-master.png | Source grid: 3 rows of 3, 9 total |
| wide_arc-master.png | Source grid: 2 rows of 5, 10 total |
| execution-master.png | Source grid: 3 rows of 4, 12 total |
| sheet-3x.png | 2304×960 preview; 192×192 cells; row counts 8,8,9,10,12 |
| skull_crack.gif | 256×256 preview, 8 frames |
| knee_breaker.gif | 256×256 preview, 8 frames |
| shatter.gif | 256×256 preview, 9 frames |
| wide_arc.gif | 256×256 preview, 10 frames |
| execution.gif | 256×256 preview, 12 frames, including the overhead hold |
| export.py | Reproducible silhouette extraction and mechanical export |
| validation.json | Source bounds, fixed source scales, final dimensions, counts and alpha |

Final: ../../mace_abilities.png, 768×320, 64×64 frames, five animation rows with counts 8/8/9/10/12. Frames left to right; shorter rows have transparent trailing cells. Ground root (32,56). All start/end facing right; Wide Arc naturally rotates through other views during its full spin. Each ability includes wind-up, strike and recovery. Execution frames5–7 form its raised hold; Claude can slow those frames further. Suggested phase splits (one-based inclusive): Skull Crack wind-up1–4/strike5–6/recovery7–8; Knee Breaker1–4/5–6/7–8; Shatter1–4/5–7/8–9; Wide Arc1–2/3–8/9–10; Execution1–7/8–10/11–12. No code changes included.

Prompt set: preserve canonical lean Thomas, dark charcoal/wet brown greatcoat, red scarf, short brown hair/stubble, satchel, amber belt lantern, same heavy iron block head and wooden haft, both hands gripping, fixed anatomy/weapon size, transparent hard pixel art, no text/grid/smoothing. Skull Crack: guard, brace, shoulder lift, threatening overhead, descent, impact, follow-through, guard. Knee Breaker: guard, crouch, low backswing, hip turn, shin-height sweep, extension, pullback, guard. Shatter: guard, brace, drawback, coil, forward drive, chest-height smash, follow-through, pullback, guard. Wide Arc: guard, backswing, front three-quarter, front, left, back three-quarter, back, right sweep, follow-through, guard. Execution: guard, brace, shoulder lift, overhead, three raised holds, descent, fast descent, ground impact, follow-through, settle. Each prompt requested complete silhouettes and generous gutters in its source grid.

Checks: all47 populated cells and13 empty trailing cells, binary alpha0/255, hard nearest sampling, shared31-colour palette, fixed scale per source pass, complete maul silhouettes and enlarged sheet inspection. Source bounds are retained so this export is auditable. Earlier rejected strips under ../mace-v1/ are superseded. Engine timing and contact placement remain for Claude's integration review.
