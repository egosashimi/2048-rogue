extends Control

const MODIFIER_DEFINITIONS := {
	"heavy_tiles": {"label": "Heavy Tiles", "description": "More 4/8 tiles spawn"},
	"tiny_board": {"label": "Tiny Board (3x3)", "description": "Smaller grid"},
	"speed_mode": {"label": "Speed Mode", "description": "Faster animations"},
	"reverse_controls": {"label": "Reverse Controls", "description": "All directions inverted"},
	"chaos_mode": {"label": "Chaos Mode", "description": "Odd numbers spawn!"},
	"time_pressure": {"label": "Time Pressure", "description": "5 seconds per move"},
	"mega_tiles": {"label": "Mega Tiles", "description": "16/32 tiles can spawn"},
	"no_twos": {"label": "No Twos", "description": "Only 4+ tiles spawn"},
	"combo_chain": {"label": "Combo Chain", "description": "Consecutive merges multiply score"},
}

@onready var currency_label: Label = $ContentPanel/VBoxContainer/CurrencyLabel
@onready var start_button: Button = $ContentPanel/VBoxContainer/StartButton
@onready var progression_button: Button = $ContentPanel/VBoxContainer/ProgressionButton
@onready var modifiers_container: Container = $ContentPanel/VBoxContainer/ModifiersContainer

var modifier_checks: Dictionary = {}

func _ready() -> void:
	_setup_modifiers_ui()
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not progression_button.pressed.is_connected(_on_progression_pressed):
		progression_button.pressed.connect(_on_progression_pressed)
	_sync_modifier_checks()
	_refresh_currency()
	_attach_currency_signal()

func _setup_modifiers_ui() -> void:
	# Clear any existing children
	for child in modifiers_container.get_children():
		child.queue_free()

	# Convert HBoxContainer to GridContainer for better layout
	if modifiers_container is HBoxContainer:
		var grid := GridContainer.new()
		grid.columns = 3  # 3 columns of modifiers
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 12)
		var parent := modifiers_container.get_parent()
		var index := modifiers_container.get_index()
		parent.remove_child(modifiers_container)
		modifiers_container.queue_free()
		parent.add_child(grid)
		parent.move_child(grid, index)
		modifiers_container = grid

	# Create checkboxes for each modifier
	for key in MODIFIER_DEFINITIONS.keys():
		var def: Dictionary = MODIFIER_DEFINITIONS[key]
		var check := CheckButton.new()
		check.text = def["label"]
		check.tooltip_text = def.get("description", "")
		check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		check.toggled.connect(Callable(self, "_on_modifier_toggled").bind(key))
		modifiers_container.add_child(check)
		modifier_checks[key] = check

func _on_start_pressed() -> void:
	var modifiers := _gather_modifiers()
	var game := _get_game_singleton()
	if game != null and game.has_method("set_pending_modifiers"):
		game.set_pending_modifiers(modifiers)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_progression_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Progression.tscn")

func _on_modifier_toggled(_pressed: bool, _key: String) -> void:
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
	for key in modifier_checks.keys():
		var check: CheckButton = modifier_checks[key]
		if check != null:
			check.button_pressed = modifiers.has(key)

func _gather_modifiers() -> Array:
	var modifiers: Array = []
	for key in modifier_checks.keys():
		var check: CheckButton = modifier_checks[key]
		if check != null and check.button_pressed:
			modifiers.append(key)
	return modifiers

func _get_game_singleton() -> Node:
	return get_node_or_null("/root/Game")

func _get_progression_singleton() -> Node:
	return get_node_or_null("/root/Progression")
