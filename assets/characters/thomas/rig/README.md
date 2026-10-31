# Thomas — approved south model cut into rig parts (job15-R)

`production/model-s.png` is Julian's approved whole model from PR55, with the warmer dark-brown coat. The runtime parts below are cut from its exact pixels using the calibrated PR57 bind coordinates. No figure, face, costume, palette, camera or proportions were repainted.

| File | Cell size | Layout | Facing |
| --- | --- | --- | --- |
| `s.png` |24×24| One row of11 cells;264×24 total | South, toward viewer from raised room camera |
| `s_n.png` |24×24| Same11 cells, exact diffuse alpha | Matching OpenGL normal map, green up |

| Cell (1-based) | Part | Pivot in cell |
| --- | --- | --- |
|1|Head/hair/neck|(12,22)|
|2|Torso, whole scarf, strap, satchel and belt lantern|(12,21)|
|3|Long coat skirt below waist, hem at model row62|(12,2)|
|4|Left upper arm|(12,2)|
|5|Left forearm/hand|(12,2)|
|6|Right upper arm|(12,2)|
|7|Right forearm/hand|(12,2)|
|8|Left thigh|(12,2)|
|9|Left shin/wrap/boot|(12,2)|
|10|Right thigh|(12,2)|
|11|Right shin/wrap/boot|(12,2)|

Left/right are anatomical: Thomas's left is screen-right. The torso pivot is row21 as explicitly calibrated in PR57. Bind assembly is one80×80 frame,52px high, feet-root(40,72). All681 visible model pixels have one owning part. Another54 copied pixels provide small hidden joint overlaps (12 extend the same leg two rows upward;42 duplicate existing joint pixels); every overlap is covered by a later part in the bind pose. Both diffuse and normal maps reconstruct the approved whole images with0 differing pixels through the supplied Godot checker.

`production/cut-15r/` contains the ownership mask, exact coordinates, audit, exporter and current previews. `production/model-15r/` preserves the approved model's generation sources. Earlier direct-painted sources and `previews/` are historical rejected job15-0 material, not previews of this cut.

## Claude handoff

Switch the held-back south rig to these new parts and send Julian an in-game idle/walk review beside a room. The approved models, canonical reference and protected still/portrait paths remain unchanged. Only south is delivered; other directions await whole-model approval. Attacks remain on existing painted sheets.

The numerical bind checks and rendered motion samples use unchanged main Rig/RigPose/RigMotion from PR57 in Godot4.7.2. They are review composites, not screenshots of the game or a lighting approval. Actual dynamic lights, normal orientation during rotation, water masking, transitions and final camera appearance still need game review. No code or scenes were changed.
