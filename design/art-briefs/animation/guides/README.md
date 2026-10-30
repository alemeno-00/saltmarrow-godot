# Pose guides

Made by `tools/pose_guides/pose_guides.gd` (Claude). For ChatGPT: paint the character over these, frame by frame.

**Why:** an image generator draws each frame as a new picture and can't keep track of which leg is which, so walks
come out as the same pose drawn again and again (Julian, 2026-10-30: "it's struggling to generate sprites that show
using left and right legs"). These guides settle every pose, the way the room blockouts settle every room. You only
paint; the poses are given.

## What is in a guide

- **Left leg red, right leg blue. Left arm orange, right arm cyan.** The side away from the camera is darker. The
  colours tell you, in every frame, which leg is which and which is in front.
- **Grey**: hips, shoulders and spine. **Pale circle**: the head; a dark dot on it is the nose (none when he faces
  away).
- **White marks on the ground**: where a planted foot stays. A planted foot must not move off its mark.
- **The grey ellipse**: where his shadow falls (the game draws the real shadow; don't paint it).
- Drawn from the rooms' camera (house style rule 9), feet at x 40, y 72 of each 80 × 80 frame, about 1.5 squares tall.

## The files

| File | Frames | What |
| --- | --- | --- |
| `walk_<dir>.png` | 8 | A walk cycle: 1 left heel down, 2 down (weight on the left), 3 passing (right swings by), 4 up, 5 right heel down, 6 down, 7 passing, 8 up |
| `idle_<dir>.png` | 6 | Standing, breathing: the chest and head rise and fall, the feet stay put |
| `*_4x.png` | | The same, four times larger, to read the poses |

`<dir>` is `s`, `se`, `e`, `ne`, `n`. The game mirrors SE, E and NE for the west side.

## How to use them

1. **One frame at a time.** Give the generator the guide frame (the 4 × one) and Thomas's approved reference
   (`assets/characters/thomas/production/sprites/standing-candidate.png`), and ask it to paint Thomas in exactly that
   pose: the red leg is his left, the blue his right. Then the next frame. Don't ask for a whole strip at once.
2. **Keep the limbs where the guide puts them**, especially the feet and knees: that is what makes the steps read.
   Clothes, the coat's swing and the scarf are yours to add on top (the coat hem and scarf lag a frame behind).
3. **Check each frame against its guide**: lay the guide over your frame. The feet should sit on the guide's feet,
   the knees near the guide's knees. If two frames in a row look alike, one of them is off its guide.
4. Remove the guide colours entirely in the finished frame.

If a direction or an animation needs a guide that isn't here (a sneak, attacks, getting hurt), say so in your pull
request and Claude will make it.
