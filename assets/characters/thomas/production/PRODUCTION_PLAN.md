# Thomas Wren character-art workstream

Status: first tranche for review; no canonical approval or runtime integration implied.
Source baseline: `main` f5926ca, read 2026-10-29 (Australia/Brisbane).
Owner boundary: art and its documentation under `assets/` only. Godot integration belongs to Claude.

## Source order and reference availability

Read `AGENTS.md`, `ART_JOBS.md`, `docs/characters.md`, `docs/story.md`, and the relevant weapon/backstory context in `docs/trees.md` before production.
The user's current brief takes precedence where the earlier concept board differs. Repository dimensions and delivery layout remain binding.

`references/user-five-lives-concept.png` is the supplied 1536×1024 composite, preserved unchanged. It is an accessible concept reference, not an atlas, portrait export, turnaround authority or game-ready sprite sheet. Its rendered miniatures are not pixel sprites.
The referenced ChatGPT conversation is `6adf1cb2-6234-83ec-8c9b-94411183e488` (“Saltmarrow Overhaul Plan”). History was read; it exposes text/content-reference placeholders and no downloadable original images. Original individual approved class images, full-resolution source layers and original turnaround files remain unavailable. The supplied composite is the only recovered visual reference; do not pretend its tiny panels are original files.

## Likeness lock

Thomas is 28: tall, lean and underfed, an ordinary exhausted veteran whose soldier's posture sags. Long hollow cheeks, grey watchful eyes, dark brown army-short hair growing out unevenly, two weeks of stubble. Keep nose, eye spacing, ear shape, jaw and hairline consistent across variants. Do not age him into a grizzled master warrior.

The healed blade scar runs from his anatomical LEFT cheekbone to a notch in his LEFT ear. A right-facing three-quarter portrait shows that near-side cheek. Never copy a mirrored scar into the opposite anatomical cheek in references. At 64 px, preserve a restrained scar cue where legible; do not enlarge it into face paint.

Every life retains Ellen's faded red knitted scarf. Canvas letter satchel, string-tied letters and a small hooded campaign lantern are continuity props. Greatcoat is dark-dyed army wool, mismatched buttons, worn elbows; wool trousers, shin wraps and cracked campaign boots. Clothes are repaired and used, not elaborate shredded fantasy armour.

Cold slate, charcoal and wet brown dominate. Dull red is the identity accent; amber stays small and local. No guns, ornate armour, fur warrior mantles, trophy belts, glowing gems or spectacular magic.

## Six visual identities

| Identity | Body and face | Costume and prop distinction | Reject |
| --- | --- | --- | --- |
| Canonical | Lean, slight tired stoop, short uneven hair, stubble | Dark-dyed greatcoat, scarf, satchel, hooded lantern, empty hands | Hero pose, heavy armour, ornate weapon |
| Fury | Same height and bone structure, modestly thicker/plumper waist and cheeks, fuller practical beard | Plain reinforced worn coat; maul only as separate reference/weapon layer | Bulky shoulders, bodybuilder arms, giant beard, barbarian fur |
| Shadow | Thin; same face visible beneath hood | Light patched hooded oilskin/wool, light leather, compact satchel; knives separate | Mask hiding all likeness, assassin armour, oversized blades |
| Elementalist | Lean, same stubble and face | Shabby slate robes over ordinary clothes; unadorned wooden staff | Wizard finery, crystal staff head, lightning spectacle |
| Censor | Lean, same face and stubble | Plain threadbare formal black coat; small utilitarian censer on short chain | Gold trim, jeweled cross, cathedral armour, giant censer |
| Talent | Lean, same ordinary soldier | Worn soldier clothes; minute pearly eye sheen / faint throat sign only | Superhero glow, exposed mutated arms, spectacular magic |

Talent's requested uncanny detail is a visual candidate, not a change to the game's rule that Mind is safe. Star signs normally follow Attunement/Marks; Claude should keep this version optional until the story owner decides whether a starting Talent carries a Mark. Preserve an unmarked base for production.

## Delivery contracts

| Asset | Exact delivery | Perspective and alignment |
| --- | --- | --- |
| Portrait | 128×128 transparent PNG; hard pixel edges, no smoothing, no text | Chest up, three quarters right; readable scarf and left cheek scar |
| Character frame | 64×64 transparent PNG; one consistent palette | Slightly elevated dungeon view; right facing, visible crown/shoulder tops, feet centred at (32,56); 32×32 ground footprint |
| Body sheet | 384×448 PNG for 7 rows, maximum 6 cells per row | No gaps; unused cells transparent; rows below; weapons separate |
| Attack sheet | 512×256 PNG for 4 rows, maximum 8 cells | Same 64×64 canvas and origin; no automatic rescaling to fit oversized weapons |
| Reference sheet | Full-resolution source PNG, dimensions documented | Front / right three-quarter / back and portrait; CONCEPT ONLY; never loaded as runtime sprite |

Source illustrations may have neutral opaque backgrounds and antialiasing because they are references, explicitly excluded from game delivery. Runtime candidates must meet the transparent pixel standard. A valid file format is not approval of likeness, animation or game readiness.

Runtime left-facing mirroring reverses the scar and satchel. This is an existing repo contract, not something an artist can resolve with code here. Ask Claude to decide whether asymmetry needs separate left-facing art later. Deliver right-facing art now.

## Animation production ledger

Row numbers are one-based; coordinates in pixels are zero-based. Timings below are proposed review timings, not engine changes. Root stays (32,56); locomotion is in-place. Keep head proportions, scarf attachment and prop placement stable; coat and satchel follow the body with small delayed motion.

| Body row | Animation | Frames | Proposed fps | Required performance / gate |
| --- | --- | --- | --- | --- |
| 1 | idle | 4 | 4 | Quiet breathing, planted soles, subtle shoulder/scarf change, seamless loop |
| 2 | walk | 6 | 8 | Distinct contact, passing, opposite contact; no skating; loop |
| 3 | sneak | 6 | 6 | Lower centre, cautious short steps; loop |
| 4 | hurt | 3 | 10 | Impact, recoil, settle; one shot |
| 5 | wounded walk | 6 | 6 | Asymmetric limp and hand to side; loop |
| 6 | dying crawl | 6 | 5 | Weight through elbows, drag legs; root remains registered while silhouette is low |
| 7 | death | 6 | 7 | Loss of support through ground contact; final frame lies still and holds |

37 populated body cells, 5 empty trailing cells. Idle-only files must not be named `body.png` or represented as job 1 completed.

| Mace row | Frames | Proposed fps | Required gate |
| --- | --- | --- | --- |
| wind-up | 3 | 6 | Weight gathers, clear threat before impact |
| strike | 3 | 12 | Continuous hand grip and maul head arc; readable impact |
| recovery | 3 | 7 | Heavy ordinary-person effort and recovery |
| crit | 8 | 6 | Bigger slower overhead blow, no superhuman flourish |

Careful step is requested as body row 8 (4 frames), but job 7c also asks for a maul held across the body whereas job 1 forbids a weapon in the base sheet. Keep it pending as a separate body/weapon-layer decision for Claude. Do not silently bake a maul into all base frames. If approved as an eighth row, canvas becomes 384×512.

## Ordered remaining checklist and acceptance gates

1. [ ] Approve canonical face against supplied composite and written age/hair/scar requirements. Review all five variants for the same likeness; request originals only if needed to settle differences.
2. [ ] Approve anatomical left scar/ear notch in front, three-quarter and rear references; inspect satchel strap and lantern attachment for continuity. Generated turnarounds are proposals, not reliable construction drawings until reconciled.
3. [ ] Finish job 1 first: 37 distinct body frames in the seven required rows. Preserve weapon-free hands and fixed root. Review at native size on dungeon floor and in motion.
4. [ ] Complete job 2: 17 mace cells (3/3/3/8), separate from base; then job 2b abilities (8/8/9/10/12 = 47 cells). Test grip, arc, clipping and attachment to body in every frame.
5. [ ] Complete job 3 health portraits: steady, hurt, badly_hurt, dying (four 128×128 files). Preserve face geometry; injury states change injury/expression, not identity.
6. [ ] Export five backstory portraits, each 128×128, after canonical approval. Fury modestly fuller; Shadow hood must still expose the left scar; Censor plain; Talent sign subtle and story-approved.
7. [ ] Reconcile front/three-quarter/back full-body construction for all six identities; retain common scale. Front and back references are not extra runtime facing directions.
8. [ ] Derive variant idle/walk sheets only after canonical animation approval; keep base skeleton, ground anchor and hand sockets. Build clothing/weapon layers after Claude confirms scope.
9. [ ] Expand to other weapon attacks, casting, swaps, injuries and Star stages per ART_JOBS. Mind/Talent effects stay separate from permanent Star overlays.
10. [ ] Final delivery: check exact PNG dimensions, alpha only 0/255, no stray border pixels, no text, palette/colour count, no clipped silhouette, trailing blank cells, row/frame counts, root/soles, continuous motion and first/last loop seam. Run contact sheets at 1× and nearest-neighbour 4×; review on a 32×32 dungeon grid. Record results and unresolved defects, never infer animation quality from dimensions alone.

Only mark an ART_JOBS checkbox when its whole deliverable passes. This tranche does not complete jobs 1–3; the master list stays untouched. Final approval and integration are review gates; no merge without the user's approval.
