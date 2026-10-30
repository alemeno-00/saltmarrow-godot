> Historical job14 floor-body redraw. The pose is retained, but job15a subsequently applies the shared palette and normal maps in `../house-style/`. The 16 unchanged files mentioned below refer to that earlier body-only revision.

# Floor-body redraw

Built-in image generation, no CLI fallback. The first side-view bodies looked pasted onto the floor. The replacement uses the approved junction camera and materials: face down, cap crown and shoulder tops visible, broader prone footprint, broken material-coloured edges, selected contact-dark clusters. Head right, boots left; no floor patch or directional cast shadow.

## Selected art and prompts

All masters are transparent 1774×887, one image / one frame each. These are generation canvases, not game-frame dimensions.

| File | Role / layout |
| --- | --- |
| `closed-master.png` | New prone pose, closed satchel; one frame |
| `fresh-closed-prompt.txt` | Full generation prompt; approved `assets/tiles/sewers/rooms/junction_a/1.png` was the camera/material reference |
| `open-master.png` | Same pose, opened empty satchel; one frame |
| `open-prompt.txt` | Full edit prompt; `closed-master.png` was the edit target |
| `tag-master.png` | Same pose, closed satchel, visible brass tally on loose neck cord; one frame |
| `tag-prompt.txt` | Full edit prompt; `closed-master.png` was the edit target |
| `before-satchel.png` | Previous runtime sheet, 128×32, one row / two 64×32 frames |
| `before-tag.png` | Previous runtime sprite, 64×32, one row / one frame |
| `before-room-2x.png` | Previous placement assembly, 768×768, one static frame |
| `before-hashes.json` | Original SHA256 values of all 18 runtime PNGs |
| `revision-checks.json` | Confirms only the two body runtime PNGs changed, with 16 preserved |
| `.gdignore` | Excludes source/review files from Godot imports |
| `README.md` | This inventory |

`../export.py` crops each selected master's binary alpha and applies a shared uniform nearest scale across the two satchel states, then centres each in its 64×32 frame. The tally uses the same 56×24 maximum footprint. Each runtime sheet is quantized to at most 32 colours without dithering; exterior alpha is binary and hidden RGB cleared. Full crop/scale records are in `../../manifest.json`. No sprite painting is done by the exporter.

Runtime outputs: `../../satchel_body.png` (128×32; one row, closed then searched), `../../miner_tag_body.png` (64×32; static). Compare `../../previews/body-before-after-closeup.png`: before left, revised right, satchel top and tally bottom. The preview uses the same actual approved room and positions, with nearest enlargement only; it is not an engine-lighting test.
