# Thomas Wren

| File | Frame / canvas size | Rows and frame counts | Facing |
| --- | --- | --- | --- |
| body.png | 64×64 / 384×512 | 1 idle 4; 2 walk 6; 3 sneak 6; 4 hurt 3; 5 wounded walk 6; 6 dying crawl 6; 7 death 6; 8 careful step 4 | Right |

Root is (32,56) in every frame; ground contact is the pixel row y55. Frames run left to right, no gaps, shorter rows have transparent trailing cells. Death is non-looping and its final frame holds. Suggested playback: idle 4 fps, walk 8, sneak 6, hurt 10, wounded walk 6, dying crawl 5, death 7.

`production/body-v2/` contains generated masters, export source, validation and nearest-neighbour animation previews. `production/animation-review/` is the rejected first study, retained for provenance; use body-v2 instead. Other production folders contain prior approved references and planning documents.

Claude integration: select only each row's populated count, do not include empty trailing cells. Row8 careful step has4 frames with the maul held across the body; see production/careful-step/. Weapon attack sheets remain separate. Use nearest texture filtering, no mipmaps, no smoothing. No code changes are included here.
