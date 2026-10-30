# Sewer contents production

All 18 requested assets were generated with the built-in image-generation tool, one asset per call. Multi-frame source images contain only that asset’s states. The full prompt specification for each is saved as `<name>-prompt.txt`. The original miner tally body referenced `satchel_body-master.png`. Both original body masters are retained for history but are superseded by the overhead redraw in `body-v2/`; those three single-image sources now supply runtime body frames. No CLI image-generation fallback was used.

`grate-format.json` preserves Julian’s explicit clarification: four total per sheet, two shut and two open. Grate source images use a 2×2 grid and export to two animation rows of two frames. Other multi-frame masters use one row.

`export.py` crops binary-alpha silhouettes, fits complete art to native cells with nearest sampling, uses shared scale for each pair/animation, registers baselines or centres, quantizes each sheet to 32 colours and clears hidden transparent RGB. Grates use a per-axis fit of their flat source plane to fixed bounds; they are not scaled independently by the game. This is mechanical export, not procedural sprite drawing.

`validate.py` checks all runtime files and makes review sheets/GIFs and a placement assembly. Run export.py then validate.py with Python and Pillow. It does not run Godot or test gameplay.

`body-v2/README.md` lists the selected redraw masters, full prompts and before/after records. The redraw starts from the approved room camera and materials; searched-satchel and tally-tag variants edit that same prone pose.

## Inventory

| File | Role |
| --- | --- |
| `.gdignore` | Godot source-folder exclusion marker |
| `bandage-master.png` | Generated master, 1254×1254; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `bandage-prompt.txt` | Generation prompt specification |
| `barrel-master.png` | Generated master, 1774×887; one source row, 2 component(s). Source canvas is not a runtime frame. |
| `barrel-prompt.txt` | Generation prompt specification |
| `bones_1-master.png` | Generated master, 1572×1001; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `bones_1-prompt.txt` | Generation prompt specification |
| `bones_2-master.png` | Generated master, 1322×1190; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `bones_2-prompt.txt` | Generation prompt specification |
| `bones_3-master.png` | Generated master, 1385×1136; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `bones_3-prompt.txt` | Generation prompt specification |
| `crate-master.png` | Generated master, 1774×887; one source row, 2 component(s). Source canvas is not a runtime frame. |
| `crate-prompt.txt` | Generation prompt specification |
| `debris_1-master.png` | Generated master, 1568×1003; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `debris_1-prompt.txt` | Generation prompt specification |
| `debris_2-master.png` | Generated master, 1402×1122; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `debris_2-prompt.txt` | Generation prompt specification |
| `debris_3-master.png` | Generated master, 1470×1070; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `debris_3-prompt.txt` | Generation prompt specification |
| `export.py` | Mechanical export or validation script |
| `grate-format.json` | Confirmed four-frame, two-row grate format |
| `grate_ew-master.png` | Generated master, 887×1774; 2×2 source grid. Source canvas is not a runtime frame. |
| `grate_ew-prompt.txt` | Generation prompt specification |
| `grate_key-master.png` | Generated master, 1536×1024; 2×2 source grid. Source canvas is not a runtime frame. |
| `grate_key-prompt.txt` | Generation prompt specification |
| `grate_ns-master.png` | Generated master, 1774×887; 2×2 source grid. Source canvas is not a runtime frame. |
| `grate_ns-prompt.txt` | Generation prompt specification |
| `hymn_sheet-master.png` | Generated master, 1312×1199; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `hymn_sheet-prompt.txt` | Generation prompt specification |
| `letter-master.png` | Generated master, 1774×887; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `letter-prompt.txt` | Generation prompt specification |
| `miner_tag_body-master.png` | Generated master, 1774×887; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `miner_tag_body-prompt.txt` | Generation prompt specification |
| `requests.json` | Original 16 non-grate requests; grate prompts are separate after clarification |
| `salve-master.png` | Generated master, 1254×1254; one source row, 1 component(s). Source canvas is not a runtime frame. |
| `salve-prompt.txt` | Generation prompt specification |
| `satchel_body-master.png` | Generated master, 2172×724; one source row, 2 component(s). Source canvas is not a runtime frame. |
| `satchel_body-prompt.txt` | Generation prompt specification |
| `validate.py` | Mechanical export or validation script |
| `valve-master.png` | Generated master, 2172×724; one source row, 4 component(s). Source canvas is not a runtime frame. |
| `valve-prompt.txt` | Generation prompt specification |
