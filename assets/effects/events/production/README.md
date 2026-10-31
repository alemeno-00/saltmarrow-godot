# Job14b production archive

The built-in image-generation tool painted the four sources. Runtime outputs are in the parent folder; no fallback API/CLI was used.

- `watcher-source.png`, `watcher-prompt.txt`: complete whole-figure source and exact painting prompt, source1216×1294. One south figure.
- `frost-source-v1.png`, `frost-prompt-v1.txt`:1536×1024 source sheet,3×2 square cells, six frost patches and exact prompt. Runtime density order is determined after registration.
- `watcher-registration-8x.png`: actual exported80×80 watcher enlarged8×,640×640, supplied as the geometry target for its normal map.
- `frost-registration-8x.png`: actual exported frost cells repacked3×2,96×64 logical pixels enlarged8× to768×512, supplied as the normal-map geometry target. Runtime sheet stays one row.
- `watcher-normal-source.png`, `watcher-normal-prompt.txt`: generated whole-figure normal-colour source and exact edit prompt.
- `frost-normal-source.png`, `frost-normal-prompt.txt`: generated3×2 normal-colour patch source and exact edit prompt.
- `export_events.py`: threshold/binary alpha, nearest-neighbour size registration, fixed material palettes and exact diffuse/normal alpha matching. Source watcher is uniformly registered to58px height, feet-root(40,72). Generated eye components project to one pixel each so both survive undersampling. Detached alpha specks are removed. Frost source squares register inside30×30 interiors plus1px transparent margins; isolated one-pixel alpha specks are removed and frames sort by opaque count. Normal colours are registered, extended only where required by diffuse alpha and normalized. It does not invent poses or paint replacement features.
- `registration.json`: source bounds, fixed placement, eye coordinates, frost source-to-frame mapping, counts, palette and Julian's exact approval of pearl-blue accents.
- `export_previews.py`: nearest-neighbour layouts, actual room/cast composites and mechanical fade preview. Does not alter runtime paintings.
- `validate_events.py`: repeatable layout, palette, height/eye/sole, binary alpha, exact normal alpha, unit-normal, increasing density, wrap-boundary and protected-reference checks.
- `validation.json`: results and checksums. Actual engine lighting/wiring is pending.
- `previews/`: review media, with its own file manifest.
- `.gdignore`: excludes source images and review material from runtime imports.

Runtime images: `../watcher.png` and `_n`, one80×80 south frame; `../star_frost.png` and `_n`, one row of six32×32 frames.
