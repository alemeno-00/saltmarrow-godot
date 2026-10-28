# Generated source masters — not runtime assets

`standing-generated.png` and `portrait-generated.png` are the unchanged imagegen outputs for the two pixel candidates. Actual dimensions and alpha are recorded in `../qa/inventory.json`. Each contains one image, no animation rows; both face three-quarter right. The standing master requests an elevated dungeon camera; the portrait is chest up.

These large images are source material, not native pixel exports. Preserve them for provenance; use the 64×64 and 128×128 candidates in `../sprites/` for technical review. Full prompts are in `../PROMPTS.md`. An export cannot repair likeness or costume errors: those must be revised in art and reviewed again.
