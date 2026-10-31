# Animation brief: characters in every direction, moving fluidly

For ChatGPT, art jobs 15–17 in `ART_JOBS.md`. Written after the first playtest (2026-10-30). Julian's notes:

- "The walking looks like only 2 frames." Thomas's walk row has 6 frames, but the legs barely change between
  them, so the eye only reads two poses.
- "Very little directional movement." Everything is drawn facing right and mirrored; walking up or down the
  screen shows a side view.
- "The animation needs a lot more work and needs to be more fluid."
- "The sprites don't feel like part of the environment, just sprites stuck onto a background."

Thomas now moves freely in any direction at **3.5 m/s** (one 32 px square is 1.5 m, so about 75 px a second), and
fights are moving the same way (`design/quick-specs/free-movement-2026-10-30.md`). The art has to keep up.

## The directions

- **Draw five directions: S, SE, E, NE, N.** The game mirrors SE, E and NE to get SW, W and NW. This replaces the
  "right only" rule for the jobs below. (Your eight-direction proposal, #5, draws all eight; mirroring the west
  side halves the work, and Thomas's scarf is the only asymmetry that shows. If mirrored frames look wrong once
  they are in the game, we draw the west side too.)
- **One sheet per direction**, with the same rows in the same order in every sheet:
  `assets/characters/thomas/dir/s.png`, `se.png`, `e.png`, `ne.png`, `n.png`.
- Frame **80 × 80**, feet at **x 40, y 72**, and characters about **1.5 squares tall (48–52 px from heel to crown)**,
  as the approved camera concept shows; the bigger frame leaves room for overhead swings. Frames left to right, no gaps. A `README.md` beside the sheets
  lists rows, frame counts and suggested fps.
- **S faces the camera, N faces away.** SE and NE are three-quarter views. In the N view we see his back, the scarf
  and the maul's haft over his shoulder.

## The camera (the most important part)

Julian, 2026-10-30: the sprites "look like they belong on a sidescroller". They do: today's Thomas is drawn from eye
level, a flat side profile with his feet side-on on a line, while the rooms are painted from a raised, slightly
angled top-down camera that shows the tops of walls and props. The eye reads the difference as a cut-out stuck on a
map. Draw every character from **the rooms' camera** (`assets/docs/references/camera-perspective-concept.png`: the
highlighted "top-down, slightly angled" panel, the in-game example and the character scale strip):

- **From above:** the top of the head and shoulders show; the face is seen a little from above; the body is a little
  shorter top to bottom than it would be side-on.
- **Feet on the floor:** the tops of the boots show, planted on the floor plane and overlapping it a pixel or two;
  never soles standing on a line. The game draws the shadow.
- **South is the default:** standing still, a character faces the camera (S). E and W are three-quarter views from
  above, not flat profiles: the far shoulder and far leg show. N shows the back and the top of the head.
- **The walk from above:** steps move up and down the screen as well as across it; the stride is seen from above,
  so legs foreshorten as they swing toward and away from the camera.

**Start with a camera test** (art job 15-0): Thomas facing south, idle and walk, and walking east. Claude puts it in
the game beside a painted room for Julian to approve before the rest is drawn.

## The skeleton: paint parts, not frames (Julian, 2026-10-30)

Painting every frame doesn't work: even over the pose guides (#47), each frame came out a slightly different Thomas,
so he flickered, and the detail turned to mush. So characters are now **parts on a skeleton**: you paint each
character **once per direction, as separate parts**, and the game moves the parts with the same walk the guides
show (`scripts/game/rig.gd`, `rig_pose.gd`). Every frame is the same drawing, so nothing flickers, and walking,
standing, sneaking and limping all come from one sheet. Proof: `production/qa/evidence/rig-proof/walk_compare.html`
(your own south frame, cut into parts, walking).

**A parts sheet** is one row of eleven 24 × 24 cells (264 × 24 px), one part per cell, in this order:

| Cell | Part | What it holds | Pivot (the white cross) |
| --- | --- | --- | --- |
| 1 | head | the head and hair, standing up from the neck | bottom middle, the neck |
| 2 | torso | shoulders to waist: coat, scarf, belt, satchel strap, the lantern at the hip | bottom middle, the waist |
| 3 | skirt | the coat below the waist, hanging down | top middle, the waist |
| 4 | upper arm, left | his left upper arm and sleeve, hanging down | top, the shoulder |
| 5 | forearm, left | his left forearm and hand, hanging down | top, the elbow |
| 6 | upper arm, right | | top, the shoulder |
| 7 | forearm, right | | top, the elbow |
| 8 | thigh, left | his left thigh (mostly under the coat), hanging down | top, the hip |
| 9 | shin, left | his left shin and boot, hanging down | top, the knee |
| 10 | thigh, right | | top, the hip |
| 11 | shin, right | | top, the knee |

- **Cut from an approved whole model, never painted part by part** (house style rule 10, job 15-R). The rig's
  proportions are measured from Thomas's approved south model (`rig/production/model-s.png`, 80 × 80, feet at
  (40, 72)): neck row 30; shoulders row 32 at x 33 and 47; elbows row 40; hands row 48; hips row 50 at x 36 and 44;
  knees row 59; ankles row 68; the coat's hem row 62. Standing as painted (the **bind pose**, `RigPose.bind()`), every
  part's pivot falls on a whole pixel of the model and nothing is turned.
- **`rig/bind_s.json`** gives, for each part, the 24 × 24 square of the model its cell holds (`model_square`) and
  where its pivot is (`pivot_on_model`, `pivot_in_cell`). Copy each model pixel into the cell of the part it belongs
  to, at (x − square x + cell x, y − square y), unmoved; every model pixel goes to exactly one part.
  **`rig/cut_guide_s.png`** shows the squares and pivots over the model at 8 ×.
- **The torso's pivot is at row 21 of its cell** (not 22, as first drawn): its square covers model rows 29–52, so
  the scarf's end (row 51), the strap, the satchel and the lantern all stay on the torso, as the brief assigns them.
- **Check a cut**: `godot --headless --path . -s tools/rig/rig_template.gd -- check <model.png> <parts.png>` puts the
  parts back together in the bind pose and lists every pixel that differs; none means the cut is right.
- **Templates**: `rig/template_s.png` (and `_4x`) show every cell with a stand-in shape of the part and its pivot.
  The other directions get theirs once each has an approved whole model (job 15).
- **Rest pose**: limbs hang straight down from their joint; the head and torso stand straight up from theirs. The
  game turns them; don't draw them bent or swinging.
- **"Left" means Thomas's left.** Facing south (toward us) his left arm is on the screen's right.
- **Each direction is its own sheet**, seen from the rooms' camera from that side: `s`, `se`, `e`, `ne`, `n`. Facing
  east, the far arm and leg (his left) are partly hidden by the body; paint them anyway, whole.
- **Overlap a little at the joints** (a pixel or two past the pivot), so no gap opens when a part turns. Overlap
  pixels go only where a part drawn later covers them in the bind pose (the coat skirt over the thighs, the torso
  over the upper arms' tops), so the check still finds no difference.
- **`rig/assembled_s.png`** shows the stand-ins put together in the bind pose, and **`rig/walk_s.png`** the
  stand-ins walking through the real rig: what the game will do with your parts.
- A normal map with each sheet (`s_n.png`), as the house style says.

Attacks and hit reactions stay painted frames for now (job 16); they may move to the skeleton later.

## Pose guides (paint over them)

*Kept for reference: the skeleton above replaces painting walks frame by frame. The guides still show what the
walk looks like, and are drawn from the same rules the skeleton uses.*

ChatGPT, 2026-10-30, was getting stuck: generated frames don't keep track of which leg is which, so the legs came out
the same in every frame. Claude now makes **pose guides**: each frame of each animation as a colour-coded figure
(left leg red, right leg blue), worked out as a real walk and drawn from the rooms' camera, with marks where planted
feet stay. Paint Thomas over them one frame at a time. They are in `guides/` beside this brief, with a README on how
to use them. More animations (sneak, attacks, getting hurt) get guides as they come up.

## What makes it fluid (applies to every row)

- **Readable key poses.** A walk cycle is two steps; each step has a contact pose (heel down, legs wide), a down
  pose (weight sinking, knee bent), a passing pose (one leg passes the other) and an up pose (pushing off). With 8
  frames, every frame is a different one of those. Legs, arms, head height and coat must visibly change from frame
  to frame. Check by flipping through the frames: if two neighbouring frames look nearly the same, redraw one.
- **The body bobs.** The head drops a pixel on the down poses and rises a pixel on the up poses.
- **Arms swing against the legs**, as far as the maul allows.
- **Things that hang lag behind.** The coat hem and Ellen's scarf trail a frame behind the body, and settle a frame
  after he stops.
- **No sliding feet.** The planted foot stays on the same pixel while it carries the weight. One full cycle (two
  steps) covers about **60 px** at walking speed, so each step is about 30 px.
- **Every loop joins up.** The last frame leads straight back into the first.

## Fitting into the rooms

The rooms are painted with soft light and texture. Sprites drawn as hard cut-outs on top of them look pasted on. These rules are now the house style for all art in rooms (`ART_JOBS.md`, "House style").

- **The paintings' grain.** Break up flat areas with the same soft clusters, wear and grime the rooms use.

- **No black outline.** Use a dark outline in the local colour (dark brown on the coat, dark red on the scarf), and
  drop it entirely where the light hits.
- **Neutral, even light.** The game lights the sprites with its own lanterns. Don't bake in orange or a light
  direction.
- **The same palette as the rooms.** Take the colours from `assets/tiles/sewers/rooms/` (the shared palette in its
  `validation.json`), so the sprites and the floor come from one set of colours.
- **Clear against the floor.** Your #5 review found the narrow brown silhouette blending into the paving. Separate
  the values: a slightly lighter face and hands, a darker coat, and a clear gap between the legs.
- **Wet feet.** The bottom pixel row of the boots is darker and damp, so he stands *on* the stone.
- **Normal maps** (job 17): the game can light a sprite from the side a lantern is on, so a lantern to his left
  lights his left side. That needs a matching normal map for each sheet.

## The jobs, in order

0. **Job 15-0: the camera test** (above), approved by Julian before anything else.
1. **Job 15: Thomas moving, in five directions.** In each direction sheet, rows: idle (6, breathing and a weight
   shift, looped), walk (8, looped, 10 fps), wounded walk (8, a limp, looped), sneak (8, crouched, slow, looped, for
   sneaking: see the coming sneaking spec), careful step (4). **Send the S, E and N walks first** as a small pull
   request, so we can check them in the game before the rest.
2. **Job 16: Thomas fighting, in five directions.** The maul: wind-up (4), strike (3, with a one-frame smear across
   the swing), recovery (4), critical overhead (10); hurt (4, the hit thrown back from the way he faces); pushed
   back (4); knocked prone (5), lying prone (2, looped), getting up (5). One sheet per direction:
   `assets/characters/thomas/dir/<dir>_mace.png`. More frames than the right-only sheets, so the swing reads as
   weight moving, not three snapshots.
3. **Job 17: normal maps** for the sheets in jobs 15 and 16: the same file name with `_n` (`s_n.png`), the same
   frames, standard OpenGL normal colours (green up). Rounded volumes (head, shoulders, coat folds), not flat.
4. Then the Drowned Miner and the Faithful get the same treatment (idle, walk, attack, hurt in five directions),
   and Garrick after them.

The current right-facing sheets stay in the game until each direction's sheet arrives, so nothing breaks in
between.
