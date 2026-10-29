# Paint-over brief: the Outflow

The first test of painted rooms: ChatGPT paints one whole room over a blockout, the game adds the darkness and the light. If it works, the other sewer rooms (cisterns, maintenance rooms, chambers) are made the same way, and only tunnels stay as tiles.

- **The room:** the Outflow, where the Sewers drain into the mines, and where Garrick, the First Shift, is fought. Design: `design/quick-specs/first-shift-boss-2026-10-29.md`. Story and look: `docs/story.md`, `docs/characters.md`.
- **Look to aim for:** `assets/reference/saltmarrow-deep/biomes/rotwater-sewers.png` and the angled top-down panel of `assets/docs/references/camera-perspective-concept.png`.
- **Blockout to paint over:** `outflow-blockout.png` in this folder (`outflow-blockout-2x.png` is the same, doubled, for viewing).

## The blockout

448 × 352 pixels: 14 squares across, 11 down, each square 32 × 32. One flat colour per kind of square.

| Colour | What the square is | Paint it as |
|---|---|---|
| Light grey | Floor | Walkable wet stone floor |
| Blue | The water channel (row 6 from the top) | Shallow water you can wade through, with a stone edge |
| Mid grey | The north wall's face | A brick wall seen from slightly above: its top edge, then its face |
| Dark grey | Wall tops (west, east and south walls) | The top of thick walls seen from above; no faces showing |
| Red | A sluice gate (two, in the north wall) | The stone frame and dark mouth of a sluice. The game draws the gate itself on top, open or shut |
| Green | The entrance (two squares in the west wall) | Open floor running out through an archway; the tunnel joins here |
| Yellow mark | A lantern fixture on the wall (three) | An iron wall lantern, centred in that square |

## Deliver

Under `assets/tiles/sewers/outflow/` (this is ART_JOBS.md job 12):

1. **`outflow_room.png`**: the painted room. **Exactly 448 × 352**, transparent PNG.
2. The pieces job 12 already lists: the sluice gate open (4 frames) and shut, the gate shutting (4 frames), a floor square flooding (4 frames), and the brass tally tag on the floor plus its 32 × 32 icon.
3. A `README.md` as usual, plus the pixel position of each lantern's glass, so the game can put real light exactly there.

## Rules

1. **Every square keeps its kind.** Floor squares look like floor you can walk on: nothing standing on them that looks like an obstacle. Wall squares look solid. Water only in the blue row. Props (pipes, grates, chains, crates, a valve wheel) go on wall squares or tight against the wall, inside the wall squares.
2. **Camera:** slightly angled top-down, as in the concept board's highlighted panel. Only the north wall shows its face; the other walls show their tops.
3. **Light: neutral and even.** Paint it as if lit by a soft, plain grey light from above, with no lantern glow, no strong shadows and no fade to darkness. The game adds the darkness, the amber lantern pools, the flicker and the light on the water. Baked light is what makes painted pieces clash with the game's light. The lantern glass itself may be lightly amber.
4. **Colours:** cold slate, charcoal and wet brown stone; dark teal water; rust and brass on metal; amber only in the lantern glass. About 32 colours at most. Star touch, sparingly: salt crystals along the waterline, a faint pearly sheen.
5. **Pixel art:** hard pixel edges, no smoothing or anti-aliasing, no text, and no grid lines (the blockout's grid lines are guides only).
6. **Quiet floor:** at least half the floor plain, so characters, blood and the fight markers read clearly. Put the detail in the walls: pipes along the north face between the gates, drain grates, moss and damp low on the bricks, salt crust at the channel edge.
7. **Leave out:** characters, Garrick, blood, the tag, and the gates themselves (only their frames).

## How it will be checked

- Claude lays the blockout grid over the painting and checks every square still reads as its kind, and that the size is exact.
- Claude puts it in the game, with darkness, lantern light and Garrick, and screenshots it next to the concept art.
- Julian approves the look.
