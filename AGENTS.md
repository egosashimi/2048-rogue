# Repository Guidelines

## Project Structure & Module Organization
Scenes sit in `scenes/`, their scripts in `scripts/`, and autoload singletons in `autoload/` (registered via `project.godot`). Keep theme tweaks inside `themes/` and park supporting art/UI references under `assets/` or `ui/`.

## Build, Test, and Development Commands
Target Godot 4.5—double-check with `godot4 --version`. Open the project through `godot4 --path .` (or `--headless --editor` for automation) and run the loop with `godot4 --path . --run Main`. Prefer lightweight harness scenes (e.g., `GridHarness`) for CI smoke checks.

## Coding Style & Naming Conventions
Use 4-space indentation in GDScript, `snake_case` for variables and functions, and `PascalCase` for classes and scene names. Mirror each scene with a script of the same stem (`Game.tscn` -> `scripts/game_manager.gd`) and keep UI logic thin by routing through managers. When extending the neobrutalist look, add colors, fonts, and constants to `themes/neobrutalist.theme.tres` instead of hard-coding values inside nodes.

## Testing Guidelines
Prioritize deterministic grid behavior: keep harness scenes in `scenes/debug/`, suffix scripts with `_test.gd`, and assert outcomes. Manual smoke tests should traverse `Main -> Menu -> Game -> Results`, ensuring tweens finish before new input unlocks.

## Seeded Runs & Replay
The results screen's `Replay Seed` button queues the last run and jumps straight back into `scenes/Game.tscn`. For automation, call `Game.configure_next_seed(<seed>)` before loading `Game.tscn` to reproduce tile order.

## Roguelite Systems
Currency, upgrades, and modifiers live in `autoload/Progression.gd`, `scripts/menu_view.gd`, and `scripts/game_manager.gd`. Menu checkboxes expose `heavy_tiles`, `tiny_board`, `speed_mode`; the progression view iterates `UPGRADE_DEFINITIONS`; HUD buttons dispatch powerups (`undo`, `shuffle`, `clear_lowest`, `merge_boost`). Results payloads expose `currency_earned` and `currency_total` for downstream tooling.

## Commit & Pull Request Guidelines
Write imperative, scope-focused commits such as `Implement grid spawn weighting` or `Polish neobrutalist HUD theme`. Group related changes; avoid bundling assets and logic unless they ship together. Pull requests must outline motivation, list verification commands (e.g., `godot4 --path . --run Main`), and include screenshots or clips for UI adjustments. Reference plan checkpoints in `roguelite-2048-plan.md` to keep progress traceable.
