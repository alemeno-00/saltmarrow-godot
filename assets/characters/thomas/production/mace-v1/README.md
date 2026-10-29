# Mace attack and ability study

Built-in imagegen, approved standing still as identity/costume reference. The ability master references the same attack master to retain the wooden haft and heavy iron block head. Final export uses nearest sampling, shared 31-colour palette, binary alpha, cleared hidden RGB, right facing, root (32,56). One fixed source scale per sheet; no frame stretching.

| File | Frame / canvas | Rows and counts |
| --- | --- | --- |
| attack-master.png | 1536×1024 source with gutters | wind-up3; strike3; recovery3; crit8 |
| attack_mace-3x.png | 192×192 preview cells / 1536×768 | 3,3,3,8 |
| attack_mace-validation.json | Report | Counts, size, scale, alpha |
| abilities-master.png | 1536×1024 source with gutters | Requested8,8,9,10,12; generator drew7 Knee Breaker poses |
| mace_abilities-candidate.png | 64×64 / 768×320 | Skull Crack8; Knee Breaker8; Shatter9; Wide Arc10; Execution12; REVIEW ONLY |
| mace_abilities-3x.png | 192×192 preview cells / 2304×960 | Same five rows; REVIEW ONLY |
| mace_abilities-validation.json | Report | Mechanical checks only |
| export.py | Art export source | Reproducible crop boxes and export |

Runtime delivery: ../../attack_mace.png, 64×64, rows3/3/3/8, canvas512×256. Empty trailing cells are transparent. Wind-up ends with the maul raised as a visible threat. Critical strike is slower; suggested6fps, ordinary strike12fps, recovery7fps. Attack sheet includes the whole body and weapon, so Claude should replace the body sprite during this action rather than overlaying a second body.

Job2b remains unchecked: the 47-cell study overlaps neighbouring figures/mauls, so some crops contain fragments or clipped extremities. One deliberate anticipation hold repeats the opening Knee Breaker pose to supply its eighth timing cell, but this does not fix the overlap. Do not load this candidate or rename it to the runtime filename. The abilities need isolated per-ability passes before assembly; no code integration is requested for them.

Prompt set: attack wind-up3, strike3, recovery3, heavier overhead critical8; then Skull Crack8 short overhead, Knee Breaker8 low sweep, Shatter9 chest smash, Wide Arc10 full spin, Execution12 high held overhead into ground strike. Preserve canonical greatcoat, red scarf, satchel, amber lamp and fixed two-handed iron maul. Hard pixel art, no scenery/text, transparent cutouts.

## Follow-up refinement audit

A second attempt generated each ability independently (Skull Crack8,Knee Breaker8,Shatter9,Wide Arc10,Execution12) using the same attack source. Those strips still touched adjacent silhouettes,clipped maul heads at canvas edges,and in Execution omitted the final maul head. These variants were discarded rather than promoted. Job2b is too large for reliable strip generation here; split into individual keyed poses with explicit weapon registration before assembling the47-frame runtime sheet. The runtime mace_abilities.png remains absent.

Superseded: job2b is now delivered at ../../mace_abilities.png using the clean grids and silhouette export in ../abilities-v2/. The failures above describe this older study only.
