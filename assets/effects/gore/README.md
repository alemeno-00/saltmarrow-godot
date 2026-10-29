# Blood and gore — job6

All separate files are32×32 transparent PNGs,one row,one frame each. Floor perspective is slightly elevated; no directional mirroring needed. Blood is dark oxblood red,with hard edges and binary alpha.

| File | Contents |
| --- | --- |
| pool_small.png | Small pool |
| pool_medium.png | Medium pool |
| pool_large.png | Large pool |
| splatter_1.png | Radial splatter |
| splatter_2.png | Diagonal splatter |
| splatter_3.png | Crescent splatter |
| splatter_4.png | Fan splatter |
| drag_smear_1.png | Narrow dragging streak |
| drag_smear_2.png | Broad broken dragging streak |
| blood_decals.png |96×96 atlas: row1 pools small/medium/large; row2 splatter1/2/3; row3 splatter4/drag1/drag2. Nine static cells,not an animation. |

The remaining floor parts are supplied as stylized32×32 transparent sprites,one row and one frame each:

| File | Contents |
| --- | --- |
| severed_arm.png | Torn brown work sleeve and gloved hand,pointing down-right |
| severed_head.png | Generic adult head,short dark hair,closed eyes,facing right |
| flesh_chunk_1.png | Small angular maroon lump |
| flesh_chunk_2.png | Wider irregular maroon lump |
| flesh_chunk_3.png | Rounded maroon lump |
| flesh_chunk_4.png | Compact asymmetrical maroon lump |
| gore_parts.png |96×64 static atlas: row1 arm/head/chunk1;row2 chunk2/chunk3/chunk4;32×32 cells |

All15 requested individual decals/parts are delivered. Parts occupy a subset of each32px cell so their floor scale stays compatible with64px characters. They use flat dark-maroon cut surfaces and small abstract flesh shapes. The earlier full-sheet request failed generation; these separate stylized props complete the missing files.

Claude can place these32×32 decals on the floor and retain them after combat. No code changes included.
