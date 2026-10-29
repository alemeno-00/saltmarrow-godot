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

These come first because the first fight is being built next. **Please do jobs 1 to 8 (Thomas, the two enemies, gore, effects and dice) before more tiles:** the fight is playable now and needs its characters.

- [x] **1. Thomas, base body sheet** — started: concept and a standing still approved. Animate from `assets/characters/thomas/production/sprites/standing-candidate.png`.
   (`assets/characters/thomas/body.png`). Thomas from `docs/characters.md` in his dyed greatcoat and red scarf, no weapon in hand (weapons are separate layers, job 2). Rows:
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
- [ ] **2b. Thomas, mace abilities** (`assets/characters/thomas/mace_abilities.png`). Same maul as job 2; see `docs/trees.md`, Maces. Each ability has wind-up, strike and recovery. Rows:
  1. Skull Crack (8 frames: a short, fast overhead to the head)
  2. Knee Breaker (8: a low sideways swing at the legs)
  3. Shatter (9: a braced, two-handed smash into the chest)
  4. Wide Arc (10: a full spin, maul held out)
  5. Execution (12: raise high over a fallen enemy, hold, bring it down; the hold frames are for slow motion)
- [x] **3. Thomas portrait, health states** — `steady` approved (`assets/characters/thomas/production/sprites/steady-portrait-candidate.png`); hurt, badly hurt and dying still needed, drawn from the same image so the face matches.
   (`assets/portraits/thomas/`). Four separate files: `steady.png`, `hurt.png` (cut lip, bruised), `badly_hurt.png` (bloody, pale, jaw clenched), `dying.png` (grey, eyes half shut).
- [x] **4. A standard enemy: the Drowned Miner** (`assets/enemies/drowned_miner/`). A miner from the new seam, changed by working too long near the star: wet, salt-crusted, pearly eyes, a pick in both hands, moving slowly and wrong. Rows: idle (4), walk (6), attack wind-up tell (3, raising the pick high), attack (3), hurt (3), pushed back (3, stumbling backwards), slammed into a wall (3), dazed (4, swaying, looped), knocked prone (4), lying prone (2, looped), getting up (4), limping walk (6, broken leg), flee (6, stumbling away), death (6), dismembered death (6, an arm goes), skull crushed (6, for Execution).
- [x] **5. A minion: the Faithful** (`assets/enemies/faithful/`). One of Agathe's congregation, gone down too early: a thin figure in a white chapel smock and a star-metal pin, barefoot, smiling. A smaller set: idle (4), walk (6), attack (4), singing (4, looped, mouth open, head tilted back, for the Swarming Hymn), pushed back (3), knocked prone (4), death (6), skull crushed (6).
- [x] **6. Blood and gore set** (`assets/effects/gore/`). Blood pools (3 sizes), splatter (4 shapes), drag smears (2), a severed arm, a severed head, generic flesh chunks (4). All 32 × 32 so they sit on the floor.
- [x] **7. Hit effects** (`assets/effects/hits/`). A short impact flash for crushing, slashing and piercing (4 frames each, 64 × 64), and a bigger tier-3 impact (6 frames).
- [x] **7b. Mace effects** (`assets/effects/mace/`):
  - dazed: a ringing shimmer over the head (6 frames, looped, 32 × 32, no cartoon stars)
  - fracture: a sharp white crack flash at the impact point (4 frames, 32 × 32)
  - wall slam: dust and grit bursting from a wall (5 frames, 64 × 64)
  - armour pieces breaking off and clattering to the floor: a helm, a pauldron and a breastplate plate (each 6 frames, 32 × 32), plus their resting sprites
  - Wide Arc: a heavy motion smear (4 frames, 96 × 96)
- [ ] **7d. Thomas, lying prone** (`assets/characters/thomas/body.png`, add a row 9): knocked down flat on his back or side, maul fallen beside him (2 frames, looped breathing), and getting up (4 frames) as row 10. Until then the game shows the first frame of his dying crawl.
- [x] **7c. Thomas, careful step** (`assets/characters/thomas/body.png`, add a row 8): a guarded sidestep, maul held across his body (4 frames).
- [x] **8. Two d10 dice** (`assets/ui/dice/`). A ten-sided die tumbling (8 frames, 48 × 48), and its ten resting faces showing 1 to 10 as pips or marks, not numerals.
- [ ] **9. The Sewers tiles** (`assets/tiles/sewers/`). **The first level:** the old town sewers under Saltmarrow, leading down into the mines. A first version is approved (`assets/tiles/sewers/v1_0/`, see Done) but not yet drawn by the game; this job is the full set it needs. Needs tiles that a generated level can use: floors, walls in every direction and corner, water channels with banks, bridges, doors, stairs down, and props. Not a single painted background.
- [ ] **10. The Salt Pits tiles** (`assets/tiles/salt_pits/`). The second biome: old mine workings with timber props. Floor (4 variations), wall (top and face, 4 variations), wall corners, a closed and open door, shallow water (4), rubble, and a timber prop. 32 × 32 each.
- [ ] **11. The Sewers boss: Garrick, the First Shift** (`assets/enemies/garrick/`). Mara's night-shift foreman, the first man into the new seam, now a huge Drowned: broad and stooped, salt-crusted, pearl-eyed, his foreman's coat rotted to rags, a length of rusted lift chain wrapped round one arm and dragging behind, a pick in the other hand, a brass tally tag on a cord at his neck. Design: `design/quick-specs/first-shift-boss-2026-10-29.md`. **Bigger frames: 96 × 96, feet at x 48, y 88.** Rows: idle (4), walk (6, chain dragging), chain wind-up tell (3, chain swung back, held), Lift-Chain Sweep (5, a wide flat sweep), Pick and Chain (4), hurt (3), slammed into a wall (3), dazed (4, looped), knocked prone (4), lying prone (2, looped), getting up (5, slow), death (8, sinks to his knees and falls forward into the water). Plus a portrait (128 × 128) for the fight HUD.
- [ ] **12. The Outflow** (`assets/tiles/sewers/outflow/`), the boss room, 32 × 32 each: a sluice gate set in a wall, open (water pouring through, 4 frames looped) and shut; the gate shutting (4 frames); a floor square flooding over (4 frames, floor to shallow water); and the brass tally tag lying on the floor, plus a 32 × 32 item icon of it.

## Later: Thomas in full

- [ ] Thomas attacks for longswords, daggers, flails, spears and staves, each with wind-up, strike, recovery and crit rows as in job 2.
- [ ] **Thomas, longsword abilities** (`assets/characters/thomas/sword_abilities.png`). A plain longsword, held in two hands; see `docs/trees.md`, Swords. Rows:
  1. Parry (4 frames: blade up, catching the blow)
  2. Riposte (5)
  3. Opening Cut (7, a diagonal draw-cut)
  4. Half-Sword (7, left hand gripping the blade, short hard thrust)
  5. Pommel Strike (6, reversing the sword to hit with the hilt)
  6. Lunge (8, two quick steps forward into a thrust)
  7. Steel Rain (14: three strikes in a row, a cut, a thrust and a hilt blow, so the game can mix them)
- [ ] Sword effects (`assets/effects/sword/`):
  - parry spark (4 frames, 32 × 32)
  - a bleeding drip overlay for any character (6 frames, looped, 32 × 32)
  - a blood trail left on the floor by bleeding characters (3 variations, 32 × 32)
- [ ] Thomas casting poses for the Storm, Faith, Mind and Star spell schools.
- [ ] Weapon swap animations: draw and stow for each weapon type (4 frames each), and pulling something from the bag (6).
- [ ] Star casting in three strengths: Hushed (faint glow), Open, and Unbound (light pouring out of Thomas, salt crystals forming on him). 6 frames each.
- [ ] Thomas portrait and body overlay: arm turned to salt crystal (a Star's Reach injury).
- [ ] Armour and clothing as layers over every frame of the base body (head, body, hands, legs, feet, cloak). **This is the biggest job on the list;** we'll decide how far to take it after the first fight.
- [ ] Portraits: in pain, Dread rising, bandaged head, swollen eye, arm in a sling, each Mark of the star, and one for each of the five backstories (Fury, Shadow, Elementalist, Censor, Talent).

- [ ] **Thomas, dagger abilities** (`assets/characters/thomas/dagger_abilities.png`). A dagger in each hand; see `docs/trees.md`, Daggers. Rows:
  1. twin stab (6 frames)
  2. Backstab (7)
  3. Open the Vein (6, a quick slash at the wrist or thigh)
  4. Throw (5)
  5. Study the Mark (4, crouched and still, eyes on the target; looped)
  6. Cut the Straps (6, crouched behind someone, sawing)
  7. Tripwire (8, kneeling and tying off a wire)
  8. Whisper (8, from behind: hand over the mouth, a pommel blow to the temple)
- [ ] Dagger props and effects (`assets/effects/dagger/`), each 32 × 32:
  - a thrown dagger spinning (4 frames)
  - a dagger lying on the floor
  - a tripwire strung across a square, seen from above, plus a snapped one
  - a lantern or brazier going out (6 frames)
  - a clatter: a small spark and dust where a dagger hits stone (4 frames)
- [ ] **Thomas, staff abilities** (`assets/characters/thomas/staff_abilities.png`). A plain wooden quarterstaff held in two hands; see `docs/trees.md`, Staves. Rows:
  1. Block (4 frames)
  2. Sweep (6, a low swing at the legs)
  3. Hold at Bay (5, a hard jab with the end of the staff)
  4. Vault (8, planting the staff and swinging over)
  5. Spellstrike (8, a strike that ends with light bursting from the head of the staff)
  6. Conduit (8, staff raised, power gathering in it)
- [ ] Casting with one hand while holding a weapon in the other, for each spell school. Spells don't need a staff, so sword-and-spell builds will use this.
- [ ] Staff effects (`assets/effects/staff/`):
  - a block impact (4 frames, 32 × 32)
  - a staff head glowing with each school's colour (Storm, Faith, Mind, Star; 4 frames each, looped, 32 × 32)
  - Grounded Staff: Star backlash crackling down the staff into the floor (6 frames, 64 × 64)
- [ ] Storm spell effects (`assets/effects/storm/`); see `docs/trees.md`, Storm:
  - Spark bolt (4 frames, 64 × 32)
  - Gust cone (6 frames, 96 × 96)
  - Frost Grip, ice climbing a target's legs (6 frames, 64 × 64), plus a frozen-in-place overlay (looped)
  - Chain Lightning arcs between targets (6 frames, made to stretch)
  - ice tiles: water frozen over (4 variations, 32 × 32), plus thawing (4 frames)
  - Thunderclap ring (6 frames, 96 × 96)
  - Rime Coat, ice armour over Thomas (looped overlay, 64 × 64)
  - Tempest storm over a 3×3 area (10 frames, 96 × 96)
  - electrified water tiles (4 frames, looped, 32 × 32)
  - a wet sheen overlay for wet characters (looped, 64 × 64)
  - lightning, cold and burn hurt overlays for any character (4 frames each, 64 × 64)
- [ ] Faith spell effects (`assets/effects/faith/`); see `docs/trees.md`, Faith. Warm, pale gold light, the old church's colour, never pearly (pearl is the star's):
  - Rebuke (4 frames, 64 × 32)
  - Mend glow over Thomas (6 frames, 64 × 64)
  - Smite: a weapon wreathed in light, then a burst on impact (6 frames, 64 × 64)
  - Hallowed Ground tiles, faint glowing marks on the floor (4 frames, looped, 32 × 32)
  - Bind: chains of light (6 frames to form, then looped, 64 × 64)
  - Confession: dark smoke passing from Thomas's hand into an enemy (6 frames, 64 × 64)
  - the Old Bell: a ghostly bell and ring of sound (10 frames, 128 × 128)
  - Release: a star-touched body crumbling into salt (8 frames, 64 × 64)
  - a frightened enemy cowering and fleeing (6 frames, for every enemy)
- [ ] Mind spell effects (`assets/effects/mind/`); see `docs/trees.md`, Mind. A cold violet shimmer, distorted rather than bright:
  - Mind Spike (4 frames, 64 × 32), plus its echo jumping between Hollow Faith
  - Unseen Hand: a faint distortion gripping a target (6 frames, 64 × 64)
  - Read Intent: a faint ghost-image of each enemy's next move (looped, 64 × 64)
  - Veil: Thomas fading to a heat-haze outline (6 frames, then looped)
  - Phantom: a flickering illusory Thomas (looped), and it shattering when hit (6 frames)
  - Turncoat: eyes clouding, turning on allies (overlay, 6 frames)
  - Nightmare: a 3×3 area of shadowy shapes (10 frames, 96 × 96)
- [ ] Mind reactions for each faction:
  - the Faithful waking from the hymn: confusion, then running (8 frames)
  - Hollow Faith frozen rigid in place (looped)
  - the Drowned sinking into water (6 frames) and resurfacing (6 frames)
  - Carrion Brood frenzy (6 frames, looped)
  - confused, stumbling (6 frames, for every enemy)
- [ ] Star spell effects (`assets/effects/star/`); see `docs/trees.md`, the Star. Pearl-white light, salt, seawater:
  - Pearl Ray (4 frames, 64 × 32)
  - Warp Step: Thomas vanishing and reappearing (6 frames each), and the ring of salt left behind (32 × 32)
  - Crystallise: salt creeping over a limb (8 frames, 64 × 64), and a crystallised arm or leg overlay for any character
  - Fold: two figures swapping in a twist of light (8 frames, 64 × 64)
  - the Tide Below: seawater welling up through the floor (8 frames), deep-water tiles (4, looped), draining (6), 32 × 32
  - Starfall: a falling shard and its impact (12 frames, 128 × 128), and salt-crystal floor tiles (4 variations, 32 × 32)
- [ ] **The Called** (`assets/enemies/called/`): the thing that comes through for the Call spell and the Star's Reach. Not quite a body: a tall, wrong shape of pearl light and wet salt, too many joints, no face. Rows: arrive through a tear (8), idle (4), walk (6), attack (5), fade away (8).
- [ ] **Thomas changing with the Star.** Overlays for every frame of his body sheet and for every portrait:
  - stage 1: pearl eyes
  - stage 2: plus faint light under the skin at the throat and hands
  - stage 3: plus salt crystals at his cuffs and hair, and pearl breath (a small looped mist)
- [ ] Townsfolk reactions to a changed Thomas: a second portrait for Agathe (delighted), Nell (afraid), Rook (calculating), Bram (uneasy) and Mara (turning away). Also a few townsfolk following him at a distance (map sprites, walk 6 and idle 4).
- [ ] Stealth reactions for every enemy (start with the Drowned Miner and the Faithful):
  - slumping unconscious (5 frames)
  - lying unconscious (2, looped)
  - waking (4)
  - wandering off to investigate (6, head turned, uneasy)
  - tripping on a wire (5)
  - armour falling away as cut straps give (4)
  - an alerted start (3, the moment it spots Thomas)

## Later: the world

- [ ] Every enemy type, each with the rows from job 4, and a smaller set for minions.
- [ ] Severed parts for each enemy type.
- [ ] Star Phenomena effects (`assets/effects/star/`): salt frost spreading across floor tiles (6 frames, 32 × 32), lights guttering, a lagging shadow, a salt-water nosebleed on the portrait, and a tear in the air where something comes through (8 frames, 64 × 64).
- [ ] Telegraph marks: the darkened-square effect under incoming big attacks.
- [ ] An icon for every weapon, armour piece and consumable (list to follow).
- [ ] **Skill icons** (`assets/ui/skills/<tree>/<node>.png`, 32 × 32): one for every node in `docs/trees.md`, starting with the ten Maces nodes (`skull_crack.png`, `weight_behind_it.png`, `knee_breaker.png`, `shatter.png`, `bone_deep.png`, `wide_arc.png`, `ringing_blows.png`, `sunder.png`, `execution.png`, `hammers_due.png`), plus `heavy_blow.png`. They go on the ability bar and the skill tree screen.
- [ ] Level-up and mastery-point moments: a short glow rising off Thomas (8 frames, 64 × 64).
- [ ] Skill tree screen frame (`assets/ui/skill_tree/`): a panel background, node frames in four states (learned, can learn, locked, not yet in the game), and the link lines.
- [ ] The cast of Saltmarrow: a portrait and a map sprite for each person in `docs/characters.md`.
- [ ] Tiles for the Forgotten Catacombs, the Blooming Deep and the under-sea tunnels.
- [ ] The Saltmarrow town hub.

## Done

- **Thomas concept sheet, five backstory costumes, a standing still and a steady portrait** (`assets/characters/thomas/production/`). Approved by Julian. The standing still and the portrait are in the game now. Jobs 1 and 3 continue from these: the animated body sheet and the other three portrait states.
- **Sewer tiles, first version** (`assets/tiles/sewers/v1_0/`). Approved; not yet drawn by the game, which needs the full set in job 9.
- **Biome layout guide and camera concept** (`assets/docs/`). Approved as reference.
- **Archive of earlier art** (`assets/reference/saltmarrow-deep/`). Approved as reference.
