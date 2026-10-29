# Two d10 dice — job8

Two ten-sided dice, ivory bone and charcoal slate with restrained amber facets. Every PNG has48×48 frames, genuine transparency and hard pixel edges. All pivots at(24,24). No numerals or text; resting values use pips.

| File | Rows / frames | Canvas |
| --- | --- | --- |
| bone_tumble.png |1 row,8 frames |384×48 |
| slate_tumble.png |1 row,8 frames |384×48 |
| bone_faces.png |1 row,10 resting faces,values1–10 left to right |480×48 |
| slate_faces.png |1 row,10 resting faces,values1–10 left to right |480×48 |
| bone_1.png, slate_1.png |1 row,1 frame each; value1 |48×48 each |
| bone_2.png, slate_2.png |1 row,1 frame each; value2 |48×48 each |
| bone_3.png, slate_3.png |1 row,1 frame each; value3 |48×48 each |
| bone_4.png, slate_4.png |1 row,1 frame each; value4 |48×48 each |
| bone_5.png, slate_5.png |1 row,1 frame each; value5 |48×48 each |
| bone_6.png, slate_6.png |1 row,1 frame each; value6 |48×48 each |
| bone_7.png, slate_7.png |1 row,1 frame each; value7 |48×48 each |
| bone_8.png, slate_8.png |1 row,1 frame each; value8 |48×48 each |
| bone_9.png, slate_9.png |1 row,1 frame each; value9 |48×48 each |
| bone_10.png, slate_10.png |1 row,1 frame each; value10 |48×48 each |

Claude: play tumble as a one-shot (suggested12fps), then select the resting cell by value minus1, or load the separate value file. Both dice can animate together with a small start offset. Tumble art is visual motion only; it does not encode the roll result. Use nearest filtering and no mipmaps. No code changes included.

production/v2/ contains final masters, reproducible export, native pip-component counts, comparison and animation previews. The older production candidates are superseded and must not be used. Resting silhouettes show the pointed poles, elongated kite faces and offset belt of a d10. All20 native resting cells have verified pip counts1–10, including separated ten-pip pits on bone10.
