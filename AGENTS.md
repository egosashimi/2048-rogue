# Repository Guidelines

## Project Structure & Module Organization
Core scenes live in `scenes/` (e.g., `scenes/Game.tscn`, `scenes/Results.tscn`) with their paired scripts under `scripts/` (`scripts/game_manager.gd`, `scripts/grid.gd`). Autoload singletons reside in `autoload/` and are registered in `project.godot`, so edits there affect the global game state. Styling assets are consolidated in `themes/`, while `assets/`, `ui/`, and `data/` hold art, mockups, and design payloads. Export targets should be generated into `build/`.

## Build, Test, and Development Commands
This project targets Godot 4.5. Verify the binary with `godot4 --version` before running workflows. Launch the editor via `godot4 --path .` or open headlessly using `godot4 --headless --editor --path .` for automation. Run the playable loop with `godot4 --path . --run Main`. As debugging scenes arrive (e.g., harness runners), prefer `godot4 --headless --path . --run GridHarness` to keep CI display-free.

## Coding Style & Naming Conventions
Use 4-space indentation in GDScript, `snake_case` for variables and functions, and `PascalCase` for classes and scene names. Mirror each scene with a script of the same stem (`Game.tscn` -> `scripts/game_manager.gd`) and keep UI logic thin by routing through managers. When extending the neobrutalist look, add colors, fonts, and constants to `themes/neobrutalist.theme.tres` instead of hard-coding values inside nodes.

## Testing Guidelines
Prioritize deterministic grid behavior: create lightweight harness scenes in `scenes/debug/` and run them headlessly as part of the merge checklist. Name harness scripts with a `_test.gd` suffix and emit `assert()` failures for straightforward CI logging. Manual smoke tests should confirm the route `Main -> Menu -> Game -> Results`, validating that tweens finish before new inputs register.

## Seeded Runs & Replay
Use the results screen's `Replay Seed` button to queue and immediately relaunch the last run's seed via `scenes/Game.tscn`, reproducing the exact tile order. For scripted workflows, call `Game.configure_next_seed(<seed>)` prior to loading `scenes/Game.tscn` so CI or harness scenes can exercise deterministic sequences.

## Commit & Pull Request Guidelines
Write imperative, scope-focused commits such as `Implement grid spawn weighting` or `Polish neobrutalist HUD theme`. Group related changes; avoid bundling assets and logic unless they ship together. Pull requests must outline motivation, list verification commands (e.g., `godot4 --path . --run Main`), and include screenshots or clips for UI adjustments. Reference plan checkpoints in `roguelite-2048-plan.md` to keep progress traceable.
