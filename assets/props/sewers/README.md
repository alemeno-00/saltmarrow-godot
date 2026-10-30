# Sewer room contents — job 14

18 diffuse PNGs and 15 companion world-prop normal maps, 30 diffuse frames: belt icons, caches, lore drops, a turning valve, both grate orientations, three bone and three debris variants. Designed for the approved sewer room kit. All artwork was painted with the built-in image-generation tool; prompt specifications, source masters and repeatable exports are in `production/`.

## Runtime files

Frames run left to right without gaps. Everything is PNG RGBA, hard edges, binary alpha and at most 32 opaque RGB colours per diffuse sheet. No readable text or numerals. The three inventory icons have dark charcoal outlines.

| File | Normal map | Frame size | Rows / frame counts | State order |
| --- | --- | --- | --- | --- |
| `salve.png` | UI only | 32×32 | 1 / 1 | static |
| `bandage.png` | UI only | 32×32 | 1 / 1 | static |
| `grate_key.png` | UI only | 32×32 | 1 / 1 | static |
| `crate.png` | `crate_n.png` | 32×32 | 1 / 2 | closed, opened |
| `barrel.png` | `barrel_n.png` | 32×32 | 1 / 2 | closed, opened |
| `satchel_body.png` | `satchel_body_n.png` | 64×32 | 1 / 2 | closed satchel, searched satchel |
| `letter.png` | `letter_n.png` | 32×32 | 1 / 1 | static |
| `hymn_sheet.png` | `hymn_sheet_n.png` | 32×32 | 1 / 1 | static |
| `miner_tag_body.png` | `miner_tag_body_n.png` | 64×32 | 1 / 1 | static |
| `valve.png` | `valve_n.png` | 32×32 | 1 / 4 | turn 0, turn 1, turn 2, turn 3 |
| `bones_1.png` | `bones_1_n.png` | 32×32 | 1 / 1 | static |
| `bones_2.png` | `bones_2_n.png` | 32×32 | 1 / 1 | static |
| `bones_3.png` | `bones_3_n.png` | 32×32 | 1 / 1 | static |
| `debris_1.png` | `debris_1_n.png` | 32×32 | 1 / 1 | static |
| `debris_2.png` | `debris_2_n.png` | 32×32 | 1 / 1 | static |
| `debris_3.png` | `debris_3_n.png` | 32×32 | 1 / 1 | static |
| `grate_ns.png` | `grate_ns_n.png` | 64×32 | 2 / 2/2 | shut 1, shut 2, open 1, open 2 |
| `grate_ew.png` | `grate_ew_n.png` | 32×64 | 2 / 2/2 | shut 1, shut 2, open 1, open 2 |

## Grate format — confirmed by Julian

Each grate has **four frames total: two shut, two open**, as Julian specified in this session. Each state gets its own animation row:

- `grate_ns.png`: frame **64×32**, canvas **128×64**. Row 1 is shut (2); row 2 is open (2). Its long axis is east–west, across a north–south tunnel.
- `grate_ew.png`: frame **32×64**, canvas **64×128**. Row 1 is shut (2); row 2 is open (2). Its long axis is north–south, across an east–west tunnel.

These are authored orientations, not one file rotated by the game. The fixed frame remains in place while the small latch/chain settles. Open NS raises the leaf into the top beam; open EW stacks it at the right side. All openings are real transparency, so the room floor shows through. Use row indexes 0/1 in code. Holding the first frame of a state is also valid; the second supplies subtle idle movement. Do not play across the row boundary as a four-frame turn.

## Placement and facing

All origins are frame centres, measured from upper-left (+x right, +y down):

- 32×32 sprites: **(16,16)**, one map square.
- 64×32 bodies and NS grate: **(32,16)**, two horizontal squares.
- 32×64 EW grate: **(16,32)**, two vertical squares.

Draw each selected frame at its logical footprint’s upper-left, or position its centre at the footprint centre. Cache pairs use a common source scale; crate and barrel share a bottom-centre baseline. Body cache frames are centred and change the satchel flap. Grate source planes are fitted to identical native bounds for stable state registration. `manifest.json` records crops, scales, origins and alignment.

Both miners lie with **head right, boots left**, as requested for directional art. Their flat caps, slate coats and wet brown trousers match one another; the tally body uses the satchel-body source as its identity reference. The tally tag hangs on a loose cord over the visible upper coat beside the collar. The letter has Ellen’s copper-red wax seal; the hymn sheet uses indistinct ink strokes, not readable writing. Both bodies use a more overhead, face-down pose, broader shoulder and hip footprint, and material-coloured broken edges. Small opaque contact-dark clusters hug the bearing shoulder, hip and boots; no floor patch or directional cast shadow is baked in. Other clutter remains low floor decoration. See `previews/body-before-after-closeup.png` (before left, revised right).

Gameplay determines interaction, placement and collision. In particular, a shut grate blocks movement even where alpha has holes; an open grate must use open-state collision. Do not infer any of that from sprite pixels. Add real lighting in game. Godot 4.7 uses nearest sampling; no smoothing.

## Suggested timing and handoff

- Caches: show closed frame, then hold opened/searched frame after the interaction. They are states, not a looping animation.
- Valve: four turning frames, about 150ms each for initial review; code should decide when to turn or hold.
- Grates: two frames within the selected row, about 300ms each for initial review, or hold the first. Claude should tune timing in gameplay.

Job15a regrades these existing diffuse PNGs in place and adds normal maps; no code, scenes, data or blockouts are changed. Claude still needs to wire item icons, cache/lore states, valve turning and grate rows into the corresponding systems and review real lighting. The placement preview is an art assembly, not an engine screenshot.

## Other files

- `manifest.json`: complete inventory, frame layout, source registration and SHA256 checksums.
- `validation.json`: sizes, palette/alpha, silhouette margins, unique frames, clutter variety and open-grate visual clearance checks.
- `production/README.md`: source/prompt/export inventory; `.gdignore` excludes references.
- `previews/README.md`: native-derived contact sheets, state GIFs, icon/grate enlargements and placement review; `.gdignore` excludes them.

## Job 15a — house-style audit

All 18 diffuse sheets were checked and palette-registered to the painted rooms' `production/palette.json`, retaining each original silhouette, frame, state and native texture cluster. Near-black residual outlines take the adjacent material's darker room tone; bearing bottom pixels are damp/darker. No directional light, bright rim, new floor patch or cast-shadow shape is added. The recently approved face-down miner poses are unchanged.

All 15 props that stand in the world have matching `_n.png` files, same alpha/layout, with rounded OpenGL surface normals (+green up). The three inventory-only icons keep their flat UI treatment and charcoal outline; they are not world-lit sheets. Normal colours encode direction and are not limited to the diffuse palette. Origins, footprints and the confirmed grate rows remain unchanged; open-grate holes are exactly the original alpha.

This checks house-style rules1–7; rule8's larger character scale does not apply to props. Current source/prompt/audit inventory and export: `production/house-style/README.md`. It supersedes the initial export's palette, but uses its generated art and states. Current validation is in `validation.json` and Thomas's `production/room-fit/validation.json`. Rerun the house-style export after any original stage export.
