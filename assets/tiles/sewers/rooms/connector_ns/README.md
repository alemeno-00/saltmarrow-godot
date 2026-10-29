# connector_ns — first painting

`1.png`: **128×128** pixels, one static frame, one row. 32px map squares. Origin (0,0) at room upper-left. This is a complete background; no animation rows. PNG RGBA, hard edges, binary alpha and at most 32 opaque RGB colours.

Blockout: `scripts/levels/sewers/layouts/connector_ns.png`. Each square retains its function. All marked doorways are painted open; use the separate seals on unused room doors.

Left-to-right mirroring: **no**. Never flip top-to-bottom. Keep the authored orientation and offset doors.

## Light glass centres

No light fixtures in this tunnel.

## Open doorway rectangles

Each rectangle is x, y, width, height in room-local pixels.

- `n`: (32, 0, 64, 32).
- `s`: (32, 96, 64, 32).

Place the full image at the blockout origin with nearest sampling in Godot 4.7. Gameplay collision stays in Claude’s blockout data; do not derive it from art alpha. See the parent README for palette, shared join profiles, provenance and review limits.
