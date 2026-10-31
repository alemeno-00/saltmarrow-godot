# Backlog: jobs for later

Asked for by Julian, 2026-10-30. Each job is design and code work for Claude (with Julian deciding) unless it
says otherwise; art goes to ChatGPT through `ART_JOBS.md` as each job is designed. The build order for what comes
first is in `design/game-brief.md`; these come after it, roughly in the order a player would meet them. Each job
starts with a quick spec or a GDD section for Julian to approve.

## Fighting and growing

1. **Refine the skill trees.** *Now:* Maces and Daggers are built; Swords, Flails, Spears, Staves, the spell schools
   and Stealth, Survival and Warfare are designed in `docs/trees.md` but not built, and Stealth has no nodes yet.
   *Job:* balance costs and tiers from playtests, finish part 3 of Daggers (Study the Mark, Tripwire, Whisper), write
   the Stealth tree, decide how each tree earns mastery (hits for both now; `docs/story.md` suggests crits for
   Daggers), and the hidden pairings between trees.
2. **Refine level-up requirements and what earns experience.** *Now:* experience comes only from kills (1 a minion,
   4 a standard enemy, 10 a boss); level n needs 5 × n × (n + 1) / 2; a stat point every third level. *Job:* reward
   the other ways of playing (slipping past a band unseen, lore found, quests, talking an encounter down), so a
   sneaking or talking life grows as fast as a fighting one; tune the curve against a full run.
3. **Refine weapons.** *Now:* the maul and daggers. *Job:* the other weapon types from `docs/trees.md`, damage types
   (crushing, slashing, piercing) and what they do to armour and injuries, weapon swapping, and finding weapons and
   their manuals in the deep.
4. **Refine magic.** *Now:* none built. *Job:* the Storm, Faith, Mind and Star schools from `docs/trees.md`, finding
   their tomes, casting in fights in metres (areas as shapes), the Star's phenomena and Marks, and how magic sits
   with sneaking (Mind's Veil) and talking.
5. **Refine the boss fights.** *Now:* Garrick, the First Shift, at the bottom of the Sewers
   (`design/quick-specs/first-shift-boss-2026-10-29.md`), moved to fights in metres. *Job:* tune him from playtests
   (his sweep band, the flooding, the gates), talking to him before the fight (`design/quick-specs/dialogue-2026-10-30.md`),
   a sneaking approach to his room, and a boss for each later biome.
6. **Refine death.** *Now:* dying is a state you can be pulled back from; dead ends the run and wipes everything but
   the journal (planned). *Job:* the death screen, what (if anything) carries over between lives besides the journal
   and the echoes, how death sits in the star's story (each life a rewriting), and how harsh it should feel.

## Exploring

7. **Refine sneaking.** *Now:* parts 1 and 2 and cover are built (`design/quick-specs/sneaking-2026-10-30.md`). *Job:*
   tune the spotting meter, noise and cones from playtests; part 3 (hiding mid-fight, the dagger preparations);
   steering patrol routes past cover for ambushes; the lantern and the dark (oil, what darkness does to Thomas,
   still to spec); the deep sewage tunnels' lurkers.
7b. **Rethink the Shadow as a skirmisher, not a hider** (Julian, 2026-10-30: "sneaking shouldn't just be hiding;
   hard to balance bosses based on this. Instead they should be good at kiting, escaping, hit and run tactics.
   Maybe reflavour the backstory to commando or guerrilla or something like that, and also have traps.") *Now:*
   the Shadow's Backstab and extra Resolve need an enemy that can't see him, which a boss fight takes away. *Ideas
   discussed (none decided):*
   - "Can't see you" becomes positional: enemies face the way they last moved or attacked, and behind their
     shoulders counts as out of sight, even for a boss, so the build circles rather than hides.
   - Hit and run built in: speed 6, a free 1.5 m step after a dagger attack that draws no free strikes, a 3 m
     careful step.
   - Kiting tools: Throw with daggers to pick up again, bleeding, a new Hamstring (slows) and Tumble (move through
     enemies' spaces without free strikes).
   - Escaping well: losing pursuers after one round out of sight instead of two.
   - **Traps** as a core part of the kit, not an extra: tripwires, snares and caltrops laid before or during a
     fight, so the build wins by choosing the ground.
   - **A new name and story** for the backstory: a commando or guerrilla fighter from the war rather than an
     assassin; the Daggers tree and Ellen's letters reflavoured to match.
   *Job:* decide the shape with Julian, rewrite the Daggers section of `docs/trees.md` and the sneaking spec, then
   rebuild what part 2 built.
8. **Refine items.** *Now:* the belt items, caches and puzzles are designed (`design/quick-specs/room-contents-2026-10-30.md`)
   and the art is delivered, but none are built. *Job:* build them, then lantern oil, armour (which Shatter, Sunder and
   Cut the Straps wait for), what is worth carrying, and whether the bag grid comes in.
9. **Expand on the hub.** *Now:* the town of Saltmarrow is out of scope (`design/game-brief.md`); the cast is in
   `docs/characters.md`. *Job:* first the smallest version (a stop at the surface between lives, a few people to talk
   to), then the town proper: shops, Nell's herbs, Tobias's forge, Bram's tavern rumours, Rook's smuggling, Mara's
   ledger, Agathe's chapel, and contracts to take down.

## Story and people

10. **Refine the story.** *Now:* `docs/story.md`; the Sewers boss ends the first version, Ellen is saved for the full
    game; the lore texts are in the game (`scripts/data/lore.gd`: Ellen's letters, the tally tags, chapel hymns),
    approved as drafts. *Job:* the acts, how the star's rewriting shows from life to life, how a run ends, and the
    full game's ending with Ellen. Julian, 2026-10-31: extend the chapel's lore (more hymns, notices, Agathe's notes)
    into a rich story to find; workshop Ellen's letters, especially how the Fury and Shadow versions show the
    relationship.
11. **Review all dialogue and the dialogue trees.** *Now:* talking is a proposal (`design/quick-specs/dialogue-2026-10-30.md`);
    no lines are written. *Job:* write the first four encounter types and their variants for review, the data format
    for branching conversations, the tests a choice can call for, and a pass over every line for voice and
    consistency with the cast.
12. **Write and expand quests.** *Now:* none. *Job:* quests that come out of encounters (carry a message to Mara, see
    a survivor out, find a named miner), contracts from the town, a quest log in the journal, and how quests change
    when the star rewrites people between lives.
13. **Write, review and refine Thomas's backstories.** *Now:* Fury and Shadow are playable; Elementalist (staves,
    Storm), Censor (flails, Faith) and Talent (Mind, Survival) are named in `docs/story.md`; Ellen's letters reword
    themselves for each backstory, but only Fury's are drafted. *Job:* each backstory's history, starting kit, Resolve
    trigger and dialogue options, Ellen's letters in every version, and how townsfolk treat each Thomas.

## Presentation

14. **Refine the UI.** *Now:* placeholder screens: the fight HUD (portrait, Resolve, actions, ability bar, log, dice,
    turn order), the skill tree, the backstory choice. *Job:* a UX pass (`/ux-design`) for each screen, the journal,
    the item belt, conversations, and UI art from ChatGPT (frames, icons, fonts in the house palette), plus
    accessibility (text size, colour-blind safe markers, remappable keys).
15. **Review the menus.** *Now:* none: the game starts straight into a life; R starts a new one. *Job:* a main menu,
    pause, settings (volume, keys, text size, accessibility), continuing a saved run, and quitting.
16. **Sound effects.** *Now:* the game is silent. *Job:* an audio direction (`/team-audio`), then a list of sounds by
    priority: footsteps on stone and in water, crouched steps, the lantern (shutter, douse, strike a light), doors and
    sluice gates, hits by tier, crits and the hit-stop, the dice, the Faithful's singing, the Drowned, Garrick's
    chain, a dagger's clatter, dripping and distant water for each room; music later. *Open:* who makes the audio
    (ChatGPT owns `assets/`, so audio would go there; it may need another tool).
