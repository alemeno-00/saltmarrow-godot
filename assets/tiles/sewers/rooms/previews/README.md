# Room kit review images

These are reference artifacts excluded from Godot by `.gdignore`; no review grids appear in game PNGs. Every PNG is one static frame/one row.

Contact-sheet order:

- `rooms-contact.png`: 1152×1536, rows junction A/B/C; chambers A/B/C; flooded A/B/entry; stairs/lore A/lore B. Individual paintings are shown at native size, centred in 384px cells.
- `tunnels-contact-2x.png`: 768×512, rows EW/NS/NE and NW/ES/SW; nearest 2×.
- `turn-assembly.png`: 1152×768, crossing → W/S bend → N/S tunnel → N/E bend → gallery, actual exported images. Art review only, not a generated-level or gameplay test.
- `sealed-room-2x.png`: 768×768, all four seals over a crossing’s unused doors.

Per-layout `*-2x.png` are nearest 2× paintings; `*-grid.png` add a QA grid and small green light-centre markers. All are static, one frame/one row.

| File | Canvas |
| --- | --- |
| `chamber_a-2x.png` | 768×512 |
| `chamber_a-grid.png` | 768×512 |
| `chamber_b-2x.png` | 768×512 |
| `chamber_b-grid.png` | 768×512 |
| `chamber_c-2x.png` | 512×768 |
| `chamber_c-grid.png` | 512×768 |
| `connector_es-2x.png` | 256×256 |
| `connector_es-grid.png` | 256×256 |
| `connector_ew-2x.png` | 256×256 |
| `connector_ew-grid.png` | 256×256 |
| `connector_ne-2x.png` | 256×256 |
| `connector_ne-grid.png` | 256×256 |
| `connector_ns-2x.png` | 256×256 |
| `connector_ns-grid.png` | 256×256 |
| `connector_nw-2x.png` | 256×256 |
| `connector_nw-grid.png` | 256×256 |
| `connector_sw-2x.png` | 256×256 |
| `connector_sw-grid.png` | 256×256 |
| `entry-2x.png` | 512×512 |
| `entry-grid.png` | 512×512 |
| `flooded_a-2x.png` | 768×768 |
| `flooded_a-grid.png` | 768×768 |
| `flooded_b-2x.png` | 768×768 |
| `flooded_b-grid.png` | 768×768 |
| `junction_a-2x.png` | 768×768 |
| `junction_a-grid.png` | 768×768 |
| `junction_b-2x.png` | 768×768 |
| `junction_b-grid.png` | 768×768 |
| `junction_c-2x.png` | 768×768 |
| `junction_c-grid.png` | 768×768 |
| `lore_a-2x.png` | 512×512 |
| `lore_a-grid.png` | 512×512 |
| `lore_b-2x.png` | 512×512 |
| `lore_b-grid.png` | 512×512 |
| `rooms-contact.png` | 1152×1536 |
| `sealed-room-2x.png` | 768×768 |
| `stairs-2x.png` | 512×512 |
| `stairs-grid.png` | 512×512 |
| `tunnels-contact-2x.png` | 768×512 |
| `turn-assembly.png` | 1152×768 |

- `rooms-contact-order.json`: contact-sheet ordering.
- `.gdignore`: exclude reviews from import.
