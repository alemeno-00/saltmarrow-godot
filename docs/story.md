# Story and design foundation

What has been agreed so far. Claude keeps this file in step with the shared design doc.

## The hook

- A star fell into the sea beside **Saltmarrow**, a cliff town whose mines run out under the seabed. The next morning the miners broke into a seam that hadn't been there before.
- Strangers began arriving, saying they came for work or the black **star-metal**. Really they all dreamed the same dream: a cliff, a lift, a bell, a light under the water.
- **Thomas Wren** comes home from a long, unnamed war (swords and spells, no guns) to an empty house and the letters of his sister **Ellen**. She was ill, dreamed of a place she'd never heard of, and went to Saltmarrow to be healed by its chapel. Her letters grew happier and stranger, then stopped. She is now inside the star's light.
- Tone: Lovecraftian and quiet. Ordinary people who look fine until you look twice.

## The cult

- There is one cult, hidden inside the chapel. **Sister Agathe** prayed for forty years for God to show his face; the star fell and something under the sea answered. Nothing lies to her: the miracles are real. She is right about the power and wrong about what it is, and she is sincere.
- She heals the dreaming travellers and gently teaches them the star's hymns until they want to go down.
- Anyone near the star long enough changes, the faithful and the miners alike. The factions below are what they became: the **Hollow Faith** emptied themselves for it, the **Carrion Brood** could not and grew hungry, the **Drowned** went furthest, out under the sea where it fell.
- Mayor Hale takes the money and looks away. Mara notices her miners aren't coming back. Pip joins the chapel and goes down.

## Death and the warping star

- The star warps reality. That is why the tunnels change, why Thomas comes back from death, and why he is a slightly different man each time.
- On death he wakes on the chapel floor and the player chooses his war backstory for this life. Ellen's letters and the townsfolk's memories reword themselves to match. Agathe alone notices, and is delighted.
- Death wipes the world: new layouts, landings and contracts. The story so far, the Marks of the star and the town's memory carry over.

## Gameplay

- **Fights:** Draw Steel rules (2d10 power rolls with three tiers, move/maneuver/main action, heroic resource, free strikes, forced movement, conditions, Recoveries, Victories).
- **Growth:** Stoneshard skill trees, one per weapon type and spell school (Storm, Faith, Mind, and the forbidden Star), plus Stealth, Survival and Warfare. Trees open by finding manuals and tomes.
- **Backstories** are head starts: Fury (maces, Warfare), Shadow (daggers, Stealth), Elementalist (staves, Storm), Censor (flails, Faith), Talent (Mind, Survival).
- **Survival:** full Stoneshard: hunger, thirst, fatigue, pain, sickness, injuries, Dread.

## The loop

- Take contracts in town, buy supplies, go down as an expedition. Walk back up, or reach an old **shaft landing** and ride the lift. Landings stay open for this life.
- While Thomas lives, levels stay as he left them. Death regenerates everything.
- Removed: lift-bells, guild training, Draw Steel kits.

## Combat feel

- Draw Steel turns on the same map; being spotted freezes the world into turns, ambushes give a free turn, breaking sight can end a fight.
- Crits are heavy and dramatic (push-in, slow motion, freeze, scream); everything else grounded and punchy. **Uncompromisingly graphic**: severed limbs, wounds, blood and bodies stay. **No floating numbers.**
- Attrition: ordinary fights cost something; elites, packs and bosses kill. At 0 stamina Thomas is dying, not dead.
- Health shows on his portrait's face and his sprite, not as numbers.
- Tier 3 hits can injure or sever body parts. Pain adds banes.
- Minion squads, standard enemies, leaders and solos; the enemy side spends Draw Steel malice.
- Only big attacks are telegraphed, by body language and darkened squares. Ability cards show all three tiers. The dice roll shows briefly, bigger on crits.
- Fleeing costs a free strike; enemies chase and can lose you; wounded enemies flee and return with others.

## Items

- Weapons per skill tree, with damage type, quality, properties and durability; star-metal weapons are strongest and cost Dread or Marks.
- Armour by slot with protection by damage type, weight, noise and wear.
- Food, water, medicine, light, tools, throwables, manuals and tomes. The bag grid limits space; weight limits speed.
- Town services: Tobias (weapons, repair), Nell (medicine, injuries), Bram (food, water), Rook (star-metal, rarities), Agathe (identifies strange things).

## Skills, weapons and spells

- **Weapons give the basic attack.** Each weapon type has its own free strike.
- **Trees give abilities.** Each tree has about 10 nodes, half abilities and half passives. Abilities are Draw Steel power rolls: 2d10 + a stat, with three tiers.
- **Weapon abilities need that weapon in hand.**
- **Trees open by finding their manual or tome.**
- **Levels:** 1 tree point per level, and a stat point every few levels. The stats are Might, Agility, Reason, Intuition and Presence.
- **Weapon trees:** Maces, Swords (the longsword), Daggers, Flails, Spears, Staves.
- **Spell schools:**
  - Storm (Reason), Faith (Presence) and Mind (Intuition) are **safe**.
  - Star is the only dangerous school.
- **Other trees:** Stealth, Survival, Warfare.
- Tree details are in `docs/trees.md`.
- **Resolve** is the one resource. You gain it each turn of a fight, spend it on bigger abilities and spells, and it empties after the fight.

### Earning extra Resolve

You earn it two ways:

- **Your backstory** gives one trigger for that life.
- **Each tree's capstone** (its deepest node) adds another. Reaching more capstones means more ways to earn Resolve.

| Backstory | Extra Resolve when you... |
| --- | --- |
| Fury | are hurt |
| Shadow | strike an enemy that can't see you |
| Elementalist | hit two or more enemies with one ability |
| Censor | are hurt by an enemy, or an enemy hurts someone near you |
| Talent | make an enemy fail against you (a missed attack, or a resisted spell) |

| Tree capstone | Extra Resolve when you... |
| --- | --- |
| Maces | fracture a bone, break armour, or push an enemy into something |
| Swords | parry or riposte |
| Daggers | land a crit |
| Flails | hit an enemy behind a shield or in cover |
| Spears | strike an enemy as it moves into your reach |
| Staves | block a hit |
| Storm | push an enemy into something |
| Faith | heal or ward |
| Mind | frighten an enemy |
| Star | cause a Star Phenomenon |
| Stealth | start a fight unseen |
| Survival | end your turn bleeding, poisoned or hungry |
| Warfare | are surrounded by two or more enemies |

### Swapping weapons

- Two weapons are ready: one in hand, one on the belt or back. Swapping between them costs your **maneuver**.
- Taking a weapon out of the bag costs your **main action**.
- Dropping a weapon is free; it lands on the floor.
- The Warfare node **Quick Hands** makes the first swap of each fight free.

### The Star school (after Dark Heresy's psykers)

- **Attunement** rises with points in the Star tree, and sets the power of Star spells.
- Choose how to cast each spell, before rolling:

| Mode | Power | Risk |
| --- | --- | --- |
| Hushed | Half Attunement; best result is tier 2 | No phenomena; costs 1 Dread |
| Open | Full Attunement | Doubles on the 2d10 cause a Star Phenomenon |
| Unbound | Attunement +2, and the result moves up one tier | Always causes a phenomenon, rolled with a bonus; costs 2 Dread |

- **Star Phenomena:** roll d100 and add current Dread.
  - Low results are eerie and mostly harmless: salt frost spreading, lights guttering, your shadow moving late, Ellen humming, the Faithful turning toward you, a salt-water nosebleed.
  - High results reach the **Star's Reach**:
    - the spell hits the wrong target or spreads
    - Thomas is pulled to a random nearby square
    - something comes through
    - Agathe feels it and the level becomes alert
    - an arm turns to salt crystal (a lasting injury)
    - a permanent **Mark**
    - at the very top, death
