# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.7.2
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)

## Saltmarrow Deep: house rules

These predate the studio setup and still apply.

**Two assistants, separate folders.**
- **Claude** owns the code: `scripts/`, `scenes/`, `tests/`, `tools/`,
  `project.godot` and the workflows.
- **ChatGPT** owns the art: everything in `assets/`. Its instructions are in
  `AGENTS.md`; keep that file in step with the rules below.
- Stay in your own folders. If art needs a code change to show up, it is
  described in the pull request and Claude wires it in.

**Where things are.**
- Game code is in `scripts/` (`core/` for headless rules, `combat/`, `game/` for
  scenes and presentation), not `src/`. Until that is resolved, treat
  `scripts/` as the code root wherever a skill says `src/`.
- The game runs on **Godot 4.7** (standard build, not .NET).
- Tests: `godot --headless --path . -s tests/run_tests.gd`. CI runs them on every
  push and pull request, and publishes the web build only when they pass, so
  `export_presets.cfg` stays tracked.
- Story: `docs/story.md`. Cast: `docs/characters.md`. Skill trees: `docs/trees.md`.

**`ART_JOBS.md` is the art to-do list.** Keep it up to date as the design
grows: add every new art need as a job with exact file paths, sizes and
animation rows, and move delivered jobs to Done.

**Rules of the game that affect art.**
- Fantasy setting after a long war: swords, staves, lanterns. **No guns.**
- Palette: cold slate blues, charcoal and wet browns, with small warm amber lights.
- Anything touched by the star shows the same signs: a pearly sheen in the
  eyes, a faint inner light under the skin, salt crystals at the edges.

**Changes go through pull requests**; nothing is pushed to `main` directly.
