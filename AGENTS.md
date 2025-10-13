# Repository Guidelines

## Project Structure & Module Organization
Scenes live in `scenes/`, paired scripts in `scripts/`, and autoload singletons in `autoload/` (registered through `project.godot`). Theme resources stay in `themes/`, while `assets/` and `ui/` store supporting art or UI fragments. Export outputs land in `build/` according to `export_presets.cfg`.

## Build, Test, and Development Commands
Target Godot 4.5 (`godot4 --version`). Launch the project with `godot4 --path .` or run headless via `godot4 --path . --run Main`. Use the baked export presets to produce builds: `godot4 --path . --export-release "Windows Desktop"` and `godot4 --path . --export-release Web`. For iteration, prefer lightweight harness scenes or scripted checks to validate grid logic.

## Coding Style & Naming Conventions
Stick to 4-space indentation in GDScript, `snake_case` for variables/functions, and `PascalCase` for classes and scene names. Mirror scene filenames with their scripts (`Game.tscn` ↔ `scripts/game_manager.gd`). When extending the neobrutalist look, push palette or spacing tweaks into `themes/neobrutalist.theme.tres` rather than hard-coding per node.

## Testing Guidelines
Guarantee deterministic slides/merges: build harnesses under `scenes/debug/` and suffix test scripts with `_test.gd`. Manual smoke runs should traverse `Main -> Menu -> Game -> Results`, confirm audio cues fire on merges, observe big-merge screen shake, and ensure input unlocks after tweens. After gameplay changes, run both export commands to make sure desktop and web builds still boot.

## Audio & Feedback
Merge SFX are generated procedurally in `scripts/game_manager.gd`; adjust tone envelopes there instead of importing external assets. Screen shake offsets the `BoardPanel` node — keep `_trigger_screen_shake` lightweight to avoid fighting the layout or tween system. For new feedback hooks, reuse the existing audio helpers to maintain consistent loudness.

## Seeded Runs & Replay
The Results screen's `Replay Seed` button requeues the last run and returns to `scenes/Game.tscn`. Automation can call `Game.configure_next_seed(<seed>)` and `Game.set_pending_modifiers([...])` before loading the Game scene to reproduce a specific board.

## Commit & Pull Request Guidelines
Write imperative, scoped commits (`Polish neobrutalist theme padding`, `Add merge SFX generator`, etc.). Group logic and theme tweaks that ship together, but split exports/content-heavy changes when practical. PRs should state the goal, list verification commands (play run + both exports), and attach screenshots or clips for UI/audio-affecting work. Tie progress back to `roguelite-2048-plan.md` checkpoints.
