# Dice generation record

| File | Frame / layout |
| --- | --- |
| bone-master.png |2172×724 source,tumbling8 then resting10 intended |
| slate-master.png |1974×790 source,tumbling8 then resting10 intended |
| bone-candidate.png |48×48 cells,480×96;row1 tumbling8 plus2 empty,row2 resting10 intended |
| slate-candidate.png |48×48 cells,480×96;same layout |
| bone-3x.png |144×144 preview cells,1440×288 |
| slate-3x.png |144×144 preview cells,1440×288 |
| export.py | Reproducible mechanical export from repository root |

Built-in imagegen prompts requested a true ten-sided pentagonal trapezohedron,ivory-bone and charcoal-slate variants,8 tumbling orientations,10 resting faces with exactly1–10 pips,other facets unmarked,48px target,1px dark outline,transparent hard pixel art,no numerals/text/scene. Visual review found repeated pip counts and questionable facet geometry. Candidate export validates canvas and binary transparency only,not numerical accuracy. Final resting faces need individual correction and pip counting before runtime delivery. Sources excluded by .gdignore.
