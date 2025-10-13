extends Node
class_name RunManager

signal run_initialized(seed: int, modifiers: Array)
signal run_completed(result: Dictionary)

var seed: int = 0
var modifiers: Array = []

var _seed_rng := RandomNumberGenerator.new()

func _init() -> void:
	_seed_rng.randomize()

func start_run(seed_override: int = 0, applied_modifiers: Array = []) -> void:
	var final_seed := seed_override
	if final_seed == 0:
		final_seed = _seed_rng.randi()
		if final_seed == 0:
			final_seed = 1
	seed = final_seed
	modifiers = applied_modifiers.duplicate(true)
	var rng_node := get_node_or_null("/root/RNG")
	if rng_node != null:
		rng_node.reseed(seed)
	run_initialized.emit(seed, modifiers)

func finish_run(result: Dictionary) -> void:
	run_completed.emit(result)
