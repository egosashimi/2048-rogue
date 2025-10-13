extends Control

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT
}

const TILE_SCENE := preload("res://scenes/Tile.tscn")
const GRID_RESOURCE := preload("res://scripts/grid.gd")

@onready var board_container: Control = $Board
@onready var score_label: Label = $HUD/HUDContainer/ScoreLabel
@onready var best_label: Label = $HUD/HUDContainer/BestLabel
@onready var game_node: Node = get_node("/root/Game")
@onready var rng_node: Node = get_node("/root/RNG")

var grid
var score: int = 0
var best_score: int = 0
var tiles: Dictionary = {}

func _ready() -> void:
	grid = GRID_RESOURCE.new()
	_load_best_score()
	_update_hud()
	if not game_node.move_requested.is_connected(_on_move_requested):
		game_node.move_requested.connect(_on_move_requested)
	if not game_node.run_started.is_connected(_on_run_started):
		game_node.run_started.connect(_on_run_started)
	game_node.notify_run_started()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for action in DIRECTIONS.keys():
		if Input.is_action_pressed(action):
			game_node.request_move(DIRECTIONS[action])
			get_viewport().set_input_as_handled()
			return

func _on_run_started() -> void:
	_start_new_run()

func _start_new_run() -> void:
	score = 0
	grid.reset()
	_clear_tiles()
	_spawn_random_tile()
	_spawn_random_tile()
	_update_hud()

func _on_move_requested(direction: Vector2i) -> void:
	var result: Dictionary = grid.step(direction)
	if not result.get("moved", false):
		return
	score += int(result.get("score", 0))
	_update_hud()
	_spawn_random_tile()
	if not grid.can_move():
		_end_run({"reason": "no_moves"})

func _spawn_random_tile() -> void:
	var empty := grid.get_empty_cells()
	if empty.is_empty():
		return
	var index := rng_node.randi_range(0, empty.size() - 1)
	var grid_pos: Vector2i = empty[index]
	var value := rng_node.pick_random_tile_value()
	grid.set_cell(grid_pos, value)
	var tile: Tile = TILE_SCENE.instantiate()
	tile.set_grid_position(grid_pos)
	tile.set_value(value)
	board_container.add_child(tile)
	tiles[grid_pos] = tile

func _clear_tiles() -> void:
	for tile in tiles.values():
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()

func _end_run(result: Dictionary) -> void:
	best_score = max(best_score, score)
	best_label.text = "Best: %d" % best_score
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
	game_node.notify_run_ended(result)
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
		best_label.text = "Best: %d" % best_score

func _get_save_node() -> Node:
	return get_node_or_null("/root/Save")

func _get_progression_node() -> Node:
	return get_node_or_null("/root/Progression")
