# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Roguelite 2048 is a neobrutalist-styled 2048 game with roguelite progression systems built in Godot 4.5. It combines the classic 2048 sliding puzzle with seeded runs, powerups, persistent currency, upgrades, and run modifiers.

## Development Commands

### Running the Project
- Open project: `godot4 --path . --editor` (opens Godot editor)
- Run game: `godot4 --path .` or press F5 in the editor
- Main scene is `res://scenes/Main.tscn` which routes to Menu -> Game flow

### Building Exports
- Windows: `godot4 --path . --export-release "Windows Desktop"`
  - Output: `build/windows/Roguelite2048.exe`
- Web: `godot4 --path . --export-release Web`
  - Output: `build/web/index.html`

Note: Desktop export templates must be installed for building binaries.

## Architecture

### Scene Flow
Main.tscn -> Menu.tscn -> Game.tscn -> Results.tscn (with Progression.tscn accessible from Menu)

The game uses `get_tree().change_scene_to_file()` for scene transitions.

### Autoload Singletons (Global State)
Located in `autoload/`, these are always available at `/root/{Name}`:

- **Game** (`Game.gd`): Central event bus and input coordinator
  - Manages game-wide signals: `run_started`, `run_ended`, `move_requested`, `input_locked_changed`, `score_updated`
  - Registers input actions dynamically (WASD/arrows, Esc/P for pause)
  - Stores `RunManager` instance and coordinates run lifecycle
  - Tracks `current_seed`, `active_modifiers`, `last_result`

- **RNG** (`RNG.gd`): Deterministic random number generation for seeded runs
  - Wraps `RandomNumberGenerator` with reseedable state
  - Methods: `reseed(seed)`, `get_state()`, `set_state(state)`, `randf()`, `randi_range()`, `shuffle_in_place()`
  - `pick_random_tile_value(heavy_tiles)`: Returns 2, 4, or 8 based on modifier state
  - State snapshots enable undo functionality

- **Progression** (`Progression.gd`): Meta-progression and currency system
  - Manages persistent currency and upgrade levels
  - `UPGRADE_DEFINITIONS`: "starter_tile", "powerup_capacity", "score_multiplier"
  - `get_run_config()`: Returns active bonuses for current run
  - Automatically syncs with Save singleton when currency/upgrades change

- **Save** (`Save.gd`): Persistence layer
  - Saves to `user://save.json` (JSON format)
  - Stores: best_score, last_seed, currency, upgrades, statistics
  - `load_save()`, `save_game()`, `set_progression_snapshot()`
  - Includes migration placeholder for future save format changes

### Core Game Logic

#### Grid (`scripts/grid.gd`)
RefCounted class (not a Node) that implements pure 2048 logic:
- Board state stored as 2D array (`cells`) with tile dictionaries: `{id, value, merged}`
- `step(direction, options)`: Executes a move, returns `{moved, moves, merges, score, positions, highest}`
- `serialize_state()` / `apply_state()`: Enable undo snapshots
- `can_move()`: Detects game-over conditions
- `get_tile_states()`: Returns all tiles with positions
- Board size is configurable (default 4x4, supports 3x3 for "tiny_board" modifier)

#### GameManager (`scripts/game_manager.gd`)
Main game scene controller that orchestrates:
- **Grid visualization**: Spawns/animates Tile instances from `scenes/Tile.tscn`
- **Move handling**: Listens to `Game.move_requested`, locks input during animations
- **Powerup system**: 4 powerups with charge tracking
  - Undo: Restores grid + RNG state from snapshot
  - Shuffle: Randomizes tile positions
  - Clear Lowest: Removes lowest-value tile
  - Merge Boost: Doubles next merge value (2x multiplier)
- **Modifier support**: "heavy_tiles" (more 4/8 spawns), "tiny_board" (3x3), "speed_mode" (faster tweens)
- **Audio/visual feedback**: Procedural merge SFX (`_build_tone()`), screen shake for big merges (512+)
- **Currency calculation**: `_calculate_currency_reward()` based on score, highest tile, modifiers, multiplier

#### RunManager (`scripts/run_manager.gd`)
Manages run lifecycle:
- `start_run(seed, modifiers)`: Initializes seed and reseeds RNG singleton
- `finish_run(result)`: Emits completion signal
- Validates modifiers against `ALLOWED_MODIFIERS` whitelist
- Generates random seed if none provided

### Key Patterns

**Seeded Determinism**: All randomness flows through `RNG` singleton with reseedable state. Undo captures RNG state alongside grid state.

**Signal-based Communication**: Game singleton acts as event bus. Scenes connect to signals rather than directly calling methods on other scenes.

**Separation of Logic and Presentation**:
- `Grid` (pure logic, no visuals) is instantiated by `GameManager`
- `GameManager` handles all visual Tile nodes and animations
- Grid returns move data, GameManager interprets it for tweens

**Progression Integration**:
- `Progression.get_run_config()` returns run-time bonuses (starter tiles, powerup charges, score multiplier)
- Currency earned at run end via `Progression.add_currency()`
- Upgrades purchased in `scripts/progression_view.gd` via `Progression.purchase_upgrade()`

## Controls
- Movement: WASD or Arrow Keys
- Pause: Escape or P (placeholder hook)
- Powerup buttons: Mouse click in-game HUD

## Important Implementation Details

**Animation Locking**: `is_animating` flag prevents input during tile movement. Must be cleared after spawn+game-over check completes.

**Tile ID System**: Each tile gets unique `_next_tile_id` from Grid. IDs persist through moves, only change on merge (one tile absorbs another's ID).

**Merge Boost State**: `merge_boost_pending` flag consumed on next move. Applied via `options["merge_multiplier"]` passed to `grid.step()`.

**Undo Snapshot**: Captured before every move (if undo charges > 0). Contains: grid state, score, moves, highest_tile, rng_state, merge_boost flag.

**Theme System**: Uses `themes/neobrutalist.theme.tres` with value-aware tile panels. Tiles apply `panel_2`, `panel_4`, ... `panel_max` styleboxes dynamically based on value.

## Testing Notes

When testing game logic:
- Use `Game.configure_next_seed(seed)` to set deterministic seed before starting run
- RNG state can be captured/restored for reproducible scenarios
- Grid class can be tested in isolation (it's a RefCounted, not Node-dependent)
