# Working on this repository

Two AI assistants work here, with separate jobs:

- **Claude** owns the code: everything in `scripts/`, `scenes/`, `tests/`, `project.godot` and the workflows.
- **ChatGPT** owns the art: everything in `assets/`.

Please keep to your own folders, so changes don't collide. If art needs a code change to show up, describe it in the pull request and Claude will wire it in.

## What to draw

**`ART_JOBS.md` is the to-do list.** Work through it from the top, and tick off each job in the pull request that delivers it. Claude adds new jobs as the design grows.

The story is in `docs/story.md` and the cast in `docs/characters.md`.

## Delivering art

- Put files under `assets/<group>/`, for example `assets/characters/thomas/`, `assets/tiles/salt_pits/`.
- PNG with transparency. Pixel art with hard edges; no smoothing or anti-aliasing.
- Sizes, facing and sheet layout are in the table at the top of `ART_JOBS.md`.
- Add a short `README.md` in each folder: what each file is, its frame size, frame counts per row, and the facing directions.
- Open a pull request; don't push to `main` directly.

## Rules of the game that affect art

- Fantasy setting after a long war: swords, staves, lanterns. **No guns.**
- Palette: cold slate blues, charcoal and wet browns, with small warm amber lights.
- Anything touched by the star shows the same signs: a pearly sheen in the eyes, a faint inner light under the skin, salt crystals at the edges.
