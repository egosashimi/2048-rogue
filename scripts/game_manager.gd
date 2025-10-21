extends Control

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT
}

const TILE_SCENE := preload("res://scenes/Tile.tscn")
const GRID_RESOURCE := preload("res://scripts/grid.gd")
const WIN_VALUE := 2048
const MOVE_TWEEN_BASE := 0.14
const BOARD_PADDING := 24.0
const CELL_GAP := 12.0
const TINY_BOARD_SIZE := Vector2i(3, 3)
const POWERUP_KEYS := [
	"undo",
	"shuffle",
	"clear_lowest",
	"merge_boost"
]
const POWERUP_LABELS := {
	"undo": "Undo",
	"shuffle": "Shuffle",
	"clear_lowest": "Clear Lowest",
	"merge_boost": "Merge Boost"
}
const MERGE_BOOST_MULTIPLIER := 2.0
const BASE_POWERUP_CHARGES := 1
const BIG_MERGE_THRESHOLD := 512
const SHAKE_BASE_DURATION := 0.28
const SHAKE_MAX_STRENGTH := 24.0

@onready var board_panel: Control = $MainLayout/CenterContainer/BoardPanel
@onready var board_container: Control = $MainLayout/CenterContainer/BoardPanel/Board
@onready var score_label: Label = $MainLayout/RightSidebar/HUD/HUDContainer/ScoreLabel
@onready var best_label: Label = $MainLayout/RightSidebar/HUD/HUDContainer/BestLabel
@onready var moves_label: Label = $MainLayout/RightSidebar/HUD/HUDContainer/MovesLabel
@onready var currency_label: Label = $MainLayout/RightSidebar/HUD/HUDContainer/CurrencyLabel
@onready var modifiers_label: Label = $MainLayout/RightSidebar/HUD/HUDContainer/ModifiersLabel
@onready var powerups_container: VBoxContainer = $MainLayout/RightSidebar/PowerupsPanel/PowerupsBar
@onready var merge_player: AudioStreamPlayer = $Audio/MergePlayer
@onready var big_merge_player: AudioStreamPlayer = $Audio/BigMergePlayer
@onready var game_node: Node = get_node("/root/Game")
@onready var rng_node: Node = get_node("/root/RNG")

var grid: Grid
var score: int = 0
var best_score: int = 0
var move_count: int = 0
var highest_tile: int = 0
var current_seed: int = 0
var active_modifiers: Array = []
var tiles: Dictionary = {}
var tile_positions: Dictionary = {}
var is_animating: bool = false
var move_tween_duration: float = MOVE_TWEEN_BASE
var powerup_charges: Dictionary = {}
var powerup_buttons: Dictionary = {}
var merge_boost_pending: bool = false
var undo_snapshot: Dictionary = {}
var heavy_tiles_enabled: bool = false
var tiny_board_enabled: bool = false
var speed_mode_enabled: bool = false
var last_rng_state: int = 0
var progression_config: Dictionary = {}
var currency_earned: int = 0

var _cell_size: Vector2 = Vector2.ZERO
var merge_sound: AudioStreamWAV = null
var big_merge_sound: AudioStreamWAV = null
var _board_panel_base_position: Vector2 = Vector2.ZERO
var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	board_container.clip_contents = true
	if not board_container.resized.is_connected(_on_board_resized):
		board_container.resized.connect(_on_board_resized)
	_shake_rng.randomize()
	set_process(true)
	_prepare_audio_streams()
	await get_tree().process_frame
	_update_board_layout()
	_cache_powerup_buttons()

	grid = GRID_RESOURCE.new()
	_load_best_score()
	_update_hud()
	_connect_game_signals()
	game_node.notify_run_started()

func _connect_game_signals() -> void:
	if not game_node.move_requested.is_connected(_on_move_requested):
		game_node.move_requested.connect(_on_move_requested)
	if not game_node.run_started.is_connected(_on_run_started):
		game_node.run_started.connect(_on_run_started)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for action in DIRECTIONS.keys():
		if Input.is_action_pressed(action):
			game_node.request_move(DIRECTIONS[action])
			get_viewport().set_input_as_handled()
			return

func _on_board_resized() -> void:
	_update_board_layout()
	if board_panel != null:
		_board_panel_base_position = board_panel.position

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer = max(_shake_timer - delta, 0.0)
		var progress := _shake_timer / _shake_duration if _shake_duration > 0.0 else 0.0
		var intensity := _shake_strength * progress
		var offset := Vector2(
			_shake_rng.randf_range(-intensity, intensity),
			_shake_rng.randf_range(-intensity, intensity)
		)
		if board_panel != null:
			board_panel.position = _board_panel_base_position + offset
	elif board_panel != null and board_panel.position != _board_panel_base_position:
		board_panel.position = _board_panel_base_position

func _on_run_started(new_seed: int = 0, modifiers: Array = []) -> void:
	current_seed = new_seed
	active_modifiers = modifiers.duplicate(true)
	_update_modifiers_label()
	_start_new_run()

func _start_new_run() -> void:
	is_animating = false
	score = 0
	move_count = 0
	highest_tile = 0
	currency_earned = 0
	undo_snapshot = {}
	heavy_tiles_enabled = active_modifiers.has("heavy_tiles")
	tiny_board_enabled = active_modifiers.has("tiny_board")
	speed_mode_enabled = active_modifiers.has("speed_mode")
	move_tween_duration = MOVE_TWEEN_BASE * (0.6 if speed_mode_enabled else 1.0)
	var progression_node := _get_progression_node()
	progression_config = progression_node.get_run_config() if progression_node != null else {}
	var target_size := grid.get_default_size()
	if tiny_board_enabled:
		target_size = TINY_BOARD_SIZE
	grid.set_size(target_size)
	_clear_tiles()
	game_node.set_input_locked(false)
	_update_board_layout()
	_initialize_powerups()
	grid.reset()
	_spawn_random_tile()
	_spawn_random_tile()
	var starter_tiles := int(progression_config.get("starter_tile_count", 0))
	for _i in range(starter_tiles):
		_spawn_random_tile(4)
	last_rng_state = rng_node.get_state() if rng_node.has_method("get_state") else 0
	_update_hud()
	_update_powerup_ui()

func _on_move_requested(direction: Vector2i) -> void:
	if is_animating:
		return
	_capture_undo_state()
	var options: Dictionary = {}
	if merge_boost_pending:
		options["merge_multiplier"] = MERGE_BOOST_MULTIPLIER
	var result: Dictionary = grid.step(direction, options)
	if not result.get("moved", false):
		return
	if merge_boost_pending:
		merge_boost_pending = false

	is_animating = true
	move_count += 1
	score += int(result.get("score", 0))
	highest_tile = max(highest_tile, int(result.get("highest", highest_tile)))
	game_node.set_input_locked(true)
	_update_hud()
	_update_powerup_ui()
	_play_move_animation(result)

func _play_move_animation(result: Dictionary) -> void:
	var moves: Array = result.get("moves", [])
	var move_tween := create_tween()
	move_tween.set_parallel(true)

	for move_data in moves:
		var tile_id := int(move_data.get("id", -1))
		if not tiles.has(tile_id):
			continue
		var tile: Tile = tiles[tile_id]
		var destination: Vector2i = move_data.get("to", tile.grid_position)
		tile_positions[tile_id] = destination
		tile.set_grid_position(destination)
		var target_position := _grid_to_pixel(destination)
		var track := move_tween.tween_property(tile, "position", target_position, move_tween_duration)
		track.set_trans(Tween.TRANS_CUBIC)
		track.set_ease(Tween.EASE_OUT)

	move_tween.finished.connect(Callable(self, "_on_move_animation_finished").bind(result), CONNECT_ONE_SHOT)

	var merges: Array = result.get("merges", [])
	for merge_data in merges:
		var into_id := int(merge_data.get("into_id", -1))
		if not tiles.has(into_id):
			continue
		var into_tile: Tile = tiles[into_id]
		var pop_tween := create_tween()
		var enlarge := pop_tween.tween_property(into_tile, "scale", Vector2.ONE * 1.08, move_tween_duration * 0.5)
		enlarge.set_trans(Tween.TRANS_BACK)
		enlarge.set_ease(Tween.EASE_OUT)
		var settle := pop_tween.tween_property(into_tile, "scale", Vector2.ONE, move_tween_duration * 0.4)
		settle.set_trans(Tween.TRANS_BACK)
		settle.set_ease(Tween.EASE_IN)

func _on_move_animation_finished(result: Dictionary) -> void:
	var merges: Array = result.get("merges", [])
	var max_merge_value := 0
	for merge_data in merges:
		var into_id := int(merge_data.get("into_id", -1))
		if tiles.has(into_id):
			var into_tile: Tile = tiles[into_id]
			var new_value := int(merge_data.get("result_value", into_tile.value))
			max_merge_value = max(max_merge_value, new_value)
			into_tile.notify_merge(new_value)
			var final_pos: Vector2i = merge_data.get("position", into_tile.grid_position)
			into_tile.set_grid_position(final_pos)
			into_tile.position = _grid_to_pixel(final_pos)
			into_tile.scale = Vector2.ONE

	for merge_data in merges:
		var from_id := int(merge_data.get("from_id", -1))
		if tiles.has(from_id):
			var removed_tile: Tile = tiles[from_id]
			if is_instance_valid(removed_tile):
				removed_tile.queue_free()
			tiles.erase(from_id)
		if tile_positions.has(from_id):
			tile_positions.erase(from_id)

	if not merges.is_empty():
		_handle_merge_feedback(max_merge_value, merges.size())

	var positions: Dictionary = result.get("positions", {})
	tile_positions.clear()
	for tile_id in positions.keys():
		var grid_pos: Vector2i = positions[tile_id]
		tile_positions[tile_id] = grid_pos
		if tiles.has(tile_id):
			var tile: Tile = tiles[tile_id]
			tile.set_grid_position(grid_pos)
			tile.position = _grid_to_pixel(grid_pos)
			tile.scale = Vector2.ONE

	highest_tile = max(highest_tile, int(result.get("highest", highest_tile)))
	_update_hud()

	if _check_win_condition():
		return

	var spawn_result := _spawn_random_tile()
	_update_hud()

	if spawn_result.is_empty():
		_end_run({"reason": "no_moves"})
		return
	if not grid.can_move():
		_end_run({"reason": "no_moves"})
		return

	is_animating = false
	game_node.set_input_locked(false)
	last_rng_state = rng_node.get_state() if rng_node.has_method("get_state") else last_rng_state
	_update_powerup_ui()

func _check_win_condition() -> bool:
	if highest_tile >= WIN_VALUE:
		_end_run({"reason": "win"})
		return true
	return false

func _spawn_random_tile(value_override: int = 0) -> Dictionary:
	var empty := grid.get_empty_cells()
	if empty.is_empty():
		return {}
	var index: int = rng_node.randi_range(0, empty.size() - 1)
	var grid_pos: Vector2i = empty[index]
	var value: int = value_override if value_override > 0 else rng_node.pick_random_tile_value(heavy_tiles_enabled)
	var state := grid.spawn_tile(grid_pos, value)
	if state.is_empty():
		return {}

	var tile: Tile = TILE_SCENE.instantiate()
	tile.tile_id = state["id"]
	tile.set_value(value)
	tile.set_grid_position(grid_pos)
	tile.z_index = 1  # Ensure tiles render above grid
	board_container.add_child(tile)
	tiles[tile.tile_id] = tile
	tile_positions[tile.tile_id] = grid_pos
	_position_tile(tile, grid_pos)
	tile.scale = Vector2.ZERO

	var tween := create_tween()
	var track := tween.tween_property(tile, "scale", Vector2.ONE, move_tween_duration * 0.8)
	track.set_trans(Tween.TRANS_BACK)
	track.set_ease(Tween.EASE_OUT)

	highest_tile = max(highest_tile, value)
	last_rng_state = rng_node.get_state() if rng_node.has_method("get_state") else last_rng_state
	return state

func _position_tile(tile: Tile, grid_pos: Vector2i) -> void:
	var target := _grid_to_pixel(grid_pos)
	tile.custom_minimum_size = _cell_size
	tile.size = _cell_size
	tile.pivot_offset = _cell_size * 0.5
	tile.position = target

func _grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		BOARD_PADDING + grid_pos.x * (_cell_size.x + CELL_GAP),
		BOARD_PADDING + grid_pos.y * (_cell_size.y + CELL_GAP)
	)

func _update_board_layout() -> void:
	var size := board_container.size
	var dims := grid.get_size() if grid != null else Grid.DEFAULT_SIZE
	var width_available: float = max(size.x - (BOARD_PADDING * 2.0) - (dims.x - 1) * CELL_GAP, 0.0)
	var height_available: float = max(size.y - (BOARD_PADDING * 2.0) - (dims.y - 1) * CELL_GAP, 0.0)
	var tile_width: float = width_available / dims.x if dims.x > 0 else 0.0
	var tile_height: float = height_available / dims.y if dims.y > 0 else 0.0
	_cell_size = Vector2(tile_width, tile_height)
	_reposition_all_tiles()
	if board_panel != null:
		_board_panel_base_position = board_panel.position

func _reposition_all_tiles() -> void:
	for tile_id in tiles.keys():
		var tile: Tile = tiles[tile_id]
		if tile == null:
			continue
		var pos: Vector2i = tile_positions.get(tile_id, tile.grid_position)
		_position_tile(tile, pos)
		tile.scale = Vector2.ONE

func _clear_tiles() -> void:
	for tile in tiles.values():
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()
	tile_positions.clear()

func _end_run(result: Dictionary) -> void:
	is_animating = false
	game_node.set_input_locked(true)

	best_score = max(best_score, score)
	if best_label:
		best_label.text = "Best: %d" % best_score

	var final_result := {
		"score": score,
		"moves": move_count,
		"highest_tile": highest_tile,
		"best_score": best_score,
		"seed": current_seed,
		"modifiers": active_modifiers.duplicate(true),
		"currency_earned": 0
	}
	for key in result.keys():
		final_result[key] = result[key]

	var save_node := _get_save_node()
	var progression_node := _get_progression_node()
	if progression_node != null:
		var reason := str(final_result.get("reason", ""))
		var reward := _calculate_currency_reward(reason)
		if reward > 0:
			progression_node.add_currency(reward)
			currency_earned = reward
			final_result["currency_earned"] = reward
			final_result["currency_total"] = progression_node.get_currency()
			final_result["currency_multiplier"] = progression_config.get("score_multiplier", 1.0)
	if save_node != null:
		var save_snapshot := {}
		if "data" in save_node and typeof(save_node.data) == TYPE_DICTIONARY:
			save_snapshot = save_node.data.duplicate(true)
		save_snapshot["best_score"] = best_score
		save_snapshot["last_seed"] = current_seed
		if progression_node != null:
			save_snapshot["currency"] = progression_node.currency
			save_snapshot["upgrades"] = progression_node.upgrades
		save_node.save_game(save_snapshot)

	_update_hud()

	game_node.notify_run_ended(final_result)
	game_node.update_score(score)
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _load_best_score() -> void:
	var save_node := _get_save_node()
	if save_node == null or not ("data" in save_node) or typeof(save_node.data) != TYPE_DICTIONARY:
		best_score = 0
		return
	best_score = int(save_node.data.get("best_score", 0))

func _update_hud() -> void:
	if score_label:
		score_label.text = "Score: %d" % score
	if best_label:
		best_label.text = "Best: %d" % max(best_score, score)
	if moves_label:
		moves_label.text = "Moves: %d" % move_count
	if currency_label:
		var progression_node := _get_progression_node()
		if progression_node != null and progression_node.has_method("get_currency"):
			currency_label.text = "Currency: %d" % progression_node.get_currency()
		else:
			currency_label.text = "Currency: --"

func _get_save_node() -> Node:
	return get_node_or_null("/root/Save")

func _get_progression_node() -> Node:
	return get_node_or_null("/root/Progression")

func _cache_powerup_buttons() -> void:
	powerup_buttons.clear()
	if powerups_container == null:
		return
	var mapping := {
		"undo": "UndoButton",
		"shuffle": "ShuffleButton",
		"clear_lowest": "ClearLowestButton",
		"merge_boost": "MergeBoostButton"
	}
	for key in POWERUP_KEYS:
		if not mapping.has(key):
			continue
		var button: Button = powerups_container.get_node_or_null(mapping[key])
		if button == null:
			continue
		powerup_buttons[key] = button
		var callable := Callable(self, "_on_powerup_pressed").bind(key)
		if not button.pressed.is_connected(callable):
			button.pressed.connect(callable)
		button.text = _powerup_display_text(key)

func _initialize_powerups() -> void:
	powerup_charges.clear()
	var bonus := int(progression_config.get("powerup_bonus", 0))
	for key in POWERUP_KEYS:
		powerup_charges[key] = BASE_POWERUP_CHARGES + bonus
	merge_boost_pending = false
	undo_snapshot = {}
	if powerup_buttons.is_empty():
		_cache_powerup_buttons()
	_update_powerup_ui()

func _update_powerup_ui() -> void:
	if powerup_buttons.is_empty():
		return
	for key in powerup_buttons.keys():
		var button: Button = powerup_buttons[key]
		if button == null:
			continue
		var remaining := int(powerup_charges.get(key, 0))
		var label := _powerup_display_text(key)
		if key == "merge_boost" and merge_boost_pending:
			label += " *"
		button.text = "%s (%d)" % [label, max(remaining, 0)]
		var disabled := remaining <= 0 or is_animating
		if key == "undo":
			disabled = disabled or undo_snapshot.is_empty()
		button.disabled = disabled

func _powerup_display_text(key: String) -> String:
	return POWERUP_LABELS.get(key, key.capitalize())

func _on_powerup_pressed(powerup: String) -> void:
	match powerup:
		"undo":
			_use_powerup_undo()
		"shuffle":
			_use_powerup_shuffle()
		"clear_lowest":
			_use_powerup_clear_lowest()
		"merge_boost":
			_use_powerup_merge_boost()

func _use_powerup_undo() -> void:
	if is_animating:
		return
	if powerup_charges.get("undo", 0) <= 0:
		return
	if undo_snapshot.is_empty():
		return
	powerup_charges["undo"] = int(powerup_charges["undo"]) - 1
	_restore_state_from_snapshot(undo_snapshot)
	undo_snapshot = {}
	_update_powerup_ui()

func _use_powerup_shuffle() -> void:
	if is_animating:
		return
	if powerup_charges.get("shuffle", 0) <= 0:
		return
	if grid.get_tile_states().size() <= 1:
		return
	powerup_charges["shuffle"] = int(powerup_charges["shuffle"]) - 1
	_shuffle_board_tiles()
	undo_snapshot = {}
	_update_hud()
	_update_powerup_ui()

func _use_powerup_clear_lowest() -> void:
	if is_animating:
		return
	if powerup_charges.get("clear_lowest", 0) <= 0:
		return
	if not _clear_lowest_tile():
		return
	powerup_charges["clear_lowest"] = int(powerup_charges["clear_lowest"]) - 1
	_rebuild_tiles_from_grid()
	highest_tile = grid.get_highest_value()
	_spawn_random_tile()
	undo_snapshot = {}
	_update_hud()
	_update_powerup_ui()
	if not grid.can_move():
		_end_run({"reason": "no_moves"})

func _use_powerup_merge_boost() -> void:
	if is_animating:
		return
	if merge_boost_pending:
		return
	if powerup_charges.get("merge_boost", 0) <= 0:
		return
	powerup_charges["merge_boost"] = int(powerup_charges["merge_boost"]) - 1
	merge_boost_pending = true
	_update_powerup_ui()

func _capture_undo_state() -> void:
	if powerup_charges.get("undo", 0) <= 0:
		undo_snapshot = {}
		return
	var rng_state := last_rng_state
	if rng_node != null and rng_node.has_method("get_state"):
		rng_state = rng_node.get_state()
	undo_snapshot = {
		"grid": grid.serialize_state(),
		"score": score,
		"best_score": best_score,
		"move_count": move_count,
		"highest_tile": highest_tile,
		"rng_state": rng_state,
		"merge_boost": merge_boost_pending
	}
	_update_powerup_ui()

func _restore_state_from_snapshot(state: Dictionary) -> void:
	if state.is_empty():
		return
	if state.has("grid"):
		grid.apply_state(state["grid"])
	score = int(state.get("score", score))
	best_score = max(best_score, int(state.get("best_score", best_score)))
	move_count = int(state.get("move_count", move_count))
	highest_tile = int(state.get("highest_tile", highest_tile))
	merge_boost_pending = bool(state.get("merge_boost", false))
	if rng_node != null and rng_node.has_method("set_state") and state.has("rng_state"):
		rng_node.set_state(int(state["rng_state"]))
	last_rng_state = rng_node.get_state() if rng_node.has_method("get_state") else last_rng_state
	_rebuild_tiles_from_grid()
	is_animating = false
	game_node.set_input_locked(false)
	_update_hud()

func _rebuild_tiles_from_grid() -> void:
	_clear_tiles()
	var tile_states := grid.get_tile_states()
	for tile_state in tile_states:
		var tile: Tile = TILE_SCENE.instantiate()
		var tile_id := int(tile_state.get("id", -1))
		var value := int(tile_state.get("value", 2))
		var position: Vector2i = tile_state.get("position", Vector2i.ZERO)
		tile.tile_id = tile_id
		tile.set_value(value)
		tile.set_grid_position(position)
		board_container.add_child(tile)
		tiles[tile_id] = tile
		tile_positions[tile_id] = position
		_position_tile(tile, position)
		tile.scale = Vector2.ONE

func _shuffle_board_tiles() -> void:
	var tile_states := grid.get_tile_states()
	if tile_states.size() <= 1:
		return
	var positions: Array = []
	for tile_state in tile_states:
		positions.append(tile_state.get("position", Vector2i.ZERO))
	if rng_node != null and rng_node.has_method("shuffle_in_place"):
		rng_node.shuffle_in_place(positions)
	else:
		positions.shuffle()
	for i in range(min(tile_states.size(), positions.size())):
		tile_states[i]["position"] = positions[i]
	var dims := grid.get_size()
	var new_rows: Array = []
	for y in range(dims.y):
		var row: Array = []
		for x in range(dims.x):
			row.append(null)
		new_rows.append(row)
	for tile_state in tile_states:
		var pos: Vector2i = tile_state.get("position", Vector2i.ZERO)
		if pos.x < 0 or pos.y < 0 or pos.x >= dims.x or pos.y >= dims.y:
			continue
		new_rows[pos.y][pos.x] = {
			"id": int(tile_state.get("id", -1)),
			"value": int(tile_state.get("value", 2)),
			"merged": false
		}
	var state := grid.serialize_state()
	state["cells"] = new_rows
	grid.apply_state(state)
	_rebuild_tiles_from_grid()
	highest_tile = grid.get_highest_value()
	last_rng_state = rng_node.get_state() if rng_node.has_method("get_state") else last_rng_state

func _clear_lowest_tile() -> bool:
	var tile_states := grid.get_tile_states()
	if tile_states.is_empty():
		return false
	var lowest := int(tile_states[0].get("value", 0))
	for tile_state in tile_states:
		lowest = min(lowest, int(tile_state.get("value", lowest)))
	var candidates: Array = []
	for tile_state in tile_states:
		if int(tile_state.get("value", 0)) == lowest:
			candidates.append(tile_state)
	if candidates.is_empty():
		return false
	var index := 0
	if rng_node != null and rng_node.has_method("randi_range"):
		index = rng_node.randi_range(0, candidates.size() - 1)
	else:
		index = randi() % candidates.size()
	var target: Dictionary = candidates[index]
	var pos: Vector2i = target.get("position", Vector2i.ZERO)
	grid.set_cell(pos, null)
	return true

func _update_modifiers_label() -> void:
	if modifiers_label == null:
		return
	if active_modifiers.is_empty():
		modifiers_label.text = "Modifiers: None"
		return
	var pretty: Array = []
	for mod in active_modifiers:
		match mod:
			"heavy_tiles":
				pretty.append("Heavy Tiles")
			"tiny_board":
				pretty.append("Tiny Board")
			"speed_mode":
				pretty.append("Speed Mode")
			_:
				pretty.append(str(mod).capitalize())
	modifiers_label.text = "Modifiers: %s" % ", ".join(pretty)

func _handle_merge_feedback(max_value: int, merge_count: int) -> void:
	_play_merge_sound(max_value)
	_trigger_screen_shake(max_value, merge_count)

func _play_merge_sound(max_value: int) -> void:
	if max_value <= 0:
		return
	if max_value >= BIG_MERGE_THRESHOLD:
		if big_merge_player != null and big_merge_sound != null:
			big_merge_player.pitch_scale = 1.0
			_play_sample(big_merge_player)
	else:
		if merge_player != null and merge_sound != null:
			var normalized: float = clamp(float(max_value) / 128.0, 0.0, 1.0)
			merge_player.pitch_scale = 1.0 + (normalized * 0.35)
			_play_sample(merge_player)

func _trigger_screen_shake(max_value: int, merge_count: int) -> void:
	var strength := 0.0
	if max_value >= 2048:
		strength = 22.0
	elif max_value >= 1024:
		strength = 18.0
	elif max_value >= 512:
		strength = 14.0
	elif max_value >= 256:
		strength = 9.0
	else:
		return
	strength += float(max(merge_count - 1, 0)) * 1.5
	_shake_duration = SHAKE_BASE_DURATION
	_shake_strength = min(strength, SHAKE_MAX_STRENGTH)
	_shake_timer = _shake_duration

func _prepare_audio_streams() -> void:
	merge_sound = _build_tone(420.0, 0.16, 0.38)
	big_merge_sound = _build_tone(180.0, 0.32, 0.6)
	if merge_player != null and merge_sound != null:
		merge_player.stream = merge_sound
		merge_player.volume_db = -3.0
	if big_merge_player != null and big_merge_sound != null:
		big_merge_player.stream = big_merge_sound
		big_merge_player.volume_db = -1.5

func _build_tone(frequency: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var sample: AudioStreamWAV = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 44100
	sample.stereo = false
	var frame_count: int = int(duration * sample.mix_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(max(frame_count * 2, 0))
	for i in range(frame_count):
		var t: float = float(i) / float(sample.mix_rate)
		var envelope: float = clamp(1.0 - (t / duration), 0.0, 1.0)
		var raw: float = sin(TAU * frequency * t)
		var value: int = int(raw * envelope * amplitude * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	sample.data = data
	sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return sample

func _play_sample(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()

func _calculate_currency_reward(reason: String) -> int:
	var base := int(floor(score / 50.0))
	var highest_bonus := int(round(highest_tile * 0.5))
	var modifier_bonus := active_modifiers.size() * 5
	var total := base + highest_bonus + modifier_bonus
	if reason == "win":
		total += 50
	var multiplier := float(progression_config.get("score_multiplier", 1.0))
	total = int(round(total * multiplier))
	return max(total, 0)
