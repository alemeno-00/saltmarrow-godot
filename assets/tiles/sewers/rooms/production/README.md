# Room kit generation and export

Painted with the built-in image-generation tool. The blockout is always the geometry reference. Sources are NOT runtime pixel sheets; native exports in each layout folder are the delivered backgrounds.

`*-prompt.txt` files contain the prompt specifications; the final crossing and tunnel prompts are retained separately. Per-call refinements emphasized dry grey doorways, top-only side/south walls, compact props and exact offset ports. Initial crossing studies borrowed the Outflow material reference and incorrectly added water; they are retained as rejected studies. Subsequent source calls use the individual blockout as their image reference.

## Mechanical export

`export.py` reads `layouts.json` and `registration.json`, crops/nearest-registers the generated paintings, uses three existing masonry crops for flat wall tops and three existing floor crops for dry doorway pads, and joins active edges with recorded four-pixel profiles. It quantizes a shared palette and restricts dry floor squares to its neutral subset, removing coloured blockout residue without painting new textures. Amber reserves are used only for bright glass pixels in fixture cells. North and south/east profiles are mirrored appropriately at joins. Omitted zero-height registration segments remove surplus plain transition bands, not gameplay cells.

`validate.py` checks exported sizes, alpha, colours, water placement, walkable opacity and port profiles, then writes review artifacts. It does not run Godot or certify collision and appearance. Both scripts require Python and Pillow. Run export.py followed by validate.py.

## File inventory

| File | Role |
| --- | --- |
| `.gdignore` | Exclude production references from Godot import |
| `chamber_a-master.png` | One static source image, 1536×1024; generated master |
| `chamber_a-prompt.txt` | Generation prompt specification |
| `chamber_b-master.png` | One static source image, 1536×1024; generated master |
| `chamber_b-prompt.txt` | Generation prompt specification |
| `chamber_c-master.png` | One static source image, 1024×1536; generated master |
| `chamber_c-prompt.txt` | Generation prompt specification |
| `connector_es-master.png` | One static source image, 1254×1254; generated master |
| `connector_es-prompt.txt` | Generation prompt specification |
| `connector_ew-master.png` | One static source image, 1254×1254; generated master |
| `connector_ew-prompt.txt` | Generation prompt specification |
| `connector_ne-master.png` | One static source image, 1254×1254; generated master |
| `connector_ne-prompt.txt` | Generation prompt specification |
| `connector_ns-master.png` | One static source image, 1254×1254; generated master |
| `connector_ns-prompt.txt` | Generation prompt specification |
| `connector_nw-master.png` | One static source image, 1254×1254; generated master |
| `connector_nw-prompt.txt` | Generation prompt specification |
| `connector_sw-master.png` | One static source image, 1254×1254; generated master |
| `connector_sw-prompt.txt` | Generation prompt specification |
| `entry-master.png` | One static source image, 1254×1254; generated master |
| `entry-prompt.txt` | Generation prompt specification |
| `export.py` | Mechanical export or validation script |
| `flooded_a-master.png` | One static source image, 1254×1254; generated master |
| `flooded_a-prompt.txt` | Generation prompt specification |
| `flooded_b-master.png` | One static source image, 1254×1254; generated master |
| `flooded_b-prompt.txt` | Generation prompt specification |
| `junction_a-final-master.png` | One static source image, 1254×1254; generated master |
| `junction_a-final-prompt.txt` | Generation prompt specification |
| `junction_a-first-master.png` | One static source image, 1254×1254; rejected crossing study |
| `junction_a-master.png` | One static source image, 1254×1254; rejected crossing study |
| `junction_a-prompt.txt` | Generation prompt specification |
| `junction_a-revision-prompt.txt` | Generation prompt specification |
| `junction_b-master.png` | One static source image, 1254×1254; generated master |
| `junction_b-prompt.txt` | Generation prompt specification |
| `junction_c-master.png` | One static source image, 1254×1254; generated master |
| `junction_c-prompt.txt` | Generation prompt specification |
| `layouts.json` | Layout, palette or source-registration data |
| `lore_a-master.png` | One static source image, 1254×1254; generated master |
| `lore_a-prompt.txt` | Generation prompt specification |
| `lore_b-master.png` | One static source image, 1254×1254; generated master |
| `lore_b-prompt.txt` | Generation prompt specification |
| `palette.json` | Layout, palette or source-registration data |
| `registration.json` | Layout, palette or source-registration data |
| `stairs-master.png` | One static source image, 1254×1254; generated master |
| `stairs-prompt.txt` | Generation prompt specification |
| `validate.py` | Mechanical export or validation script |
