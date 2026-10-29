# Final dice source and validation

| File | Layout |
| --- | --- |
| bone-rest-master.png |Source grid2×5,values1–10 |
| slate-rest-master.png |Source grid2×5,values1–10 |
| bone-tumble-master.png |Source grid2×4,8 rotational poses |
| slate-tumble-master.png |Source grid2×4,8 rotational poses |
| bone-ten-master.png |Single corrected bone10 source with ten separated square pits |
| comparison-3x.png |1440×576;144×144 cells;bone tumble8/face10 then slate tumble8/face10 |
| bone-tumble.gif |240×240 preview,8 frames |
| slate-tumble.gif |240×240 preview,8 frames |
| export.py |Alpha silhouette extraction,nearest sampling,palette export and pip counting;run from any folder |
| validation.json |Native frame dimensions and pip counts for both dice |

Built-in imagegen prompts: two ten-sided pentagonal trapezohedra with kite-shaped facets,pointed poles and offset five-sided belt;ivory bone/charcoal outline and slate/amber/ivory variants. Resting grid2×5 requires exact1–10 pips,unmarked other facets,48px hard pixel art,transparent whole silhouettes,no text/numerals/smoothing. Pip layouts:1 single,2 two,3 triangle,4 two-by-two,5 corners/centre,6 two columns of3,7 four/three,8 two columns of4,9 three-by-three,10 two columns of5. Matching eight-pose tumbles were edited from each corrected rest master. Bone10 received a single-face correction to smaller square pits with clear gaps after downsampling joined two circular pips.

Mechanical export uses connected alpha silhouettes,nearest-neighbour sampling,one fixed scale per source pass,31-colour palette,binary alpha and cleared hidden RGB. No pips are procedurally drawn or replaced. The corrected bone10 image is registered to the same resting silhouette height before sampling. Pip validation counts disconnected contrasting components in the centre of each native48×48 resting cell,excluding rim decoration. Both arrays must equal[1,2,3,4,5,6,7,8,9,10]. Side-by-side enlarged visual review confirms the count and d10 reading. Engine timing remains for Claude.
