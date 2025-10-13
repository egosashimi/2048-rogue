extends Node

signal run_started(seed: int, modifiers: Array)
signal run_ended(result: Dictionary)
signal move_requested(direction: Vector2i)
signal input_locked_changed(locked: bool)
signal score_updated(score: int)

const INPUT_MAP := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"pause": [KEY_ESCAPE, KEY_P]
}

var input_locked: bool = false
var last_result: Dictionary = {}
var current_score: int = 0
var current_seed: int = 0
var active_modifiers: Array = []

var run_manager: RunManager = null
var _next_seed_override: int = 0

func _ready() -> void:
	_ensure_input_actions()
	_ensure_run_manager()

func request_move(direction: Vector2i) -> void:
	if input_locked:
		return
	move_requested.emit(direction)

func is_input_locked() -> bool:
	return input_locked

func set_input_locked(value: bool) -> void:
	if input_locked == value:
		return
	input_locked = value
	input_locked_changed.emit(input_locked)

func configure_next_seed(seed: int) -> void:
	_next_seed_override = seed

func notify_run_started(seed_override: int = 0, modifiers: Array = []) -> void:
	_ensure_run_manager()
	var effective_seed := seed_override
	if effective_seed == 0 and _next_seed_override != 0:
		effective_seed = _next_seed_override
	_next_seed_override = 0
	run_manager.start_run(effective_seed, modifiers)

func notify_run_ended(result: Dictionary) -> void:
	_ensure_run_manager()
	last_result = result.duplicate(true)
	run_manager.finish_run(last_result)
	run_ended.emit(last_result.duplicate(true))

func update_score(score: int) -> void:
	current_score = score
	score_updated.emit(score)

func get_last_result() -> Dictionary:
	return last_result.duplicate(true)

func get_current_seed() -> int:
	return current_seed

func get_active_modifiers() -> Array:
	return active_modifiers.duplicate(true)

func _ensure_input_actions() -> void:
	for action in INPUT_MAP.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for keycode in INPUT_MAP[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

func _ensure_run_manager() -> void:
	if run_manager != null and is_instance_valid(run_manager):
		return
	run_manager = RunManager.new()
	run_manager.name = "RunManager"
	add_child(run_manager)
	var init_callable := Callable(self, "_on_run_initialized")
	if not run_manager.run_initialized.is_connected(init_callable):
		run_manager.run_initialized.connect(init_callable)
	var completed_callable := Callable(self, "_on_run_completed")
	if not run_manager.run_completed.is_connected(completed_callable):
		run_manager.run_completed.connect(completed_callable)

func _on_run_initialized(seed: int, modifiers: Array) -> void:
	current_seed = seed
	active_modifiers = modifiers.duplicate(true)
	last_result = {}
	run_started.emit(current_seed, active_modifiers.duplicate(true))

func _on_run_completed(_result: Dictionary) -> void:
	# Placeholder hook for future roguelite bookkeeping.
	pass
