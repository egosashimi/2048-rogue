# GPT‑5 Codex Execution Plan — Roguelite 2048 (Godot, From Scratch, Neobrutalist)

This document is a ready-to-run prompt for a gpt‑5‑codex coding agent. It follows OpenAI prompt best practices: explicit goals, constraints, deliverables, step-by-step tasks, acceptance criteria, and idempotent patch instructions.

---

## Role & Mission

- You are gpt‑5‑codex, a senior Godot 4 game dev agent working in a repo with apply_patch, update_plan, and shell tools.
- Build a roguelite 2048 game from scratch in Godot 4.x with a neobrutalist UI. Do not use or copy any open-source 2048 codebases. All logic and UI must be implemented natively.

---

## Non‑Negotiables

- No upstream/open-source project as a base. From-scratch only.
- Engine: Godot 4.x. Language: GDScript (C# optional later).
- Aesthetic: neobrutalist (bold, high-contrast, flat, chunky borders).
- Outputs must be idempotent, minimal, and scoped. Use `apply_patch` to add/update files; avoid churn.
- Keep code organized, small, and signal-driven. Prefer composition over inheritance.

---

## Scope & Targets

- Platforms: Desktop (Win/macOS/Linux) first; Web (HTML5) second; Mobile later.
- Core features: classic 2048 slide/merge; seeded RNG; HUD; results screen.
- Roguelite features: currency, upgrades, powerups, run modifiers, daily seed.
- Persistence: `user://save.json` with versioning/migrations.

---

## Deliverables by Phase (High-Level)

1) Scaffold project (files, scenes, autoloads, theme) — “Phase 0: Bootstrap”
2) Core 2048: grid, tiles, input, animations, results — “Phase 1: Core 2048”
3) Architecture/persistence: autoloads, save/load, seeded RNG — “Phase 2”
4) Roguelite: currency, upgrades, powerups, modifiers — “Phase 3”
5) Challenges/achievements/stats — “Phase 4”
6) Neobrutalist polish & exports — “Phase 5”

Each phase ends with acceptance checks and zero editor errors when opened in Godot.

---

## Immediate Actions (First Patch) — Bootstrap the Repo

Create the structure and stubs to open/run in Godot. Use the exact paths and minimal contents below. Keep contents small and compile-safe.

- Add `.gitignore` for Godot
- Add base folders: `scenes/`, `scripts/`, `autoload/`, `themes/`, `ui/`, `assets/`, `data/`, `build/`
- Add `project.godot` with app name, main scene, feature flags (safe defaults)
- Add scenes: `scenes/Main.tscn`, `scenes/Menu.tscn`, `scenes/Game.tscn`, `scenes/Tile.tscn`, `scenes/Results.tscn`, `scenes/Progression.tscn`
- Add autoload scripts: `autoload/Game.gd`, `autoload/Save.gd`, `autoload/Progression.gd`, `autoload/RNG.gd`
- Add core scripts: `scripts/game_manager.gd`, `scripts/grid.gd`, `scripts/tile.gd`, `scripts/run_manager.gd`
- Add theme: `themes/neobrutalist.theme.tres` (minimal theme resource)
- Add `README.md` with run/export notes

Notes:
- Register Autoloads in code via `project.godot` (do not rely on manual editor setup).
- Define input actions programmatically in `autoload/Game.gd` on startup with `InputMap.add_action()` and `InputMap.action_add_event()` to ensure deterministic scaffolding.

---

## File Blueprints (Minimal Safe Contents)

Use these minimal, editor-safe contents. Expand later as needed.

- `.gitignore`
  - `.import/\nexport/\n*.tmp\n*.translation\n*.import\n*.godot/imported/*\n.buildcache/\n` (keep concise)

- `project.godot`
  - `[application]\nconfig/name="Roguelite 2048"\nrun/main_scene="res://scenes/Main.tscn"\n` + `[autoload]` entries: `Game="*res://autoload/Game.gd"`, `Save`, `Progression`, `RNG`
  - `[rendering]` safe defaults; target desktop; compatibility OK

- `scenes/Main.tscn`
  - Root `Node` with script to change_scene_to_file("res://scenes/Menu.tscn") on ready

- `scenes/Menu.tscn`
  - Root `Control` with a large `Button` (“Start Run”) styled by theme; on press → `res://scenes/Game.tscn`

- `scenes/Game.tscn`
  - Root `Control`; child `Control` as Board container, child `Control` as HUD
  - Attach `scripts/game_manager.gd`

- `scenes/Tile.tscn`
  - `PanelContainer` + `Label`; attach `scripts/tile.gd`

- `scenes/Results.tscn`
  - `Control` with labels for score/moves/highest tile; “Try Again” button → Menu

- `scenes/Progression.tscn`
  - `Control` placeholder; will list upgrades later

- `autoload/Game.gd`
  - Adds InputMap actions (`move_up/down/left/right`, `pause`), defines global signals

- `autoload/Save.gd`
  - Stubs for `load()`, `save()`, save path, version constant

- `autoload/Progression.gd`
  - Currency/unlocks maps; signals for currency_changed

- `autoload/RNG.gd`
  - `RandomNumberGenerator` wrapper with seed control

- `scripts/game_manager.gd`
  - Connect inputs; hold references to grid and tiles; emit score updates

- `scripts/grid.gd`
  - Board state (4x4); helpers: get_empty_cells, can_move, step(dir) skeleton

- `scripts/tile.gd`
  - `value:int`, `pos:Vector2i`; signal stubs for moved/merged

- `themes/neobrutalist.theme.tres`
  - Minimal Theme resource with a few color constants and Button/Panel border sizes

- `README.md`
  - Short instructions to open with Godot 4, goals, and neobrutalist notes

---

## Phase Plan (Actionable for Codex)

### Phase 1 — Core 2048
- Implement slide/merge logic in `grid.gd` (single merge per tile per move)
- Hook input in `game_manager.gd`; lock input during tweens
- Spawn 2/4 with weighted chance; seeded via `RNG.gd`
- Basic HUD: score, best, move counter
- Win/loss detection; transition to `Results.tscn`

Acceptance:
- Move in all directions works; merges correct; no double-merge bugs
- No runtime errors in Output when played from editor

### Phase 2 — Architecture & Persistence
- Signals for score/run end/currency
- `Save.gd` JSON save/load; autosave on run end
- Seeded runs reproducible with same seed

Acceptance:
- Save file created/loaded under `user://`
- Deterministic run with fixed seed

### Phase 3 — Roguelite Core
- Currency earning formula (score-driven + highest-tile bonus)
- Upgrades: starting bonuses, powerups, score multipliers
- Powerups: Undo(1), Shuffle, Clear Lowest, Merge Boost
- Modifiers: Heavy Tiles, Tiny Board, Speed Mode

Acceptance:
- Upgrades persist and affect new runs
- Powerups usable with clear UI and limited uses

### Phase 4 — Challenges/Achievements/Stats
- Daily/weekly seeded challenges (calendar-based)
- Local leaderboard scaffold
- Achievement tracking + simple toasts

Acceptance:
- Challenge seed stays constant per day
- Achievements persist and fire reliably

### Phase 5 — Neobrutalist Polish & Exports
- Finalize theme: borders, palette, font sizes
- SFX for merges; subtle screenshake for big merges
- Desktop export presets; basic Web export

Acceptance:
- Clean visuals with strong legibility and high contrast
- Desktop export runs; Web export loads on modern desktop

---

## Constraints & Style (Best Practices)

- Idempotent patches; avoid renames unless necessary
- Small, focused scripts; signal-first design
- Deterministic logic; avoid frame-dependent state
- No external addons or assets without approval
- Document key decisions in file headers or README

---

## Ready‑To‑Run Prompt (paste to Codex)

System:
"""
You are gpt‑5‑codex, a senior Godot 4 engineer. Work incrementally, use apply_patch to create files, keep patches minimal and idempotent, and follow the project plan in roguelite-2048-plan.md. Do not use any open-source 2048 code. Build a from-scratch implementation with a neobrutalist UI.
"""

User Task:
"""
Phase 0 bootstrap: create the folders, project.godot with autoloads, minimal scenes (Main, Menu, Game, Tile, Results, Progression), autoload scripts (Game.gd, Save.gd, Progression.gd, RNG.gd), core scripts (game_manager.gd, grid.gd, tile.gd, run_manager.gd), theme file, .gitignore, and README. Ensure input actions are created at runtime in Game.gd. Keep all contents minimal but editor-safe.
"""

Acceptance:
- Godot opens project without errors; Main → Menu → Game scene routing works
- Input map created on startup; no missing script errors
- Theme resource loads; UI elements render

---

## Timeline (Target)

- Phase 0 Bootstrap: 0.5–1 day
- Phase 1 Core 2048: 3–5 days
- Phase 2 Arch/Persistence: 3–5 days
- Phase 3 Roguelite: 7–10 days
- Phase 4 Challenges/Achievements: 5–7 days
- Phase 5 Polish/Exports: 5–7 days

Total: ~4–6 weeks (part/full-time)

