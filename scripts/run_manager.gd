extends Node
class_name RunManager

signal run_initialized(new_seed: int, modifiers: Array)
signal run_completed(result: Dictionary)

const ALLOWED_MODIFIERS := [
	"heavy_tiles",
	"tiny_board",
	"speed_mode",
	"reverse_controls",
	"gravity_shift",
	"chaos_mode",
	"time_pressure",
	"mega_tiles",
	"no_twos",
	"combo_chain",
	"cursed_tile"
]

var run_seed: int = 0
var modifiers: Array = []

var _seed_rng := RandomNumberGenerator.new()

func _init() -> void:
	_seed_rng.randomize()

func start_run(seed_override: int = 0, applied_modifiers: Array = []) -> void:
	var final_seed := seed_override
	if final_seed == 0:
		final_seed = abs(_seed_rng.randi())
		if final_seed == 0:
			final_seed = 1
	run_seed = final_seed
	modifiers = _filter_modifiers(applied_modifiers)
	var rng_node := get_node_or_null("/root/RNG")
	if rng_node != null:
		rng_node.reseed(run_seed)
	run_initialized.emit(run_seed, modifiers.duplicate(true))

func finish_run(result: Dictionary) -> void:
	run_completed.emit(result)

func _filter_modifiers(applied_modifiers: Array) -> Array:
	var validated: Array = []
	for mod in applied_modifiers:
		if ALLOWED_MODIFIERS.has(mod) and not validated.has(mod):
			validated.append(mod)
	return validated
