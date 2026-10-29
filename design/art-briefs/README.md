# Painted rooms: the blockout standard

How every painted room is briefed, painted and checked. It grew out of the Outflow test (`outflow/`, art job 12, approved by Julian on 2026-10-29). Room types, sizes and the door standard are in `design/quick-specs/sewer-room-kit-2026-10-29.md`.

**The method.** Claude draws a **blockout**: the room at game scale, one flat colour per 32 × 32 square. The game reads the blockout as the room's layout. ChatGPT paints over the same image. Because the rules and the painting come from one file, they can't drift apart.

## What the Outflow taught us

The Outflow lined up exactly and lit well, but it came out plainer than the concept art (`assets/reference/saltmarrow-deep/biomes/rotwater-sewers.png`). The blockout caused that, not the painting:

- **Walls were one square tall**, so the room felt shallow. The concept art's walls are two or more squares tall.
- **The room was a plain rectangle**, with no walkways, railings, alcoves or machinery.
- **All the light was on the north wall**, so the far half of the room went black.
- **The flooded square repeats** as a visible grid. Anything the game repeats needs variants.

The rules below fix those.

## The colours

| Colour | Hex | What the square is | In the game | Paint it as |
|---|---|---|---|---|
| Dark grey | `#3a3a42` | Wall top | Blocks movement and sight | The top of a thick wall, seen from above |
| Mid grey | `#6a6a76` | Wall face | Blocks movement and sight | A wall's face, seen from slightly above |
| Light grey | `#b8b2a4` | Floor | Walkable | Wet stone floor, mostly quiet |
| Pale stone | `#d8d0bc` | Raised walkway | Walkable (looks raised; same rules as floor for now) | A raised stone walk with a visible edge where it meets lower floor or water |
| Blue | `#2f7f9a` | Shallow water | Walkable, costs 2 movement | Water with a stone edge |
| Brown | `#7a4f2a` | Blocking prop | Blocks movement and sight | Machinery, a pillar, a pump, stacked crates: something solid and tall |
| Violet | `#8e5aa8` | Railing | Blocks movement, **not** sight | A low railing or chain line along an edge |
| Green | `#3fae5a` | Door / entrance | Walkable; where a connector joins | Open floor through an arch |
| Red | `#c0392b` | Sluice or special fixture | Blocks movement (e.g. the entry's ladder up to town) | A fixture; for sluices, the frame only, as the game draws the moving part |
| Dark violet | `#4b3f6b` | Stairs down | Walkable; leads to the next depth | Stone steps going down into the dark |
| Yellow mark | `#f1c40f` | Light on a wall | (on a wall-face square) | An iron wall lantern |
| Orange mark | `#e67e22` | Standing light | (on a prop square) | A brazier or lantern post |

Brown and violet are the game's *prop* and *rail* tiles. The room kit's blockouts are drawn by `tools/blockouts/sewer_layouts.gd` into `scripts/levels/sewers/layouts/`; to change a room, edit its text there and run the tool again.

## Rules for every blockout (Claude)

1. **North walls are two squares thick**, both squares mid grey, so their faces paint two squares tall. West, east and south walls are one square of wall top.
2. **Light reaches the whole room:** a wall lantern or standing light within about 6 squares of every floor square. Standing lights go on prop squares, so they're never in the way.
3. **Give every room a shape.** Junctions and chambers get at least one of: a raised walkway, a railing line, an alcove, a blocking prop (machinery, pillars). Plain rectangles are for connectors only.
4. **Doors follow the door standard:** 2 squares wide, centred on their side, green.
5. Doors and their landing squares stay clear: the 2 squares straight in front of each door are walkable (no props or railings).

## Rules for every painting (ChatGPT)

1. **Exact size.** The painting is the blockout's size; every square keeps its kind. Floor looks walkable, walls and props look solid, railings look low.
2. **Neutral, even light.** Paint as if lit by soft grey light from above: no lantern glow, no strong shadows, no fade to dark. Lantern and brazier glass may be lightly amber. The game adds the darkness, the light pools and the flicker.
3. **Colours** come from the concept art: cold slate, charcoal and wet brown stone, dark teal water, rust and brass on metal, amber only in glass. At most 32 colours. Star touch, sparingly: salt crystals along waterlines, a faint pearly sheen.
4. **Quiet floor:** at least half the floor plain. The detail goes in walls, props and edges.
5. **Pixel art:** hard edges, no smoothing, no text, no grid lines.
6. **Leave out:** characters, blood, items, and anything the game animates (gates, flooding).
7. **The README lists the pixel centre of every light's glass**, so the game can put real light there, and says whether the painting can be mirrored left to right (no text, nothing that only works one way round).
8. **Variants of a layout** keep every square's kind and change the rest: materials, wear, moss, salt, which machinery stands on the prop squares, small floor details.
9. **Anything the game repeats** (flooded squares, floor patches) comes in **at least 3 variants**.

## Checks before approval

- Claude: the exact size; every square reads as its kind (blockout grid laid over the painting); then in the game with darkness and lights, next to the concept art.
- Julian approves the look.

## Delivery

Paintings go in `assets/tiles/<biome>/rooms/<layout>/<variant>.png`, with a README per folder (as `AGENTS.md` asks). Boss rooms go in their own folder, like `assets/tiles/sewers/outflow/`.
