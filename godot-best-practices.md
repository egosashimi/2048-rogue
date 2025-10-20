# Godot 4.5 Best Practices & Common Pitfalls

This document outlines errors encountered during development of Roguelite 2048 and how to avoid them in future projects.

---

## 1. Scene Script Management

### ❌ Problem: Embedded Scripts Causing Black Screen
**Symptom**: Game shows black screen with no errors in headless mode, but scripts appear correct.

**Root Cause**: Main scene had an embedded GDScript (SubResource) instead of an external script file.

```gdscript
# BAD: Embedded in .tscn file
[sub_resource type="GDScript" id="1"]
script/source_code = "extends Control\n\nfunc _ready() -> void:\n..."
```

**Solution**: Always use external script files.

```gdscript
# GOOD: External script reference
[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
```

**Best Practice**:
- Create all scripts as separate `.gd` files in a `scripts/` directory
- Use the Godot editor to attach scripts (ensures proper ExtResource format)
- Never manually embed scripts in `.tscn` files

---

## 2. Scene Transitions

### ❌ Problem: "Parent node is busy" Error
**Symptom**:
```
ERROR: Parent node is busy adding/removing children, `remove_child()` can't be called at this time.
   at: remove_child (scene/main/node.cpp:1718)
```

**Root Cause**: Calling `get_tree().change_scene_to_file()` directly in `_ready()` conflicts with scene tree initialization.

```gdscript
# BAD: Direct call in _ready()
func _ready() -> void:
    get_tree().change_scene_to_file("res://scenes/Menu.tscn")
```

**Solution**: Use deferred calls for scene transitions during initialization.

```gdscript
# GOOD: Deferred call
func _ready() -> void:
    get_tree().change_scene_to_file.call_deferred("res://scenes/Menu.tscn")
```

**Best Practice**:
- Always use `.call_deferred()` for scene transitions in `_ready()`
- Safe to call directly in response to user input (button clicks, etc.)
- Applies to any scene tree modification during initialization

---

## 3. Type Inference in Godot 4.5

### ❌ Problem: "Cannot infer the type" Errors
**Symptom**:
```
SCRIPT ERROR: Parse Error: Cannot infer the type of "variable" because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant value, so it will be typed as Variant.
```

**Root Cause**: Godot 4.5 enforces stricter type inference. Using `:=` requires the engine to determine a concrete type.

### Case 1: Variables that can be null

```gdscript
# BAD: Type inference fails with null
var tile := get_cell(start)  # Returns Dictionary or null
var merge_target := null     # Type unknown

# GOOD: Explicit type annotation
var tile: Variant = get_cell(start)
var merge_target: Variant = null

# EVEN BETTER: Use concrete type if possible
var tile: Dictionary = {}
var merge_target: Dictionary = {}
```

### Case 2: Dictionary access

```gdscript
# BAD: Type inferred from dictionary value (Variant)
var from_id := tile["id"]
var into_id := merge_target["id"]

# GOOD: Explicit type
var from_id: int = tile["id"]
var into_id: int = merge_target["id"]
```

### Case 3: Math operations with ambiguous types

```gdscript
# BAD: Inferred as Variant
var envelope := clamp(1.0 - (t / duration), 0.0, 1.0)
var raw := sin(TAU * frequency * t)
var value := int(raw * envelope * amplitude * 32767.0)

# GOOD: Explicit types
var envelope: float = clamp(1.0 - (t / duration), 0.0, 1.0)
var raw: float = sin(TAU * frequency * t)
var value: int = int(raw * envelope * amplitude * 32767.0)
```

### Case 4: Conditional assignments

```gdscript
# BAD: Type unknown due to conditional logic
var cell_data := null
if condition:
    cell_data = some_value

# GOOD: Explicit Variant type
var cell_data: Variant = null
if condition:
    cell_data = some_value
```

**Best Practice**:
- Use `:=` only when the right-hand side has an obvious, concrete type
- Use explicit type annotations (`: Type`) for:
  - Variables initialized with `null`
  - Dictionary/Array element access
  - Conditional assignments
  - Return values from functions that can return multiple types
- Enable "Treat warnings as errors" in project settings to catch these early

---

## 4. Warnings as Errors

**Configuration**: In `project.godot`:
```ini
[debug]
gdscript/warnings/treat_warnings_as_errors=true
gdscript/warnings/inferred_declaration=1
```

**Why**: Catches type inference issues before runtime. The game will fail to load if scripts have type warnings, forcing you to fix them immediately.

**When to use**:
- Always enable in new projects
- Ensures clean, type-safe code
- Prevents "works in editor, fails in export" scenarios

---

## 5. Testing & Debugging

### Command-line testing

```bash
# Headless mode (catches parse errors only)
godot --path . --headless --quit

# Console mode (shows runtime errors and print statements)
godot --path . --verbose

# Full editor (visual debugging)
godot --path . --editor
```

**Best Practice**:
- Run `--headless --quit` in CI/CD pipelines
- Use `--verbose` for debugging initialization issues
- Keep console window open during development to catch warnings

---

## 6. Error Investigation Workflow

When encountering a black screen or mysterious failure:

1. **Check parse errors first**: Run `godot --headless --quit`
2. **Check runtime errors**: Run `godot` with console output visible
3. **Verify scene structure**: Ensure all scripts are external ExtResources
4. **Check autoload order**: Ensure singletons load in dependency order
5. **Add debug prints**: Use `print()` statements in `_ready()` to trace execution
6. **Enable verbose logging**: Use `--verbose` flag for detailed initialization logs

---

## 7. Project Structure Recommendations

```
project/
├── scenes/          # All .tscn files
│   ├── Main.tscn
│   ├── Menu.tscn
│   └── Game.tscn
├── scripts/         # All .gd files (matches scene names)
│   ├── main.gd
│   ├── menu_view.gd
│   └── game_manager.gd
├── autoload/        # Singleton scripts
│   ├── Game.gd
│   ├── Save.gd
│   └── Progression.gd
└── themes/          # Theme resources
    └── neobrutalist.theme.tres
```

**Best Practice**:
- Keep scripts separate from scenes
- Match script filenames to scene names (lowercase with underscores)
- Use `/autoload` for singleton scripts
- Organize by feature, not by type (for larger projects)

---

## Summary Checklist

Before running your game:

- [ ] All scripts are external `.gd` files (no embedded SubResources)
- [ ] Scene transitions in `_ready()` use `.call_deferred()`
- [ ] Type inference used only for obvious concrete types
- [ ] Variables that can be `null` have explicit type annotations
- [ ] Dictionary/Array access uses explicit types
- [ ] "Treat warnings as errors" enabled in project settings
- [ ] Tested with `godot --headless --quit` (no parse errors)
- [ ] Tested with console output visible (no runtime errors)

---

## References

- Godot 4.5 GDScript documentation: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- Type system changes: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html
- Scene tree lifecycle: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
