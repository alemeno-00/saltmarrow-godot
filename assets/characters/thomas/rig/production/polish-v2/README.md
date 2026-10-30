# South rig readability revision v2

Built-in image generation revised the existing eleven-part south sheet while preserving the supplied rig contract. Runtime exports remain `../../s.png` and `../../s_n.png`: eleven24×24 cells in one row,264×24 total. Head/torso pivots(12,22), all other pivots(12,2). No skeleton motion or renderer code was edited.

- `south-parts-master-v2.png`, `parts-prompt-v2.txt`: revised isolated parts source and full prompt; four-column/three-row working layout, last cell empty. Inputs were the registered v1 parts and approved steady portrait for identity.
- `head-cell-target.png`: enlarged24×24 intermediate head cell supplied to the focused head edit.
- `head-master-v2.png`, `head-prompt-v2.txt`: separate head repaint and full prompt, made for clear facial features within9×9 native pixels. This source overrides cell1 of the full parts master.
- `south-parts-normal-master-v2.png`, `normal-prompt-v2.txt`: regenerated normal-colour source and full prompt. Export normalizes vectors and applies exact diffuse alpha.
- `before-s.png`, `before-s_n.png`: exact runtime sheets from main before this revision,264×24, archived for comparison.
- `before-assembled-s.png`: previous80×80 mechanical standing preview.
- `validation.json`: checked layout, pivots, palette, transparency, source revision, checksums and pending in-game approval status.

Run `../export_parts.py` followed by `../preview_parts.py` using Pillow to reproduce the mechanical palette/registration/assembly work. They do not paint new anatomy or generate different appearances for animation frames. Native part sizes remain those of v1. The body is still viewed from the raised room camera and the mechanical standing assembly remains52px tall.

The current source skirt is belt-free, so export no longer trims a duplicated belt from it. Previous masters remain unchanged in the parent production folder. Preview comparison images show before on the left and v2 on the right. Actual game lighting and moving joint contact still need review.
