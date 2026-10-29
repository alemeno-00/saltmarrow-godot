# Paint-over brief: the Sewers room kit

Paint the Sewers' rooms and tunnels over their blockouts, the same way as the Outflow (approved). Read first:

- **The blockout standard:** `design/art-briefs/README.md` (colours, rules for every painting, delivery). Everything there applies.
- **The approved example:** `assets/tiles/sewers/outflow/` and its README.
- **The look to aim for:** `assets/reference/saltmarrow-deep/biomes/rotwater-sewers.png` and the angled top-down panel of `assets/docs/references/camera-perspective-concept.png`.
- **The rooms' design:** `design/quick-specs/sewer-room-kit-2026-10-29.md`.

The blockouts are in `scripts/levels/sewers/layouts/` (`<layout>.png`). The game reads these same images as the rooms' layouts, so a painting must match its blockout square for square.

## Doorways: paint them open, and deliver sealed pieces

Every room has a doorway in the middle of each side (green, 2 squares wide). In a level, a room usually uses only some of them, and the game seals the rest. So:

1. **Paint every doorway open:** floor running out through an arch to the room's edge.
2. **Deliver four sealed-doorway pieces** in `assets/tiles/sewers/rooms/sealed/`, which the game lays over unused doorways:
   - `north.png`, 64 × 64 (2 squares wide, 2 tall): the two-square brick face of the north wall, continuing the wall around it.
   - `south.png` 64 × 32, `west.png` 32 × 64, `east.png` 32 × 64: wall top.

   They must blend with any room's walls, so keep them plain.

## What to paint (first batch: one painting per layout)

Paint one of each first. Once Julian approves the batch, more variants follow (the counts are in the spec).

| Layout | Size (squares) | What it is | Notes |
|---|---|---|---|
| `junction_a` | 12 × 12 | A vaulted crossing held up by four stone pillars | Two pillars carry braziers |
| `junction_b` | 12 × 12 | A square settling tank: a raised stone walk around a pool | The pale squares are the raised walk; show its edge stepping down to the floor and the water |
| `junction_c` | 12 × 12 | A pump room: iron pump housings in the north corners, a railed drain pit in the middle | Rust, brass valves, pipes into the north wall; the railing is low iron |
| `chamber_a` | 12 × 8 | A long gallery with two pillars | |
| `chamber_b` | 12 × 8 | A channel room: water to both sides of a dry stone causeway | |
| `chamber_c` | 8 × 12 | A tall overflow chamber, one pillar and a brazier | Not mirrorable (8 wide) |
| `flooded_a` | 12 × 12 | A cistern flooded wall to wall, a raised walk around it, two lit pillars standing in the water | |
| `flooded_b` | 12 × 12 | A round cistern basin: the water's edge steps in like a circle | Make the curve read as round brickwork, not square steps |
| `entry` | 8 × 8 | Where Thomas climbs down from town: an iron ladder in a shaft in the north wall (red squares) | The driest, plainest room. Not mirrorable |
| `stairs` | 8 × 8 | Stone steps going down into the dark (the dark violet square) | Salt crust thickening near the steps. Not mirrorable |
| `lore_a` | 8 × 8 | A hidden shrine: a niche in the north wall (red squares) where the Faithful leave offerings before a pearl-white star scratched over an old saint | Two braziers. Not mirrorable |
| `lore_b` | 8 × 8 | A sewer warden's store: shelves of ledgers swollen with damp, tally boards | The brown squares are the shelves. Not mirrorable |
| `connector_ew`, `connector_ns` | 4 × 4 | A straight tunnel, east-west and north-south | Walls here are one square thick, so the north face is one square tall: the one exception to the two-square rule |
| `connector_ne`, `connector_nw`, `connector_es`, `connector_sw` | 4 × 4 | A tunnel bending through 90° | Draw the bend as curved brickwork inside the square footprint |

That's 12 rooms and 6 tunnel pieces. The T, crossing and dead-end shapes can wait.

## Delivery

- One painting per file: `assets/tiles/sewers/rooms/<layout>/1.png`, exactly the blockout's size (32 pixels per square), with a README per folder as the standard asks. List the pixel centre of every light's glass.
- **Mirroring:** the 12-wide rooms may be shown mirrored left to right, so nothing in them should only work one way round (no text, no direction-specific details). The 8-wide rooms are never mirrored.
- **Tunnels must join seamlessly:** any tunnel piece can sit next to any other piece's doorway. Keep tunnel floors and wall tops plain and consistent at the edges.

## How it will be checked

- Claude checks every painting's size and that every square reads as its kind, then lays them into generated levels with the game's lighting, next to the concept art.
- Julian approves the batch.
