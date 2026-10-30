# Guide-based production sources

Built-in image generation painted each frame separately. Inputs: that individual supplied pose guide and Thomas's approved standing candidate. Camera correction prompts additionally use the accepted east contact as an orientation reference. No online LPC pixels are used in this delivery.

- idle_s-01 through06, walk_s-01 through08, walk_e-01 through08: each *-paint.png is one transparent generated source frame; each *-guide.png is its corresponding pose mechanically enlarged to1024×1024; each *-prompt.txt is the full prompt.
- walk_e-02-camera-correction-prompt.txt and walk_e-03-camera-correction-prompt.txt: follow-up prompts for selected corrected frames. Original prompts document superseded attempts; rejected images are not included.
- idle_s-guide.png: unchanged upstream80×80 guide frames,6 in one row. walk_s-guide.png and walk_e-guide.png:8 each. Red=left leg, blue=right leg, orange=left arm, cyan=right arm.
- approved-standing-8x.png: nearest-neighbour enlargement of the approved standing reference. The original remains untouched.
- guide-source.json: pinned revision and upstream guide paths.
- export_guided.py: mechanical binary-alpha cleanup, colour mapping, size/placement registration, atlas/GIF/comparison assembly and normal-vector normalization. It does not draw animation poses.
- export-report.json: per-frame bounds, scale registration and unique pixel hashes.
- camera-test-unscaled.png: intermediate assembled diffuse atlas,640×240 (despite the historical filename it includes the documented registration).
- camera-test-normal-master.png and normal-prompt.txt: generated normal-colour source and prompt; exported normals use exact diffuse alpha.
- validation.json: format checks and pending review status.
- .gdignore: excludes production sources from runtime imports.

Only ../../camera_test.png and ../../camera_test_n.png are proposed runtime sheets. Three rows of80×80 frames: south idle6, south walk8, east walk8; root(40,72). The test README documents guide calibration and required in-game review.
