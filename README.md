# Saltmarrow Deep (Godot)

A gothic, Lovecraftian roguelike. A soldier home from a long war goes looking for his sister in Saltmarrow, a cliff town whose mines run out under the sea, where a star fell and a kind nun is leading the town down to it.

This is the rebuild of [the original web game](https://github.com/alemeno-00/Saltmarrow) in Godot 4.7.

**Play in the browser:** https://alemeno-00.github.io/saltmarrow-godot/ (updated on every change to `main`)

## Running it

1. Install **Godot 4.7** (the standard build, not .NET).
2. Clone this repository and open `project.godot` in Godot.
3. Press **Play** (F5).

Controls: WASD or arrow keys to move (two keys together for diagonals), click a square to walk there, Space to wait, mouse wheel to zoom.

## Tests

```
godot --headless --path . -s tests/run_tests.gd
```

Tests run on every push and pull request. The web build is only published when they pass.

## Layout

| Folder | What's in it |
| --- | --- |
| `scripts/core` | Game rules as plain data (levels, later combat and survival). No drawing, so it can be tested headless. |
| `scripts/game` | Scenes and presentation: the hero, the level view, input. |
| `scenes` | Godot scenes. |
| `assets` | Art and sound. See `AGENTS.md` for how art is delivered. |
| `tests` | Headless tests. |
| `tools` | Helper scripts (screenshots). |
