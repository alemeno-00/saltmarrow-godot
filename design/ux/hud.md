# HUD: the screen while playing

**Status**: approved layout (Julian, 2026-10-31: "yes, this layout"). Phase 1 built 2026-10-31
(`scripts/game/combat_hud.gd`, `ui_style.gd`, `game_menu.gd`; screenshots in `production/qa/evidence/hud/`).
**Brief**: `design/game-brief.md`, build order step 13 (the UI); backlog item 14.
**Controls**: mouse first, as in Baldur's Gate 3 (Julian, 2026-10-30 and 2026-10-31). Everything can be done with
the mouse; keys are hotkeys for abilities and general things, never the only way.

## What was wrong (review, 2026-10-31)

- Thomas's Stamina was shown only as a word under the portrait, never as a number or a bar.
- The top of the screen was a line of keyboard hints that ran off the right edge and changed between exploring and
  fighting.
- Abilities were text buttons, the belt four empty numbered boxes, the turn order small grey text in a corner.
- Sneaking, the lantern and throwing had no buttons.
- Hovering an enemy only changed that top line; no default Godot styling had been replaced.

## Layout (1280 × 720)

| Where | What | When |
| --- | --- | --- |
| Bottom centre: **the hotbar** | Portrait (with how hurt he looks); Stamina bar with numbers; Resolve; then the action slots; then the belt's four slots; in a fight, what's left of the turn and **End turn** | Always |
| Top left | Depth; level; a thin experience bar (amber when there are points to spend) | Always |
| Top centre | **Turn order**: a token for everyone in the fight in the order they act, the one acting lit; the round; their Malice | Fights |
| Top right | Buttons: **Journal** (J), **Skills** (K), **Menu** (Esc) | Always |
| By the cursor | **Tooltip**: what is under the mouse (an enemy's name, how hurt, its conditions; a thing's name) and what a left-click will do | On hover |
| Bottom left, above the hotbar | The fight log, newest at the bottom | Fights |
| Top centre, below the turn order | The dice | When rolled |
| Centre | Banners | Briefly |

### The action slots

- **Exploring**: Sneak (C), Lantern (L: open, shutter, light; right-click it to put it out), Throw (T, once he has
  the skill), Search / use (E, greyed with nothing in reach).
- **Fighting**: his abilities (1–5), then Careful step (F), Stand up (Q), Catch breath (B).
- Each slot: an icon (a short word until the art arrives), its hotkey in the corner, its cost if it has one; greyed
  when it can't be used now. Hover shows the card (what it does, its cost, why it can't be used).

### The menu (Esc or the Menu button)

Resume, Controls (every hotkey, in one list), New life, Quit (not on the web). The keyboard hints that used to run
along the top live here now.

## Look

Placeholder drawing in the house palette until ChatGPT's UI kit (ART_JOBS job 20) arrives: dark wet slate panels,
a worn brass edge, amber for what is active or chosen, a pale pearl for anything touched by the star, red for harm.
All UI art is loaded from `assets/ui/` by one place in the code (`scripts/game/ui_style.gd`), so the art drops in
without code changes beyond its paths.

## Phases

1. **Phase 1 (now)**: the layout above, with placeholder drawing.
2. **Phase 2 (after the art)**: the skill tree (node icons, a detail panel on hover), the backstory cards (art for
   each), and the journal, title, death and win screens in the same frames; fonts.

## Acceptance criteria

- [x] Stamina is always visible as a number and a bar. *(test)*
- [x] Everything on the old hint line can be done with the mouse: sneak, lantern, throw, search, skills, journal,
      new life. *(test)*
- [x] Hovering an enemy shows its name and state by the cursor. *(test)*
- [x] In a fight the turn order shows everyone still fighting, the one acting lit. *(test)*
- [x] Nothing on screen runs off its edge at 1280 × 720. *(screenshot)*
- [x] All existing hotkeys still work. *(tests)*
