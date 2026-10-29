# Thomas body production pass

Generated with the built-in imagegen tool using the approved standing still as the identity and costume reference; mechanically exported with nearest sampling, binary alpha and a shared 31-colour palette. No approved source image was altered.

| File | Size / layout | Rows and populated counts |
| --- | --- | --- |
| locomotion-master.png | 1774×887 source, variable gutters | idle 4; walk 6 |
| injury-master.png | 1536×1024 source, variable gutters | sneak 6; hurt 3; wounded walk 6 |
| ground-master.png | 1774×887 source, variable gutters | dying crawl 6; death 6 |
| body-4x.png | 1536×1792, 256×256 preview cells | 4,6,6,3,6,6,6 |
| idle.gif | 256×256 preview | idle 4 |
| walk.gif | 256×256 preview | walk 6 |
| sneak.gif | 256×256 preview | sneak 6 |
| hurt.gif | 256×256 preview | hurt 3 |
| wounded_walk.gif | 256×256 preview | wounded walk 6 |
| dying_crawl.gif | 256×256 preview | dying crawl 6 |
| death.gif | 256×256 preview | death 6; preview repeats, runtime must hold last |
| export.py | Art export source | Isolates transparent gutters, uses one scale per source pass, assembles sheet and previews |
| validation.json | Export report | Dimensions, alpha, counts, source scales and occupied bounds |

All figures face right. Root (32,56), with floor contact ending at y55. For crawl/death this is the ground anchor, not an upright foot requirement. Unequal lengths have empty trailing cells. The seven-row runtime output is ../../body.png (384×448).

Prompt set: (1) canonical Thomas, four subtle breathing poses and six alternating walk poses; (2) six crouched sneak, three backward recoil hurt, six limping walk clutching ribs, followed by background extraction; (3) six prone reach/plant/pull crawl poses, six progressive death poses from buckling knees to still on ground. All prompts required empty hands, fixed anatomy, canonical greatcoat/scarf/satchel/amber belt lamp, right facing, hard pixel art and transparency. Source canvases are not runtime grids.

Checks: 37 populated cells, five empty trailing cells; binary alpha; all frames fit inside 64×64; no duplicated full-cell hashes; enlarged silhouette inspection. Distinct pose progressions replace the rejected full-sheet study. This is a first animation art delivery for review; final engine playback and timing belongs to Claude. Use nearest filtering and no mipmaps. Do not import master canvases or previews as animation sheets.
