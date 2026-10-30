# Thomas: guide-based camera test (job 15-0)

Review candidate for the raised, slightly angled room camera. Julian must approve the in-game camera test before the remaining directional sheets are drawn. This is not a replacement for the live 64px sheets.

| File | Frame size | Canvas | Rows, left to right |
| --- | --- | --- | --- |
| camera_test.png | 80×80 | 640×240 | 1: south idle,6; 2: south walk,8; 3: east walk,8 |
| camera_test_n.png | 80×80 | 640×240 | Matching OpenGL normal map; green up; exact diffuse alpha |
| manifest.json | — | — | Frame counts, timing and export validation |

Root reference is (40,72); heel-to-crown export targets are48–52px. Suggested playback: idle7fps, walks10fps. Empty cells7–8 of row1 are transparent. West may be mirrored from east by the game.

## Pose and camera checks

Each of the22 frames was painted separately with the supplied guide and approved standing reference. Anatomical left/right contacts and opposite arm positions were compared on the guide review pages. Two east frames were repainted after their facing drifted toward the viewer. Guides and full prompts are preserved in production/guided-v1/.

The upstream guide figures measure approximately55px, with a wider range across projected stride poses. Export applies a common0.9 guide-space calibration about (40,72), then uniform per-image registration to the specified48–52px range. This is documented in export-report.json; raw painted sources and unchanged guides remain available for comparison. Export does not synthesize limb poses or mirror one contact to make the other.

House-style export checks: shared painted-room palette, four muted reds explicitly allowed by Julian, hard binary alpha, coloured material edges, restrained texture, no added cast shadow, darker boot contact pixels and a matching normal map. See previews/guided-room-comparison.png for native pixel density on the actual junction floor. This static composite is not proof of in-game lighting or camera approval.

## Review limits and wiring for Claude

- Load the candidate as three80px rows with counts6/8/8; attach camera_test_n.png. Existing sprite loading and paths have not been changed.
- Check the loop in the painted room: foot planting at movement speed, continuity of body/equipment, and especially the east camera against the approved concept. Guide overlays and unique frame hashes do not certify anatomy or a smooth loop.
- Generated normal colours are fitted to the atlas and masked to exact diffuse alpha; verify the rounded volumes under the game lights.
- Camera approval and moving foot-contact approval are pending. Keep job15-0 unchecked until approved; do not treat this candidate as approval to draw the rest of job15.

Old development studies may be present in a working checkout. They are not part of this delivery and must not be used as runtime masters.
