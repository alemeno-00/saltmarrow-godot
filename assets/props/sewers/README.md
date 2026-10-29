# Sewer room contents — job 14

18 runtime PNGs, 30 frames: belt icons, caches, lore drops, a turning valve, both grate orientations, three bone and three debris variants. Designed for the approved sewer room kit. All artwork was painted with the built-in image-generation tool; prompt specifications, source masters and repeatable exports are in `production/`.

## Runtime files

Frames run left to right without gaps. Everything is PNG RGBA, hard edges, binary alpha and at most 32 opaque RGB colours per sheet. No readable text or numerals. The three inventory icons have dark charcoal outlines.

| File | Frame size | Rows / frame counts | State order |
| --- | --- | --- | --- |
| `salve.png` | 32×32 | 1 / 1 | static |
| `bandage.png` | 32×32 | 1 / 1 | static |
| `grate_key.png` | 32×32 | 1 / 1 | static |
| `crate.png` | 32×32 | 1 / 2 | closed, opened |
| `barrel.png` | 32×32 | 1 / 2 | closed, opened |
| `satchel_body.png` | 64×32 | 1 / 2 | closed satchel, searched satchel |
| `letter.png` | 32×32 | 1 / 1 | static |
| `hymn_sheet.png` | 32×32 | 1 / 1 | static |
| `miner_tag_body.png` | 64×32 | 1 / 1 | static |
| `valve.png` | 32×32 | 1 / 4 | turn 0, turn 1, turn 2, turn 3 |
| `bones_1.png` | 32×32 | 1 / 1 | static |
| `bones_2.png` | 32×32 | 1 / 1 | static |
| `bones_3.png` | 32×32 | 1 / 1 | static |
| `debris_1.png` | 32×32 | 1 / 1 | static |
| `debris_2.png` | 32×32 | 1 / 1 | static |
| `debris_3.png` | 32×32 | 1 / 1 | static |
| `grate_ns.png` | 64×32 | 2 / 2/2 | shut 1, shut 2, open 1, open 2 |
| `grate_ew.png` | 32×64 | 2 / 2/2 | shut 1, shut 2, open 1, open 2 |

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

Both miners lie with **head right, boots left**, as requested for directional art. Their flat caps, slate coats and wet brown trousers match one another; the tally body uses the satchel-body source as its identity reference. The tally tag is visible on the chest. The letter has Ellen’s copper-red wax seal; the hymn sheet uses indistinct ink strokes, not readable writing. Clutter is low floor decoration, without baked floor or ground shadows.

Gameplay determines interaction, placement and collision. In particular, a shut grate blocks movement even where alpha has holes; an open grate must use open-state collision. Do not infer any of that from sprite pixels. Add real lighting in game. Godot 4.7 uses nearest sampling; no smoothing.

## Suggested timing and handoff

- Caches: show closed frame, then hold opened/searched frame after the interaction. They are states, not a looping animation.
- Valve: four turning frames, about 150ms each for initial review; code should decide when to turn or hold.
- Grates: two frames within the selected row, about 300ms each for initial review, or hold the first. Claude should tune timing in gameplay.

No code, scenes, data, blockouts or existing art were changed. Claude still needs to wire item icons, cache/lore states, valve turning and grate rows into the corresponding systems and review real lighting. The placement preview is an art assembly, not an engine screenshot.

## Other files

- `manifest.json`: complete inventory, frame layout, source registration and SHA256 checksums.
- `validation.json`: sizes, palette/alpha, silhouette margins, unique frames, clutter variety and open-grate visual clearance checks.
- `production/README.md`: source/prompt/export inventory; `.gdignore` excludes references.
- `previews/README.md`: native-derived contact sheets, state GIFs, icon/grate enlargements and placement review; `.gdignore` excludes them.
