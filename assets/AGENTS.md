# Humanoid art workflow

Julian requires supplied pose/rig guides for all future humanoids, including enemies and NPCs. Read the current animation brief and character job before painting.

- For every character and every drawn direction, first paint one complete whole-figure model sprite from its approved concept and character brief. Check it at actual game size against the room and existing cast. Julian must approve this model before any parts are cut. Never paint rig parts directly.
- After explicit model approval, cut those same pixels into the supplied rig template's cells. Do not repaint or redesign the parts. Only add a few hidden overlap pixels at joints so rotations do not expose gaps. Reassembling the rest pose must reproduce the approved model pixel for pixel. Preserve the documented cell order, pivots, room camera and character scale; flag incompatible templates instead of silently changing the model or rig.
- Put readability before texture: large clear shapes, 3–4 values per material, readable face and carried equipment. Wear and texture use small connected 2–3px clusters; never single-pixel speckle, dithering or noise. Review at1× before calling a model ready.
- Painted-frame actions still use the corresponding supplied pose guide, one frame at a time, with explicit anatomical left/right identity. Check the result against the guide.
- Flag missing or incompatible templates/guides in the pull request for Claude. Do not invent unsupported poses or silently change the rig.
- House style, normal maps, asset-only ownership and protected approved reference paths remain governed by the parent AGENTS.md and ART_JOBS.md. In-game camera approval is required before expanding a test into all directions.
