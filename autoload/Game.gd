extends Node

signal run_started
signal run_ended(result)
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

func _ready() -> void:
	_ensure_input_actions()

func request_move(direction: Vector2i) -> void:
	if input_locked:
		return
	move_requested.emit(direction)

func set_input_locked(value: bool) -> void:
	if input_locked == value:
		return
	input_locked = value
	input_locked_changed.emit(input_locked)

func notify_run_started() -> void:
	run_started.emit()

func notify_run_ended(result: Dictionary) -> void:
	run_ended.emit(result)

func update_score(score: int) -> void:
	score_updated.emit(score)

func _ensure_input_actions() -> void:
	for action in INPUT_MAP.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for keycode in INPUT_MAP[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
