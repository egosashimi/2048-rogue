extends Node

var generator := RandomNumberGenerator.new()
var current_seed: int = 0

const HEAVY_TILE_CHANCE := 0.35
const STANDARD_TILE_CHANCE := 0.1

func _ready() -> void:
	reseed()

func reseed(new_seed: int = 0) -> void:
	if new_seed == 0:
		new_seed = int(Time.get_unix_time_from_system())
	current_seed = new_seed
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
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp

func pick_random_tile_value(heavy_tiles: bool = false, mega_tiles: bool = false, no_twos: bool = false, chaos_mode: bool = false) -> int:
	# Chaos mode - completely random values including odd numbers!
	if chaos_mode:
		var chaos_values := [2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16]
		return chaos_values[randi_range(0, chaos_values.size() - 1)]

	# No twos mode - only 4+ tiles
	if no_twos:
		var roll := randf()
		if roll < 0.7:
			return 4
		elif roll < 0.95:
			return 8
		else:
			return 16

	# Mega tiles mode - can spawn 16 or 32
	if mega_tiles:
		var roll := randf()
		if roll < 0.6:
			return 2
		elif roll < 0.85:
			return 4
		elif roll < 0.95:
			return 8
		elif roll < 0.99:
			return 16
		else:
			return 32

	# Heavy tiles mode (existing)
	var chance := HEAVY_TILE_CHANCE if heavy_tiles else STANDARD_TILE_CHANCE
	var roll := randf()
	if roll < chance:
		return 4
	if heavy_tiles and roll > 0.95:
		return 8
	return 2
