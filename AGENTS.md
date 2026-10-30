# Working on this repository

Two AI assistants work here, with separate jobs:

- **Claude** owns the code: everything in `scripts/`, `scenes/`, `tests/`, `tools/`, `project.godot` and the workflows (`.github/`). Claude also owns the studio setup: `.claude/`, `design/`, `docs/`, `production/`, `project.yaml`, and the lists `ART_JOBS.md`, `CLAUDE.md` and this file.
- **ChatGPT** owns the art: everything in `assets/`.

Please keep to your own folders, so changes don't collide. The one exception: tick a job's box in `ART_JOBS.md` in the pull request that delivers it. If art needs a code change to show up, describe it in the pull request and Claude will wire it in.

**Don't move or rename art the game already uses.** The game loads some files by their exact path (for now, Thomas's `standing-candidate.png` and `steady-portrait-candidate.png` in `assets/characters/thomas/production/sprites/`). Put new versions beside them and say so in the pull request; Claude will switch the game over.

The game runs on **Godot 4.7**.

## What to draw

**`ART_JOBS.md` is the to-do list.** Work through it from the top, and tick off each job in the pull request that delivers it. Claude adds new jobs as the design grows.

The story is in `docs/story.md` and the cast in `docs/characters.md`.

## Delivering art

- Put files under `assets/<group>/`, for example `assets/characters/thomas/`, `assets/tiles/salt_pits/`.
- PNG with transparency. Pixel art with hard edges; no smoothing or anti-aliasing.
- Sizes, facing and sheet layout are in the table at the top of `ART_JOBS.md`.
- **Everything that stands in a room follows the house style** in `ART_JOBS.md` ("House style: everything drawn over the rooms"): no black outline, the rooms' palette and grain, readable values, grounded feet, neutral light, a `_n.png` normal map with every sheet, **everything drawn from the rooms' raised, slightly angled top-down camera** (never eye level: top of the head and shoulders visible, feet planted on the floor plane), and characters about 1.5 squares tall on 80 × 80 frames from job 15 on. It applies to every job, including ones that don't repeat it, so that all the art stays consistent.
- Add a short `README.md` in each folder: what each file is, its frame size, frame counts per row, and the facing directions.
- Open a pull request; don't push to `main` directly.

## Rules of the game that affect art

- Fantasy setting after a long war: swords, staves, lanterns. **No guns.**
- Palette: cold slate blues, charcoal and wet browns, with small warm amber lights.
- Anything touched by the star shows the same signs: a pearly sheen in the eyes, a faint inner light under the skin, salt crystals at the edges.
