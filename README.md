# Roguelite 2048 (Godot 4.5)

This repository now ships the core neobrutalist 2048 loop plus the first roguelite systems: seeded runs, powerups, currency rewards, upgrades, and selectable modifiers, all built from scratch in Godot 4.5.

## Requirements
- Godot 4.5 (desktop editor or headless binary)
- Desktop export templates installed if you plan to build binaries

## Getting Started
1. Open the project with Godot via `project.godot`.
2. Run the project (`F5`) to load the main scene. It routes `Main` -> `Menu` -> `Game`.
3. Keyboard controls are registered at runtime (`WASD`/arrow keys for movement, `Esc`/`P` for pause placeholder).
4. Use the menu toggles to enable modifiers (`Heavy Tiles`, `Tiny Board`, `Speed Mode`) or open the upgrades screen; in-game powerup buttons fire `Undo`, `Shuffle`, `Clear Lowest`, and `Merge Boost`.
5. The Results screen surfaces score, currency earned, and seed data—tap `Replay Seed` to instantly rerun the same configuration.

## Roguelite Loop
- Currency is awarded after each run (score + highest tile + modifier bonus) and persists via `autoload/Progression.gd`.
- Spend currency in the Progression view to unlock `Starter Tile`, extra powerup charges, and a stacking score multiplier.
- Powerups live on the Game HUD; `Undo` consumes a snapshot, `Shuffle` reorders tiles, `Clear Lowest` frees a cell before spawning anew, and `Merge Boost` doubles the next merge.
- Run modifiers alter the flow: Heavy Tiles increases 4/8 spawn weight, Tiny Board shrinks the grid to 3x3, and Speed Mode accelerates tween timing.

## Project Structure
- `scenes/` - Main, Menu, Game, Tile, Results, and Progression scenes.
- `scripts/` - Game manager, grid logic, tile script, and run manager.
- `autoload/` - Global singletons for input mapping, saving, progression, and RNG.
- `themes/` - `neobrutalist.theme.tres` defines the initial high-contrast styling.
- `data/`, `assets/`, `ui/`, `build/` - Reserved for future content and exports.

## Next Steps
- Layer in daily/weekly challenges, achievements, and stat tracking (Phase 4).
- Add audiovisual polish, accessibility presets, and export presets for desktop/web (Phase 5).
- Broaden content: additional modifiers, powerups, and meta progression once the analytics loop is in place.
