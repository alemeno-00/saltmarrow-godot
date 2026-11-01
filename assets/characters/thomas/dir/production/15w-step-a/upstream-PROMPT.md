# Thomas, south walk: the prompt (ART_JOBS 15-W)

Thomas walks towards the camera. Paint his walk in the look of the **first painted sprites**: hand-painted pixel art,
the approved model's colours and detail (`assets/characters/thomas/rig/production/model-s.png`), the house style. His
**whole body moves**: legs stepping, arms swinging against the legs, the body rising and falling, the coat swaying.

**How, for every frame:**

1. Open that frame of `guide_walk_s_4x.png` (320 × 320 a frame, 4 × the game's size). It is Thomas already in the
   pose, made from the approved model's own pieces: every limb is where it must be, but rough where pieces turned.
2. **Paint the frame over it at 4 ×,** as a clean painting of Thomas in exactly that pose: same outline, same
   positions of the feet, hands, head and coat hem (within a pixel of the game's size, so 4 px at this size). Fix
   every rough edge, doubled pixel and gap; make the folds of the coat follow the step.
3. **Keep him the approved Thomas:** the same face and hair, the red scarf, the strap, satchel and lantern, the long
   warm dark-brown coat. Paint **the head as in the model**: it barely changes between frames.
4. **Left and right never swap.** In `key_walk_s_4x.png` his LEFT leg is red and LEFT arm orange, his RIGHT leg blue
   and RIGHT arm cyan. Facing us, his left is on the picture's **right**. Each arm swings with the opposite leg.
5. Paint each frame as **its own edit**, starting from its guide, never from the frame before (that is how the walk
   drifted last time).
6. Paint on a transparent background, 4 × 4 screen pixels for every game pixel, colours from the model. Then the
   normal map the same way, over `guide_walk_s_n_4x.png`.

**In two steps:**

- **Step A, the key frames: 1, 3, 5, 7.** Each foot down, and each passing. Deliver them for Julian to approve before
  anything else.
- **Step B, the in-between frames** (the others), each between two approved key frames.

**Then:** put the eight 4 × frames in one row (2560 × 320) as `assets/characters/thomas/dir/production/walk_s_4x.png`
(and `walk_s_n_4x.png`), and shrink them to the game's size with the tool, which snaps every pixel to the model's colours:
`godot --headless --path . -s tools/pose_guides/walk_guides.gd -- shrink <walk_s_4x.png> <walk_s.png>` (add `normal`
for the normal map). Make `assets/characters/thomas/dir/s.png` (640 × 160): row 1, six copies of the approved model
(standing), row 2, the eight shrunk walk frames; `s_n.png` the same. Then
`godot --headless --path . -s tools/pose_guides/walk_guides.gd -- check res://assets/characters/thomas/dir/s.png`
must print PASS: the outline within reach of the guide's, each foot on its own side and height, the head his own.

## The frames

**Frame 1 (key frame).** Compared with standing, his body is 1 px lower. His LEFT side (red leg, orange arm, on the picture's right): foot planted 6 px ahead, sole flat on the floor at row 74; arm swung back. His RIGHT side (blue leg, cyan arm, on the picture's left): foot planted 6 px behind, sole flat on the floor at row 71; arm swung forward.

**Frame 2.** Compared with standing, his body is 1 px lower and 1 px further to the picture's right. His LEFT side (red leg, orange arm, on the picture's right): foot planted 3 px ahead, sole flat on the floor at row 74; arm hanging straight. His RIGHT side (blue leg, cyan arm, on the picture's left): foot lifted 2 px and swinging forward, 4 px behind, sole at row 74; arm swung forward.

**Frame 3 (key frame).** Compared with standing, his body is 1 px lower and 1 px further to the picture's right. His LEFT side (red leg, orange arm, on the picture's right): foot planted under him, sole flat on the floor at row 72; arm hanging straight. His RIGHT side (blue leg, cyan arm, on the picture's left): foot lifted 3 px and swinging forward, under him, sole at row 74; arm hanging straight.

**Frame 4.** Compared with standing, his body is 1 px further to the picture's right. His LEFT side (red leg, orange arm, on the picture's right): foot planted 3 px behind, sole flat on the floor at row 70; arm swung forward. His RIGHT side (blue leg, cyan arm, on the picture's left): foot lifted 2 px and swinging forward, 4 px ahead, sole at row 73; arm hanging straight.

**Frame 5 (key frame).** Compared with standing, his body is 1 px lower. His LEFT side (red leg, orange arm, on the picture's right): foot planted 6 px behind, sole flat on the floor at row 71; arm swung forward. His RIGHT side (blue leg, cyan arm, on the picture's left): foot planted 6 px ahead, sole flat on the floor at row 74; arm swung back.

**Frame 6.** Compared with standing, his body is 1 px lower and 1 px further to the picture's left. His LEFT side (red leg, orange arm, on the picture's right): foot lifted 2 px and swinging forward, 4 px behind, sole at row 74; arm swung forward. His RIGHT side (blue leg, cyan arm, on the picture's left): foot planted 3 px ahead, sole flat on the floor at row 74; arm hanging straight.

**Frame 7 (key frame).** Compared with standing, his body is 1 px lower and 1 px further to the picture's left. His LEFT side (red leg, orange arm, on the picture's right): foot lifted 3 px and swinging forward, under him, sole at row 74; arm hanging straight. His RIGHT side (blue leg, cyan arm, on the picture's left): foot planted under him, sole flat on the floor at row 72; arm hanging straight.

**Frame 8.** Compared with standing, his body is 1 px further to the picture's left. His LEFT side (red leg, orange arm, on the picture's right): foot lifted 2 px and swinging forward, 4 px ahead, sole at row 73; arm hanging straight. His RIGHT side (blue leg, cyan arm, on the picture's left): foot planted 3 px behind, sole flat on the floor at row 70; arm swung forward.

