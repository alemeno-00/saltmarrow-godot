# Outflow production sources

All masters were painted with the built-in image-generation tool. Exact prompts and reference roles are in `PROMPTS.md`. Masters are source artwork, not runtime sprites; native exports in the parent folder meet pixel size and palette requirements.

| File | Contents | Layout |
| --- | --- | --- |
| `room-first-master.png` | Initial room; rejected for shortened entrance and regular floor grid | One static image, 1415×1112 |
| `room-master.png` | Revised quiet floor and two-square entrance | One static image, 1415×1112 |
| `gates-master.png` | Four open, four shutting, one closed source components | Three source rows, 4/4/1; not runtime frame dimensions |
| `flood-master.png` | Progressive floor-to-water source components | One source row, four squares |
| `tag-master.png` | Floor and inventory views | One source row, two objects |
| `PROMPTS.md` | Full prompt set and references | Text |
| `blockout-grid.json` | Sampled supplied blockout and coordinate constraints | Data |
| `gate-source-crops.json` | Component bounds for gate source | Data |
| `flood-source-crops.json` | Component bounds for flood source | Data |
| `tag-source-crops.json` | Component bounds for tag source | Data |
| `export.py` | Alpha component extraction, mechanical grid registration, nearest export, palette normalization | Python + Pillow |
| `validate.py` | Dimensions, alpha, colours, channel, entrance, frame identity checks; review assemblies | Python + Pillow |
| `.gdignore` | Exclude sources from Godot import | Marker |

Run export.py, then validate.py with Python/Pillow. Complete master dimensions are also recorded below automatically. The exporter moves the generated room's observed boundary bands onto exact blockout lines. It narrows sluice-frame bands to their specified cells and trims four source pixels at the outer entrance edge to remove a transparent edge pixel. All registration knots are in manifest.json. Lantern palette accents are preserved only in the three original glass regions, keeping ambient floor/water neutral.

Source masters are not sheets for the game; generated component separation is removed for the gapless runtime PNGs. The third-row standalone shut study is retained for provenance; runtime shut is the exact last closing frame.

Actual source canvases (one static reference image each):

- `flood-master.png`: 2172×724.
- `gates-master.png`: 1448×1086.
- `room-first-master.png`: 1415×1112.
- `room-master.png`: 1415×1112.
- `tag-master.png`: 1774×887.
