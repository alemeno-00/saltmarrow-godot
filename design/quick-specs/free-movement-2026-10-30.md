# Quick Design Spec: Free Movement in Metres

**Type**: New Small System (phase A); phase B reworks the fight rules
**System**: Movement, exploring and fights
**GDD Reference**: `design/game-brief.md` (workflow: minimal, no GDD), MVP item 10
**Date**: 2026-10-30
**Why**: first playtest (2026-10-30): "movement feels bad". Thomas hops one square per key press in 4 directions,
and out of fights the world still runs in turns (the patrol only steps when Thomas steps).

## The unit

One square of the level is **1.5 m** (32 pixels). Draw Steel's numbers carry over: speed 5 is 7.5 m, reach 1 is
1.5 m, push 2 is 3 m.

**Stays on squares:** the level itself — blockouts, walls, doors, gates, water, lights, painted rooms — and the AI's
route-finding. Characters stop living on squares; players never see them.

## Phase A: exploring in real time

1. Thomas moves freely: 8 directions with the keys, any direction with a stick, at **3.5 m/s**. He reaches full speed
   in **0.1 s** and stops in **0.08 s**.
2. Clicking walks him there along a smoothed path.
3. His body is a circle of **0.35 m** that slides along walls and props instead of stopping dead. Closed doors open
   when he walks into them. Water slows him to **60 %**.
4. The world runs in real time. The patrol walks its route at **1.6 m/s**; waiting enemies stay put and look about;
   ripples spread with distance walked.
5. An enemy notices Thomas within **10.5 m** (today's 7 squares) with a clear line of sight. Time stops and the fight
   starts with initiative, as now.
6. The stairs and the tally tag trigger when he walks onto them.
7. **Until phase B landed:** when a fight started, everyone slid to the nearest free square and the square-based
   fight ran. Phase B removed this.
8. The walk animation plays at the speed he is moving, using 8-direction rows once ChatGPT delivers them and today's
   sheets, mirrored, until then.

### Hit feel (code only, works with today's art)

- A hit-stop of **60 / 90 / 120 ms** for a weak / solid / strong hit.
- Camera shake scaled to damage.
- Knockback that slides the body with easing, with a thud and dust against a wall.
- A short wind-up pause before heavy blows.
- Blood timed to the moment of impact, not the start of the swing.
- Dust on a sharp turn.

## Phase B: fights in metres, like Baldur's Gate 3

Playtest 2026-10-30, Julian: "I want the movement to be anywhere and not grid based, even the combat. Make the
movement and combat like Baldur's Gate 3." Draw Steel's rules stay (the dice, main action, maneuver and move, Malice,
free strikes); where things are and how far they reach is in metres, and it looks and plays like BG3.

1. **Nobody snaps to squares.** When a fight starts everyone stays exactly where they stand; bodies that overlap are
   nudged apart. After a fight Thomas walks on from where he is.
2. **Moving.** Thomas's movement is a budget in metres (speed × 1.5 m: speed 5 is 7.5 m), and the HUD says what is
   left ("Move 4.2 m"). Hovering anywhere shows the route he would take as a line, with its cost at the end; the
   part beyond his budget is drawn red. Clicking walks him there, or as far along as his budget reaches. Movement
   can be split around actions. Routes go round walls and bodies and cut corners where the way is clear. Water
   costs double for every metre waded.
3. **Reach** is measured edge to edge between bodies: 1.5 m for reach 1, 3 m for reach 2. Hovering an enemy in
   reach shows it can be hit; choosing an ability shows its reach as a ring.
4. **Free strikes** (BG3's attacks of opportunity): leaving an enemy's reach gives it one strike. The route preview
   marks the enemies who would get one. A careful step (maneuver) moves up to 1.5 m with no free strikes.
5. **Areas are shapes.** Wide Arc hits everyone in reach. Garrick's Lift-Chain Sweep and the miner's Overhead Smash
   are a band across where Thomas stood when the blow was raised (the old squares: 1.5 m deep, as wide as the
   squares across it), drawn on the floor; it hits every body that touches the band when it lands.
6. **Pushes** move the target n × 1.5 m straight along the line of the blow, stopping at walls (a wall slam) or
   bodies; the damage for slamming counts the squares' worth left over.
7. **Flanking**: an ally more than 120° round the target from the attacker, both in reach.
8. **Bodies** are circles: radius **0.4 m** for a normal-size creature, **0.7 m** for Garrick (big, but still
   inside a square, so he fits the Outflow). They never overlap.
9. **The turn order** runs along the top of the screen, the one acting lit.
10. Enemies move the same way: to a spot beside Thomas (flanking if they can), or as far toward him as their
   budget allows; a fleeing one picks the furthest spot it can reach out of his sight.
11. Distances that were squares become metres: sight 10.5 m, losing them within 3 m, bystanders join within 4.5 m,
   escape beyond sight or 6 m out of view.
12. Unchanged: the dice, abilities, skill trees, hymns, the flooding arena and the sluice gate (which floods by
   square, the level's squares being the data).

## Tuning knobs

All in one file of named values (`scripts/core/movement_rules.gd` or similar), none inline.

| Knob | Default | Range | Category |
|------|---------|-------|----------|
| Metres per square | 1.5 | fixed | gate |
| Walk speed | 3.5 m/s (3.0 felt slightly slow) | 2.0–4.5 | feel |
| Time to full speed | 0.10 s | 0–0.25 | feel |
| Time to stop | 0.08 s | 0–0.2 | feel |
| Thomas's body radius | 0.35 m | 0.25–0.5 | feel |
| Water slowdown | 60 % | 40–80 % | feel |
| Spotting distance | 10.5 m | 6–15 | curve |
| Patrol speed | 1.6 m/s | 1.0–2.5 | feel |
| Hunter and searcher speed | 2.6 m/s | 1.5–3.0 | curve |
| Runaway comes back after | 15 s | 8–40 | curve |
| Fight walking speed (playback) | 5 m/s | 3–8 | feel |
| Hit-stop weak / solid / strong | 60 / 90 / 120 ms | 0–200 | feel |
| Shake per point of damage | to tune | — | feel |
| Creature radius normal / large | 0.4 / 0.7 m | — | gate |
| Flank angle | 120° | 90–150° | curve |

## Acceptance criteria

- [ ] Thomas glides, slides along walls, and never sticks on a corner or a doorway.
- [ ] The patrol walks while Thomas stands still.
- [ ] Being seen at 10.5 m with a clear sight line starts a fight; a wall between them does not.
- [ ] The same seed still gives the same level and enemies.
- [ ] Every test passes, rewritten where it placed things by square.
- [ ] A retained screenshot of each phase in `production/qa/evidence/`.
- [ ] Phase B: no fight rule still counts in squares.

## Size and art

Phase A is a few days of work. Phase B is the larger rewrite of the battle, the AI and their tests (a week or more).

Art is a separate `ART_JOBS.md` job, shown to the user before ChatGPT gets it: 8-direction idle and walk, then attacks
with wind-up, strike and follow-through, hit reactions and knockdowns.
