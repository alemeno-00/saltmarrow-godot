# Humanoid art workflow

Julian requires supplied pose/rig guides for all future humanoids, including enemies and NPCs. Read the current animation brief and character job before painting.

- When the job uses the skeleton, paint each character once per direction as separate rest-pose parts over the supplied rig template. Preserve the documented cell order, pivots, joint overlap, room camera and character scale. The rig supplies movement; do not generate separate appearances for walk frames.
- Painted-frame actions still use the corresponding supplied pose guide, one frame at a time, with explicit anatomical left/right identity. Check the result against the guide.
- Flag missing or incompatible templates/guides in the pull request for Claude. Do not invent unsupported poses or silently change the rig.
- House style, normal maps, asset-only ownership and protected approved reference paths remain governed by the parent AGENTS.md and ART_JOBS.md. In-game camera approval is required before expanding a test into all directions.
