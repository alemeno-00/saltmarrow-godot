# junction_a — first painting

`1.png`: **384×384** pixels, one static frame, one row. 32px map squares. Origin (0,0) at room upper-left. This is a complete background; no animation rows. PNG RGBA, hard edges, binary alpha and at most 32 opaque RGB colours.

Blockout: `scripts/levels/sewers/layouts/junction_a.png`. Each square retains its function. All marked doorways are painted open; use the separate seals on unused room doors.

Left-to-right mirroring: **yes**. Never flip top-to-bottom. Mirror light x coordinates as width−1−x. No text or direction-specific marks.

## Light glass centres

Room-local pixels, x right/y down; these are the actual painted glass positions. Add real lights in the game.

| Kind | Glass centre (x,y) | Blockout cell (zero-based) |
| --- | --- | --- |
| wall | (49, 25) | (1, 0) |
| wall | (334, 26) | (10, 0) |
| standing | (111, 267) | (3, 8) |
| standing | (270, 267) | (8, 8) |

## Open doorway rectangles

Each rectangle is x, y, width, height in room-local pixels.

- `n`: (160, 0, 64, 64).
- `s`: (160, 352, 64, 32).
- `w`: (0, 160, 32, 64).
- `e`: (352, 160, 32, 64).

Place the full image at the blockout origin with nearest sampling in Godot 4.7. Gameplay collision stays in Claude’s blockout data; do not derive it from art alpha. See the parent README for palette, shared join profiles, provenance and review limits.
