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
const MOVE_TWEEN_DURATION := 0.14
const BOARD_PADDING := 24.0
const CELL_GAP := 12.0

@onready var board_container: Control = $Board
@onready var score_label: Label = $HUD/HUDContainer/ScoreLabel
@onready var best_label: Label = $HUD/HUDContainer/BestLabel
@onready var moves_label: Label = $HUD/HUDContainer/MovesLabel
@onready var game_node: Node = get_node("/root/Game")
@onready var rng_node: Node = get_node("/root/RNG")

var grid: Grid
var score: int = 0
var best_score: int = 0
var move_count: int = 0
var highest_tile: int = 0
var tiles: Dictionary = {}
var tile_positions: Dictionary = {}
var is_animating: bool = false

var _cell_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	board_container.clip_contents = true
	if not board_container.resized.is_connected(_on_board_resized):
		board_container.resized.connect(_on_board_resized)
	await get_tree().process_frame()
	_update_board_layout()

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

func _on_run_started() -> void:
	_start_new_run()

func _start_new_run() -> void:
	is_animating = false
	score = 0
	move_count = 0
	highest_tile = 0
	grid.reset()
	_clear_tiles()
	game_node.set_input_locked(false)
	_update_board_layout()
	_spawn_random_tile()
	_spawn_random_tile()
	_update_hud()

func _on_move_requested(direction: Vector2i) -> void:
	if is_animating:
		return
	var result: Dictionary = grid.step(direction)
	if not result.get("moved", false):
		return

	is_animating = true
	move_count += 1
	score += int(result.get("score", 0))
	highest_tile = max(highest_tile, int(result.get("highest", highest_tile)))
	game_node.set_input_locked(true)
	_update_hud()
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
		var track := move_tween.tween_property(tile, "position", target_position, MOVE_TWEEN_DURATION)
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
		var enlarge := pop_tween.tween_property(into_tile, "scale", Vector2.ONE * 1.08, MOVE_TWEEN_DURATION * 0.5)
		enlarge.set_trans(Tween.TRANS_BACK)
		enlarge.set_ease(Tween.EASE_OUT)
		var settle := pop_tween.tween_property(into_tile, "scale", Vector2.ONE, MOVE_TWEEN_DURATION * 0.4)
		settle.set_trans(Tween.TRANS_BACK)
		settle.set_ease(Tween.EASE_IN)

func _on_move_animation_finished(result: Dictionary) -> void:
	var merges: Array = result.get("merges", [])
	for merge_data in merges:
		var into_id := int(merge_data.get("into_id", -1))
		if tiles.has(into_id):
			var into_tile: Tile = tiles[into_id]
			var new_value := int(merge_data.get("result_value", into_tile.value))
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

func _check_win_condition() -> bool:
	if highest_tile >= WIN_VALUE:
		_end_run({"reason": "win"})
		return true
	return false

func _spawn_random_tile() -> Dictionary:
	var empty := grid.get_empty_cells()
	if empty.is_empty():
		return {}
	var index := rng_node.randi_range(0, empty.size() - 1)
	var grid_pos: Vector2i = empty[index]
	var value := rng_node.pick_random_tile_value()
	var state := grid.spawn_tile(grid_pos, value)
	if state.is_empty():
		return {}

	var tile: Tile = TILE_SCENE.instantiate()
	tile.tile_id = state["id"]
	tile.set_value(value)
	tile.set_grid_position(grid_pos)
	board_container.add_child(tile)
	tiles[tile.tile_id] = tile
	tile_positions[tile.tile_id] = grid_pos
	_position_tile(tile, grid_pos)
	tile.scale = Vector2.ZERO

	var tween := create_tween()
	var track := tween.tween_property(tile, "scale", Vector2.ONE, MOVE_TWEEN_DURATION * 0.8)
	track.set_trans(Tween.TRANS_BACK)
	track.set_ease(Tween.EASE_OUT)

	highest_tile = max(highest_tile, value)
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
	var width_available := max(size.x - (BOARD_PADDING * 2.0) - (Grid.SIZE.x - 1) * CELL_GAP, 0.0)
	var height_available := max(size.y - (BOARD_PADDING * 2.0) - (Grid.SIZE.y - 1) * CELL_GAP, 0.0)
	var tile_width := width_available / Grid.SIZE.x if Grid.SIZE.x > 0 else 0.0
	var tile_height := height_available / Grid.SIZE.y if Grid.SIZE.y > 0 else 0.0
	_cell_size = Vector2(tile_width, tile_height)
	_reposition_all_tiles()

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
		"best_score": best_score
	}
	for key in result.keys():
		final_result[key] = result[key]

	var save_node := _get_save_node()
	var progression_node := _get_progression_node()
	if save_node != null:
		var save_snapshot := {}
		if "data" in save_node and typeof(save_node.data) == TYPE_DICTIONARY:
			save_snapshot = save_node.data.duplicate(true)
		save_snapshot["best_score"] = best_score
		if progression_node != null:
			save_snapshot["currency"] = progression_node.currency
			save_snapshot["upgrades"] = progression_node.upgrades
		save_node.save_game(save_snapshot)

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

func _get_save_node() -> Node:
	return get_node_or_null("/root/Save")

func _get_progression_node() -> Node:
	return get_node_or_null("/root/Progression")
