# Collaboration-guide conflicts for review

Authority: repository `AGENTS.md` and identical `CLAUDE.md`, checked at base commit `3f97eca413b73c942220b089a77195ddf0cc445a` and re-read before publication. No existing files or code are changed. All migration material is under `assets/` on a separate review branch.

| Guide requirement | Recovered material / conflict | Treatment in this draft |
| --- | --- | --- |
| Transparent PNG, hard edges, no smoothing | Town and biome boards are full opaque compositions; apothecary is an opaque crop, originally WebP. | Reference archive only, excluded from Godot imports. Original WebP retained for provenance beside an unresized PNG conversion. No claim of production compliance. Review before deriving sprites. |
| 32px grid; characters stand on one square | Legacy town master is 1518 × 1036; mockups are 1536 × 1024. They are paintings, not registered tilemaps or 32px frame sheets. | Do not use their dimensions as collision geometry, sprite frame size or proof of tile registration. |
| Rows idle/walk/attack/hurt/death; equal frames and fixed feet | No recovered Thomas Wren sheet; environment boards have one still frame and no directions. | No substitute animation sheets. Folder READMEs identify dimensions, frame counts and directions as applicable. |
| Follow story foundation and characters-for-art | Those source docs and the requested art bible are missing. Legacy town notes contain older landmark/NPC/service assumptions; biome prompts include Victorian-gothic machinery. | Do not adopt older story or setting details as current canon. Current repository README and guide constraints are the only recovered Godot foundation. No guns are introduced. |
| Art stays in assets; code belongs to Claude | Legacy documents describe renderer integration, service unlocks and old validation results. | No web-game code or integration instructions are applied to Godot. Historical prompt notes are clearly labelled; they do not establish current behavior or tests. |

The request to preserve reference artwork inherently includes images that are not transparent sprites. This draft makes that distinction visible for review; it does not waive the guide's production delivery rules. Production sprites require separate exports and validation after missing source references are recovered.
