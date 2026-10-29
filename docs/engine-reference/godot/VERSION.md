# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7 |
| **Installed at pin time** | 4.7.2.stable.official.ed1daf0bf — `~/Downloads/Godot.app` (not on PATH), probed 2026-10-29 |
| **Release Date** | June 2026 (latest patch: 4.7.2, August 2026) |
| **Project Pinned** | 2026-10-29 (project moved from 4.6.2 to 4.7.2) |
| **Last Docs Verified** | 2026-10-17 (release timeline and 4.7 changes); 2026-02-12 (4.4-4.6 content) |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.5, 4.6
and 4.7 were released after the cutoff and introduced significant changes that
the model does NOT know about; 4.4 came out shortly before it and may be thinly
covered. Always cross-reference this directory before suggesting Godot API calls.

## Installed-Version Gap Warning

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.5 | Sep 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | Jun 2026 | HIGH | AreaLight3D, HDR output, Asset Store replaces the Asset Library, VirtualJoystick, Jolt soft-body and world-boundary changes, typed-return overrides |

## Before the Cutoff

4.4 (Mar 2025, Jolt option, FileAccess return types) predates the May 2025
cutoff; the Knowledge Gap Warning still applies to it.

Dates from https://github.com/godotengine/godot/releases, checked 2026-10-17:
4.4 Mar 3 2025, 4.5 Sep 15 2025, 4.6 Jan 26 2026, 4.7 Jun 18 2026, 4.7.2 Aug 18
2026. Migration guides and release notes: `breaking-changes.md` § Sources.

## Migration Notes — 4.6 → 4.7

Upgraded 2026-10-29: `project.godot` feature tag `4.6` → `4.7`, CI
`GODOT_VERSION` `4.6.2` → `4.7.2`. Guide:
https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
(full list in `breaking-changes.md` § 4.6 → 4.7; not re-fetched for this upgrade).

**Audit of `scripts/` and `tests/` against that list:**
- No use of the renamed or removed APIs (`RichTextLabel` image units,
  `tap_back_pos`, `is_class`, `accessibility_live`, `get_format`, Jolt 3D
  physics, `AudioStreamPlayer2D.area_mask`).
- No `event.device == 0` checks; input is matched by action name or event type (`InputEventKey`, `InputEventMouseButton`).
- Typed-return functions starting with `_` are the project's own helpers, not
  engine overrides, so the typed-return override change does not apply.
- **Check by eye:** 4.7 adds no antialiasing feather to `CanvasItem` lines,
  so lines draw thinner. The game draws with `draw_line`, `draw_polyline` and
  outlined `draw_rect` in `scripts/game/` (hero, enemy_view, overlay,
  level_view, combat_hud, tree_screen, gore). Look at the map, the fight HUD
  and the skill tree; widen lines that now look too thin.

**Result on 4.7.2:** headless import clean; `tests/run_tests.gd` 55 passed,
0 failed. Import changed no tracked files.
