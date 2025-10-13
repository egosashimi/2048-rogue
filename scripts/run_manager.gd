extends Node

signal run_initialized(seed: int)
signal run_completed(result: Dictionary)

var seed: int = 0
var modifiers: Array = []

func start_run(seed_override: int = 0, applied_modifiers: Array = []) -> void:
	seed = seed_override if seed_override != 0 else get_node("/root/RNG").current_seed
	modifiers = applied_modifiers.duplicate()
	get_node("/root/RNG").reseed(seed)
	run_initialized.emit(seed)

func finish_run(result: Dictionary) -> void:
	run_completed.emit(result)
