# GEMINI.md

## Project Overview

This is a "Roguelite 2048" game built with the Godot 4.5 game engine. The project combines the core mechanics of the classic 2048 puzzle game with roguelite elements such as seeded runs, power-ups, currency, and persistent upgrades. The game features a neobrutalist art style and includes a full game loop from the main menu to the results screen.

The core game logic is managed by `scripts/game_manager.gd`, which handles the game board, tile movement, and power-ups. Global game state, such as run management, scoring, and input handling, is managed by autoloaded scripts in the `autoload/` directory, including `Game.gd`, `Progression.gd`, `Save.gd`, and `RNG.gd`.

## Building and Running

### Running the Project

1.  **Open in Godot:** Open the project in the Godot 4.5 editor by importing the `project.godot` file.
2.  **Run Game:** Press `F5` to run the game. This will start the main scene (`scenes/Main.tscn`), which transitions to the menu and then the game.

### Building the Project

The project includes export presets for Windows and Web. You can build the project from the command line using the following commands:

*   **Windows Desktop:**
    ```sh
    godot4 --path . --export-release "Windows Desktop"
    ```
    This will create the executable at `build/windows/Roguelite2048.exe`.

*   **Web:**
    ```sh
    godot4 --path . --export-release Web
    ```
    This will output the web build to `build/web/index.html`.

## Development Conventions

*   **Engine:** The project is developed using Godot 4.5.
*   **Language:** The game is scripted in GDScript.
*   **Project Structure:**
    *   `scenes/`: Contains all the game scenes, including `Main.tscn`, `Menu.tscn`, `Game.tscn`, and `Tile.tscn`.
    *   `scripts/`: Contains the core game logic, such as `game_manager.gd` and `grid.gd`.
    *   `autoload/`: Contains global singleton scripts for managing game-wide state.
    *   `themes/`: Contains the visual theme for the game's UI.
    *   `build/`: The output directory for exported builds.
*   **Coding Style:** The code follows standard GDScript conventions. The use of signals is prevalent for communication between different parts of the game.
*   **State Management:** Global state is managed through autoloaded singleton nodes (e.g., `Game`, `Progression`). This allows for persistent data and state management across different scenes.
