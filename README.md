# Roguelite 2048 (Godot 4.5)

This repository contains the groundwork for a neobrutalist 2048 roguelite built from scratch in Godot 4.5. The current state is Phase 0 of the development plan: project scaffolding, scenes, autoloads, scripts, and a base theme.

## Requirements
- Godot 4.5 (desktop editor or headless binary)
- Desktop export templates installed if you plan to build binaries

## Getting Started
1. Open the project with Godot via `project.godot`.
2. Run the project (`F5`) to load the main scene. It routes `Main` -> `Menu` -> `Game`.
3. Keyboard controls are registered at runtime (`WASD`/arrow keys for movement, `Esc`/`P` for pause placeholder).
4. The Results screen displays the run seed and offers `Replay Seed` to instantly relaunch the same seed for another attempt.

## Project Structure
- `scenes/` - Main, Menu, Game, Tile, Results, and Progression scenes.
- `scripts/` - Game manager, grid logic, tile script, and run manager.
- `autoload/` - Global singletons for input mapping, saving, progression, and RNG.
- `themes/` - `neobrutalist.theme.tres` defines the initial high-contrast styling.
- `data/`, `assets/`, `ui/`, `build/` - Reserved for future content and exports.

## Next Steps
- Implement grid movement/merge logic and tile animations (Phase 1).
- Flesh out persistence and roguelite systems (Phase 2+).
- Iterate on neobrutalist visuals, audio, and exports once core gameplay stabilizes.
