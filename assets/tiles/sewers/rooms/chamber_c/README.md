# chamber_c — first painting

`1.png`: **256×384** pixels, one static frame, one row. 32px map squares. Origin (0,0) at room upper-left. This is a complete background; no animation rows. PNG RGBA, hard edges, binary alpha and at most 32 opaque RGB colours.

Blockout: `scripts/levels/sewers/layouts/chamber_c.png`. Each square retains its function. All marked doorways are painted open; use the separate seals on unused room doors.

Left-to-right mirroring: **no**. Never flip top-to-bottom. Keep the authored orientation and offset doors.

## Light glass centres

Room-local pixels, x right/y down; these are the actual painted glass positions. Add real lights in the game.

| Kind | Glass centre (x,y) | Blockout cell (zero-based) |
| --- | --- | --- |
| wall | (47, 21) | (1, 0) |
| standing | (176, 272) | (5, 8) |

## Open doorway rectangles

Each rectangle is x, y, width, height in room-local pixels.

- `n`: (160, 0, 64, 64).
- `s`: (160, 352, 64, 32).
- `w`: (0, 160, 32, 64).
- `e`: (224, 160, 32, 64).

Place the full image at the blockout origin with nearest sampling in Godot 4.7. Gameplay collision stays in Claude’s blockout data; do not derive it from art alpha. See the parent README for palette, shared join profiles, provenance and review limits.
