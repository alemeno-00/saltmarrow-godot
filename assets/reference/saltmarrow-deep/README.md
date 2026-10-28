# Saltmarrow Deep — recovered art and design references

This is a **partial recovery for review**, not a complete migration of the referenced chat. Original files remain in the source workspace. Nothing is wired into Godot. `.gdignore` keeps this reference archive out of the resource import pipeline; it is intentionally not a production sprite folder.

- [Town hub](town-hub/README.md): local town reference and older web-game master.
- [Apothecary](apothecary/README.md): older Thorn composite crop, with original and PNG conversion.
- [Biome mockups](biomes/README.md): four town-led design previews and their saved prompts.
- [Thomas Wren](characters/thomas-wren/README.md): recoverable feedback and missing-sheet status.
- [Character/story recovery notes](story/README.md): confirmed repository foundation and missing art bible.
- [Migration inventory](migration-inventory.json): source paths, byte counts, SHA-256 checksums, dimensions and missing materials.

## Recovery limits

Source conversation: [Saltmarrow Overhaul Plan](https://chatgpt.com/c/6adf1cb2-6234-83ec-8c9b-94411183e488). The chat reader returned five user turns, one unresolved assistant content-reference marker, no attachments, and no older-page cursor. It did not expose image bytes, downloadable image URLs, class names beyond one mention of “fury”, or the art bible. A content-reference marker is not an image file.

The local `Game` workspace contains older Saltmarrow art. These files are recoverable, but their presence does not prove they are the recent conversation's final images. The town reference and v6 master look alike but have different byte hashes, so both are retained with distinct names. No artwork was generated to fill missing files, and no older class art is relabelled as Thomas Wren.

Existing Godot files, assets, settings, scenes, scripts, workflows and tests are preserved. All additions are confined to this new folder under `assets/`, following the repository's art ownership boundary. These opaque environment compositions are archived as reference art, an intentional exception to the transparent production-sprite delivery format. Production exports still need the repository's PNG, hard-edge, 32px-grid and animation-layout requirements.

## Completing recovery

Supply the original town hub and apothecary images if they differ from these legacy references, the grounded Thomas Wren class concept sheets (including the final version without descriptions), and the full character/story art bible, story foundation and characters-for-art sheet. Keep incoming revisions under new filenames, record their source and checksums, and review before choosing production assets. Do not replace these files silently.
