extends Control

@onready var currency_label: Label = $ContentPanel/VBoxContainer/CurrencyLabel
@onready var start_button: Button = $ContentPanel/VBoxContainer/StartButton
@onready var progression_button: Button = $ContentPanel/VBoxContainer/ProgressionButton
@onready var heavy_tiles_check: CheckButton = $ContentPanel/VBoxContainer/ModifiersContainer/HeavyTilesCheck
@onready var tiny_board_check: CheckButton = $ContentPanel/VBoxContainer/ModifiersContainer/TinyBoardCheck
@onready var speed_mode_check: CheckButton = $ContentPanel/VBoxContainer/ModifiersContainer/SpeedModeCheck

func _ready() -> void:
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not progression_button.pressed.is_connected(_on_progression_pressed):
		progression_button.pressed.connect(_on_progression_pressed)
	heavy_tiles_check.toggled.connect(Callable(self, "_on_modifier_toggled").bind("heavy_tiles"))
	tiny_board_check.toggled.connect(Callable(self, "_on_modifier_toggled").bind("tiny_board"))
	speed_mode_check.toggled.connect(Callable(self, "_on_modifier_toggled").bind("speed_mode"))
	_sync_modifier_checks()
	_refresh_currency()
	_attach_currency_signal()

func _on_start_pressed() -> void:
	var modifiers := _gather_modifiers()
	var game := _get_game_singleton()
	if game != null and game.has_method("set_pending_modifiers"):
		game.set_pending_modifiers(modifiers)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_progression_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Progression.tscn")

func _on_modifier_toggled(_pressed: bool, key: String) -> void:
	var modifiers := _gather_modifiers()
	var game := _get_game_singleton()
	if game != null and game.has_method("set_pending_modifiers"):
		game.set_pending_modifiers(modifiers)

func _on_currency_changed(_amount: int) -> void:
	_refresh_currency()

func _refresh_currency() -> void:
	var progression := _get_progression_singleton()
	if progression != null and progression.has_method("get_currency"):
		var currency: int = progression.get_currency()
		currency_label.text = "Currency: %d" % currency
	else:
		currency_label.text = "Currency: --"

func _attach_currency_signal() -> void:
	var progression := _get_progression_singleton()
	if progression == null:
		return
	var callable := Callable(self, "_on_currency_changed")
	if not progression.currency_changed.is_connected(callable):
		progression.currency_changed.connect(callable)

func _sync_modifier_checks() -> void:
	var game := _get_game_singleton()
	if game == null or not game.has_method("get_pending_modifiers"):
		_set_modifier_checks([])
		return
	var modifiers: Array = game.get_pending_modifiers()
	_set_modifier_checks(modifiers)

func _set_modifier_checks(modifiers: Array) -> void:
	heavy_tiles_check.button_pressed = modifiers.has("heavy_tiles")
	tiny_board_check.button_pressed = modifiers.has("tiny_board")
	speed_mode_check.button_pressed = modifiers.has("speed_mode")

func _gather_modifiers() -> Array:
	var modifiers: Array = []
	if heavy_tiles_check.button_pressed:
		modifiers.append("heavy_tiles")
	if tiny_board_check.button_pressed:
		modifiers.append("tiny_board")
	if speed_mode_check.button_pressed:
		modifiers.append("speed_mode")
	return modifiers

func _get_game_singleton() -> Node:
	return get_node_or_null("/root/Game")

func _get_progression_singleton() -> Node:
	return get_node_or_null("/root/Progression")
