# Job15-R — approved whole-figure model

This is one south-facing model, painted as a complete figure from `assets/characters/thomas/production/concepts/canonical-reference-v1.png` and the character brief. It is not assembled from the rejected parts. The approved model is awaiting compatible rig/template calibration before cutting. Existing `rig/s.png` and `s_n.png`, approved still/portrait paths and the canonical reference remain unchanged.

## Approved model

`../model-s.png`: one transparent80×80 frame, south-facing,52px heel-to-crown, feet-root(40,72). The coat is a continuous long dark shape with an open front and ragged lower panels below the knees; scarf, cross-body strap, left-hip canvas bag, separate belt lantern, trousers, wraps and boots are painted into this whole model.

`../model-s_n.png`: matching80×80 OpenGL normal map, green up, exact diffuse alpha. It is a whole-figure map, not a parts map. Actual game lighting is not tested in these composites.

### Approved palette

The shared room palette supplies grey-beige or amber for skin and did not preserve a warm human mid-tone in this model. The model uses four flesh colours sampled from the canonical reference; exact RGBs are in `registration.json` and `validation.json`. All other colours come from the shared room palette and the previously approved muted-red accents. Julian accepted the model on 2026-10-31, requesting a warmer dark-brown coat. That coat change preserves every silhouette and shading boundary: 180 coat pixels changed colour; no non-coat pixels or normal-map pixels changed.

Materials use3–4-value ramps, quiet connected shading clusters and no added dither pattern. Palette conversion includes an eye-white correction for the tiny model so the eyes are dark readable marks rather than glowing pixels. The bottom sole row is darkened without adding a cast shadow. Readability and likeness remain visual approval decisions; format checks do not certify either.

## Sources and export

- `canonical-front-crop.png`: mechanical crop of the canonical sheet's front view, used as identity/costume reference.
- `cast-pixel-density-reference.png`: unchanged first Faithful/Miner frames enlarged for the painting tool's density reference.
- `model-native-source.png`, `model-native-prompt.txt`: built-in image-generation source and full prompt for the complete figure.
- `model-native-edit-target.png`: registered pixel-density intermediate supplied to the targeted whole-figure face/kit edit.
- `model-refined-source.png`, `model-refine-prompt.txt`: selected complete-figure source and full refinement prompt. No body part was painted or delivered separately.
- `model-normal-source.png`, `model-normal-prompt.txt`: generated normal-colour source and full prompt.
- `export_model.py`: mechanical alpha cleanup, nearest-neighbour52px registration, explicit material palette conversion, normal-vector normalization, exact alpha matching and preview assembly. It does not cut rig parts.
- `material-ids.png`: one80×80 material-label diagnostic frame, matching the model; labels1–7 identify coat, skin, hair/boots, canvas, wraps, brass and scarf, with8 for the eye correction.
- `registration.json`: scale, source bounds, foot anchoring and material colour ramps.
- `validation.json`: format checks, protected-file hashes, approved skin accents, model checksum and template-fit status.
- `.gdignore`: source/review media are not runtime game resources.

## Review files

See `previews/README.md`: the8× model beside the canonical sheet, a1× room composite and unscaled cast comparison are the main checks. They show the actual exported model, not the larger generated source.

## Approval and next step

Julian approved the whole model and chose the warmer dark-brown coat: “warmer dark brown , that sprite is great also”. The coat now uses four existing room colours. This approval applies to this south model and its skin ramp; it does not approve other directions or in-game animation.

Step2 began with the template-fit audit in `../cut-15r/README.md`. The current rig places the waist so the torso cell cannot retain the bottom of the approved scarf and carried kit. Preserve the model and calibrate the template/rig before cutting; do not silently crop, resize, or repaint it. Runtime parts remain untouched and job15-R remains unchecked.
