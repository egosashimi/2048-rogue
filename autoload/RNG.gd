extends Node

var generator := RandomNumberGenerator.new()
var current_seed: int = 0

func _ready() -> void:
	reseed()

func reseed(seed: int = 0) -> void:
	if seed == 0:
		seed = int(Time.get_unix_time_from_system())
	current_seed = seed
	generator.seed = current_seed

func randf() -> float:
	return generator.randf()

func randi_range(min_value: int, max_value: int) -> int:
	return generator.randi_range(min_value, max_value)

func pick_random_tile_value() -> int:
	return 4 if randf() < 0.1 else 2
