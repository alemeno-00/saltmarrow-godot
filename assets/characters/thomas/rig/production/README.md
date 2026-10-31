# South rig production files

- `template_s.png`, `template_s_4x.png`, `assembled_s_4x.png`: unchanged upstream south template and assembled stand-in reference from skeleton revision5d836a0. Template:11 cells of24×24. Assembled reference: one80×80 frame enlarged4×.
- `template_s-packed-12x.png`: same11 template cells repacked4 columns×3 rows (last cell empty) and enlarged12× for the image tool. Final runtime order remains a single row.
- `approved-standing-8x.png`: nearest-neighbour appearance reference; the original approved file is unchanged.
- `south-parts-master.png`, `south-parts-prompt.txt`: built-in image generation source and full prompt,11 painted parts in the packed grid.
- `south-parts-registered-packed.png`: exported24px parts repacked4×3 and enlarged12× for normal generation.
- `south-parts-normal-master.png`, `south-parts-normal-prompt.txt`: generated OpenGL normal-colour source and full prompt.
- `export_parts.py`: mechanical per-cell extraction, stray-alpha cleanup, template-size registration, palette conversion, normal-vector normalization and exact diffuse/normal alpha matching. It does not paint or animate body parts.
- `registration.json`: each cell's part name, pivot, size, source bounds and fixed paste offset.
- `preview_parts.py`: mechanical compositing with the pinned Rig/RigPose equations for standing and eight walk samples; does not repaint any frame. This is a preview, not a Godot integration test.
- `validation.json`: source revision/template checksum, format checks, assembled size and pending approval status.
- `.gdignore`: excludes production sources from runtime imports.

Runtime outputs: `../s.png` and `../s_n.png`, one row of11 cells,24×24 each. See the parent README for cell order and pivots.

## Job15-R step1: whole model approval

model-s.png and model-s_n.png are one80×80 south-facing whole-figure approval candidate,52px tall, feet-root(40,72). They are not runtime parts replacements. See model-15r/README.md for source prompts, concept/room/cast previews, the proposed four-colour skin exception and the explicit stop before any cutting. Existing rig/s.png and s_n.png remain untouched.
