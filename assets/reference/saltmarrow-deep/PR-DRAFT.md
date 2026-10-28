# Archive recovered Saltmarrow art references and flag missing design materials

The earlier Saltmarrow conversation does not expose downloadable image attachments or the requested art bible through the current reader. This change preserves accessible local art in an explicitly labelled reference archive, with provenance, dimensions, hashes and missing-material records. It does not claim a complete recovery of the latest chat revisions.

All 20 added files are under `assets/reference/saltmarrow-deep/`. The 28 pre-existing tracked files are unchanged. `.gdignore` keeps the archive out of Godot imports. No production art is wired into the project.

Recovered: two town image sources, older Thorn Apothecary crop (original WebP and PNG conversion), four town-led biome mockups and saved prompts. Thomas Wren feedback and current repository story constraints are recorded separately from missing source documents.

## Review conflicts before adopting production assets

See `GUIDE-CONFLICTS.md`. Opaque compositions and an archived WebP do not meet the transparent-PNG production sprite requirements. The images are not registered tiles or animation sheets. Legacy web-game story/progression and Victorian-gothic prompt details are not adopted as Godot canon. The story foundation, characters-for-art sheet, Thomas Wren concept sheets/final revisions and complete character/story art bible remain unavailable. The recent town/apothecary images cannot be positively identified against the older recovered references.

## Verification

- Checked checksums and source-copy equality for preserved originals; recorded ten copied/converted artifacts and five recovery gaps.
- Verified native dimensions for all eight image files through macOS ImageIO; visually inspected both town sources and the original apothecary crop.
- Verified all local Markdown links and all 28 original tracked files remained byte-for-byte unchanged.
- Preserved one existing terminal blank line in the verbatim legacy prompt notes; whitespace validation passes with that archival exception.
- Godot tests were not run locally because Godot is not installed. Existing pull-request CI should run unchanged once this draft is published.

Keep as draft pending review of guide conflicts and recovery gaps. Do not merge automatically.
