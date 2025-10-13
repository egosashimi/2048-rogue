extends Node

var generator := RandomNumberGenerator.new()
var current_seed: int = 0

const HEAVY_TILE_CHANCE := 0.35
const STANDARD_TILE_CHANCE := 0.1

func _ready() -> void:
	reseed()

func reseed(seed: int = 0) -> void:
	if seed == 0:
		seed = int(Time.get_unix_time_from_system())
	current_seed = seed
	generator.seed = current_seed
	generator.state = generator.seed

func get_state() -> int:
	return generator.state

func set_state(state: int) -> void:
	generator.state = state

func randf() -> float:
	return generator.randf()

func randi_range(min_value: int, max_value: int) -> int:
	return generator.randi_range(min_value, max_value)

func shuffle_in_place(array: Array) -> void:
	if array.is_empty():
		return
	for i in range(array.size() - 1, 0, -1):
		var j := generator.randi_range(0, i)
		var tmp := array[i]
		array[i] = array[j]
		array[j] = tmp

func pick_random_tile_value(heavy_tiles: bool = false) -> int:
	var chance := HEAVY_TILE_CHANCE if heavy_tiles else STANDARD_TILE_CHANCE
	var roll := randf()
	if roll < chance:
		return 4
	if heavy_tiles and roll > 0.95:
		return 8
	return 2
