# Mace effects

Each strip has one row,frames left to right,no gaps,genuine transparency,binary alpha and hard pixel edges. Pivot is frame centre. Directional effects face right; game may mirror.

| File | Frame | Frames / canvas |
| --- | --- | --- |
| dazed.png |32×32 |6 /192×32; loop above head,no cartoon stars |
| fracture.png |32×32 |4 /128×32 |
| wall_slam.png |64×64 |5 /320×64 |
| wide_arc.png |96×96 |4 /384×96 |
| helm_break.png |32×32 |6 /192×32 |
| pauldron_break.png |32×32 |6 /192×32 |
| breastplate_break.png |32×32 |6 /192×32 |
| helm_rest.png |32×32 |1 /32×32 |
| pauldron_rest.png |32×32 |1 /32×32 |
| breastplate_rest.png |32×32 |1 /32×32 |

Suggested10fps for impacts/debris,6fps for dazed. Dazed progressively dims before restarting; its final frame is deliberately faint. After debris frame6,spawn the matching resting sprite on the floor. Only dazed loops; all others are one-shots. Claude should place wall slam at collision,fracture at hit point,and Wide Arc around the attacker. No code changes included.
