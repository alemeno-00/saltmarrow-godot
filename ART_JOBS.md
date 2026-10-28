# Art jobs

The list of art the game needs, in priority order. **Claude keeps this list up to date as the design grows; ChatGPT works through it.**

How to use it:

- Take the highest job that isn't done. Deliver it as a pull request into `assets/` (see `AGENTS.md`), and tick its box in the same pull request.
- If a job is unclear or too big, say so in the pull request rather than guessing. Claude will split or clarify it.
- The story and look of every character are in `docs/characters.md`; the world and tone in `docs/story.md`.

## Standard sizes (every job uses these unless it says otherwise)

| Thing | Size | Notes |
| --- | --- | --- |
| Map square | 32 × 32 px | Floor, wall and prop tiles are drawn to this grid. |
| Character frame | 64 × 64 px | One character per frame, standing on the bottom-centre square. Feet at **x 32, y 56** in every frame. |
| Facing | Right only | The game mirrors sprites to face left. Draw everything facing right. |
| Sprite sheet | One row per animation | Frames left to right, all the same size, no gaps. A `README.md` beside it lists rows and frame counts. |
| Portrait | 128 × 128 px | Chest up, facing three-quarters right. |
| Item icon | 32 × 32 px | On transparent background, with a 1 px dark outline. |
| Style | Pixel art | Hard edges, no smoothing, no anti-aliasing, no text in images. |
| Palette | Cold slate, charcoal, wet browns | Small warm amber lights. Blood is dark red, never bright pink. |

## Now: the first playable fight

These come first because the first fight is being built next.

- [ ] **1. Thomas, base body sheet** (`assets/characters/thomas/body.png`). Thomas from `docs/characters.md` in his dyed greatcoat and red scarf, no weapon in hand (weapons are separate layers, job 2). Rows:
  1. idle (4 frames, slow breathing)
  2. walk (6)
  3. sneak (6, crouched)
  4. hurt (3, flinch back)
  5. wounded walk (6, limping, clutching his side)
  6. dying crawl (6, on the ground, dragging himself)
  7. death (6, ends lying still; last frame holds)
- [ ] **2. Thomas, mace attack** (`assets/characters/thomas/attack_mace.png`). Holding a heavy maul. Rows:
  1. wind-up (3 frames, the frame before impact readable as a threat)
  2. strike (3)
  3. recovery (3)
  4. crit strike (8, a bigger, slower overhead blow for slow motion)
- [ ] **3. Thomas portrait, health states** (`assets/portraits/thomas/`). Four separate files: `steady.png`, `hurt.png` (cut lip, bruised), `badly_hurt.png` (bloody, pale, jaw clenched), `dying.png` (grey, eyes half shut).
- [ ] **4. A standard enemy: the Drowned Miner** (`assets/enemies/drowned_miner/`). A miner from the new seam, changed by working too long near the star: wet, salt-crusted, pearly eyes, a pick in both hands, moving slowly and wrong. Rows: idle (4), walk (6), attack wind-up tell (3, raising the pick high), attack (3), hurt (3), flee (6, stumbling away), death (6), dismembered death (6, an arm goes).
- [ ] **5. A minion: the Faithful** (`assets/enemies/faithful/`). One of Agathe's congregation, gone down too early: a thin figure in a white chapel smock and a star-metal pin, barefoot, smiling. A smaller set: idle (4), walk (6), attack (4), death (6).
- [ ] **6. Blood and gore set** (`assets/effects/gore/`). Blood pools (3 sizes), splatter (4 shapes), drag smears (2), a severed arm, a severed head, generic flesh chunks (4). All 32 × 32 so they sit on the floor.
- [ ] **7. Hit effects** (`assets/effects/hits/`). A short impact flash for crushing, slashing and piercing (4 frames each, 64 × 64), and a bigger tier-3 impact (6 frames).
- [ ] **8. Two d10 dice** (`assets/ui/dice/`). A ten-sided die tumbling (8 frames, 48 × 48), and its ten resting faces showing 1 to 10 as pips or marks, not numerals.
- [ ] **9. The Salt Pits tiles** (`assets/tiles/salt_pits/`). The first biome: old mine workings with timber props. Floor (4 variations), wall (top and face, 4 variations), wall corners, a closed and open door, shallow water (4), rubble, and a timber prop. 32 × 32 each.

## Later: Thomas in full

- [ ] Thomas attacks for blades, daggers, flails, spears and staves, each with wind-up, strike, recovery and crit rows as in job 2.
- [ ] Thomas casting poses for the Storm, Faith, Mind and Star spell schools.
- [ ] Weapon swap animations: draw and stow for each weapon type (4 frames each), and pulling something from the bag (6).
- [ ] Star casting in three strengths: Hushed (faint glow), Open, and Unbound (light pouring out of Thomas, salt crystals forming on him). 6 frames each.
- [ ] Thomas portrait and body overlay: arm turned to salt crystal (a Star's Reach injury).
- [ ] Armour and clothing as layers over every frame of the base body (head, body, hands, legs, feet, cloak). **This is the biggest job on the list;** we'll decide how far to take it after the first fight.
- [ ] Portraits: in pain, Dread rising, bandaged head, swollen eye, arm in a sling, each Mark of the star, and one for each of the five backstories (Fury, Shadow, Elementalist, Censor, Talent).

## Later: the world

- [ ] Every enemy type, each with the rows from job 4, and a smaller set for minions.
- [ ] Severed parts for each enemy type.
- [ ] Star Phenomena effects (`assets/effects/star/`): salt frost spreading across floor tiles (6 frames, 32 × 32), lights guttering, a lagging shadow, a salt-water nosebleed on the portrait, and a tear in the air where something comes through (8 frames, 64 × 64).
- [ ] Telegraph marks: the darkened-square effect under incoming big attacks.
- [ ] An icon for every weapon, armour piece and consumable (list to follow).
- [ ] The cast of Saltmarrow: a portrait and a map sprite for each person in `docs/characters.md`.
- [ ] Tiles for the Forgotten Catacombs, the Blooming Deep and the under-sea tunnels.
- [ ] The Saltmarrow town hub.

## Done

Nothing yet.
