extends Control

@onready var currency_label: Label = $VBoxContainer/CurrencyLabel
@onready var upgrade_list: VBoxContainer = $VBoxContainer/UpgradeList
@onready var back_button: Button = $VBoxContainer/BackButton

var upgrade_rows: Dictionary = {}

func _ready() -> void:
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	_build_upgrade_rows()
	_refresh_currency()
	_refresh_upgrades()
	_attach_signals()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_upgrade_pressed(key: String) -> void:
	var progression := _get_progression()
	if progression == null:
		return
	if progression.purchase_upgrade(key):
		_refresh_currency()
	_refresh_upgrades()

func _on_currency_changed(_amount: int) -> void:
	_refresh_currency()
	_refresh_upgrades()

func _on_upgrades_changed(_data: Dictionary) -> void:
	_refresh_upgrades()

func _refresh_currency() -> void:
	var progression := _get_progression()
	if progression != null:
		currency_label.text = "Currency: %d" % progression.get_currency()
	else:
		currency_label.text = "Currency: --"

func _refresh_upgrades() -> void:
	var progression := _get_progression()
	if progression == null:
		return
	for key in upgrade_rows.keys():
		_update_upgrade_row(key, progression)

func _build_upgrade_rows() -> void:
	upgrade_rows.clear()
	if upgrade_list.get_child_count() > 0:
		for child in upgrade_list.get_children():
			upgrade_list.remove_child(child)
			child.queue_free()
	var progression := _get_progression()
	for key in Progression.UPGRADE_DEFINITIONS.keys():
		var row := HBoxContainer.new()
		row.name = key
		row.theme_override_constants.separation = 16
		var info_label := Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.horizontal_alignment = HorizontalAlignment.LEFT
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.text = "Purchase"
		button.pressed.connect(Callable(self, "_on_upgrade_pressed").bind(key))
		row.add_child(info_label)
		row.add_child(button)
		upgrade_list.add_child(row)
		upgrade_rows[key] = {
			"row": row,
			"label": info_label,
			"button": button
		}
	if progression != null:
		for key in upgrade_rows.keys():
			_update_upgrade_row(key, progression)

func _update_upgrade_row(key: String, progression: Node) -> void:
	if not upgrade_rows.has(key):
		return
	var refs: Dictionary = upgrade_rows[key]
	var info_label: Label = refs["label"]
	var button: Button = refs["button"]
	var definition: Dictionary = Progression.UPGRADE_DEFINITIONS.get(key, {})
	var name := definition.get("name", key.capitalize())
	var description := definition.get("description", "")
	var max_level := int(definition.get("max_level", 1))
	var level := progression.get_upgrade_level(key)
	var info_lines := []
	info_lines.append("%s (Lv %d/%d)" % [name, level, max_level])
	if description != "":
		info_lines.append(description)
	info_label.text = "\n".join(info_lines)
	var cost := progression.get_upgrade_cost(key)
	if cost < 0:
		button.text = "Maxed"
		button.disabled = true
	else:
		button.text = "Buy (%d)" % cost
		button.disabled = progression.get_currency() < cost

func _attach_signals() -> void:
	var progression := _get_progression()
	if progression == null:
		return
	var currency_callable := Callable(self, "_on_currency_changed")
	if not progression.currency_changed.is_connected(currency_callable):
		progression.currency_changed.connect(currency_callable)
	var upgrades_callable := Callable(self, "_on_upgrades_changed")
	if not progression.upgrades_changed.is_connected(upgrades_callable):
		progression.upgrades_changed.connect(upgrades_callable)

func _get_progression() -> Node:
	return get_node_or_null("/root/Progression")
