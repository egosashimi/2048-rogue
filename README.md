# Roguelite 2048 (Godot 4.5)

This repository now ships the core neobrutalist 2048 loop plus the first roguelite systems: seeded runs, powerups, currency rewards, upgrades, selectable modifiers, and the full Phase 5 polish pass -- all built from scratch in Godot 4.5.

## Requirements
- Godot 4.5 (desktop editor or headless binary)
- Desktop export templates installed if you plan to build binaries

## Getting Started
1. Open the project with Godot via `project.godot`.
2. Run the project (`F5`) to load the main scene. It routes `Main` -> `Menu` -> `Game`.
3. Keyboard controls are registered at runtime (`WASD`/arrow keys for movement, `Esc`/`P` for pause placeholder).
4. Use the menu toggles to enable modifiers (`Heavy Tiles`, `Tiny Board`, `Speed Mode`) or open the upgrades screen; in-game powerup buttons fire `Undo`, `Shuffle`, `Clear Lowest`, and `Merge Boost`.
5. The Results screen surfaces score, currency earned, and seed data; tap `Replay Seed` to instantly rerun the same configuration.

## Roguelite Loop
- Currency is awarded after each run (score + highest tile + modifier bonus) and persists via `autoload/Progression.gd`.
- Spend currency in the Progression view to unlock `Starter Tile`, extra powerup charges, and a stacking score multiplier.
- Powerups live on the Game HUD; `Undo` consumes a snapshot, `Shuffle` reorders tiles, `Clear Lowest` frees a cell before spawning anew, and `Merge Boost` doubles the next merge.
- Run modifiers alter the flow: Heavy Tiles increases 4/8 spawn weight, Tiny Board shrinks the grid to 3x3, and Speed Mode accelerates tween timing.

## Neobrutalist Polish & Exports
- Bold, high-contrast theme refresh across Menu, Game, Results, and Progression screens, with value-aware tile styling and enlarged HUD typography.
- Procedural merge SFX and big-merge screen shake to reinforce moment-to-moment feedback without pulling from external audio libraries.
- Ready-to-run export presets: `godot4 --path . --export-release "Windows Desktop"` creates `build/windows/Roguelite2048.exe`, while `godot4 --path . --export-release Web` outputs `build/web/index.html`.

## Project Structure
- `scenes/` - Main, Menu, Game, Tile, Results, and Progression scenes.
- `scripts/` - Game manager, grid logic, tile script, and run manager.
- `autoload/` - Global singletons for input mapping, saving, progression, and RNG.
- `themes/` - `neobrutalist.theme.tres` defines the high-contrast styling gradients.
- `build/` - Export outputs (desktop/web) as configured in `export_presets.cfg`.
- `data/`, `assets/`, `ui/` - Reserved for future content drops.

## Next Steps
- Phase 4 feature pass: daily/weekly challenge scaffolding, achievements, and stat dashboards with persistence hooks.
- QA hardening: add deterministic grid/powerup harnesses, run export smoke-tests, and validate save migrations.
- Content expansion: powerup/modifier variations and layered audio cues once telemetry highlights high-value gaps.
