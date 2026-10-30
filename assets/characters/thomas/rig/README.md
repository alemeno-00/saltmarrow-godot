# Thomas south-facing rig parts — job 15-0

Painted over the south template from the skeleton brief at revision5d836a0. This replaces painting every walking frame separately: the rig moves the same eleven drawings. South faces the viewer, seen from the raised room camera.

| File | Cell size | Layout |
| --- | --- | --- |
| `s.png` | 24×24 | One row of11 cells;264×24 total |
| `s_n.png` | 24×24 | Matching OpenGL normal map, green up, identical alpha |

Cells left to right, using Thomas's anatomical left/right:

| Cell (1-based) | Part | Pivot in cell |
| --- | --- | --- |
| 1 | Head/hair/neck | (12,22) |
| 2 | Torso, scarf, strap, belt, hip lantern | (12,22) |
| 3 | Split coat skirt below waist | (12,2) |
| 4 | Left upper arm | (12,2) |
| 5 | Left forearm/hand | (12,2) |
| 6 | Right upper arm | (12,2) |
| 7 | Right forearm/hand | (12,2) |
| 8 | Left thigh | (12,2) |
| 9 | Left shin/wrap/boot | (12,2) |
| 10 | Right thigh | (12,2) |
| 11 | Right shin/wrap/boot | (12,2) |

Head and torso extend upward from their pivots; limbs and skirt hang straight down. All11 pivots have painted material. Joint coverage is extended to overlap adjacent pieces. The torso owns the belt; the current v2 skirt source is already belt-free. Each piece is registered once, rather than repositioned separately for each animation frame.

House-style checks: shared room palette plus Julian's approved four muted reds; coloured material edges; hard binary transparency; worn pixel clusters; lighter face/hands and dark charcoal coat; damp boot contact pixels; neutral diffuse colouring and no added shadow. The head, shoulders and boot tops are drawn for the raised camera. Mechanical standing assembly is52px tall on an80×80 preview with root(40,72).

`production/` preserves the template, generated master, prompts, fixed registration, normal-map source and mechanical export/preview scripts. `previews/` contains the parts, standing assembly, eight-frame walking loop and floor comparison. Both folders are excluded from Godot imports.

## Claude handoff

The skeleton branch's existing loader reads this folder's `s.png`; attach `s_n.png` through the intended rig lighting support. No code, scenes or existing sprite assets were edited. This sheet depends on the skeleton implementation and revised job15-0 brief, which were read from branch`skeleton` rather than the older main-branch job description.

The previews mechanically reproduce that pinned rig's placements and camera; they are not screenshots of the running game. Check rotations for exposed seams, near/far limb ordering, camera fit, moving foot contact and normal orientation under actual lights. Julian's in-game approval is pending; other directions have not been started. Keep job15-0 unchecked until that review is complete.

## Readability revision v2

The runtime sheets now use polish-v2 sources: clearer pale facial features and hands, charcoal coat/lapels, distinct brown leather and trousers, and cleaner scarf/wrap clusters. The head was repainted separately for its 9×9 native artwork. Cell sizes, part order, rig pivots and assembled 52px height remain the same. The normal map was regenerated. The torso painting was registered one pixel sideways to cover the unchanged waist pivot.

Before-and-after images are in previews/polish-before-after-8x.png and previews/polish-room-before-after-3x.png (before left, revision right). Actual game lighting and camera approval remain pending.
