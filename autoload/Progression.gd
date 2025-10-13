extends Node

signal currency_changed(amount: int)
signal upgrades_changed(upgrades: Dictionary)

var currency: int = 0
var upgrades: Dictionary = {}

func _ready() -> void:
	_load_from_save()

func add_currency(amount: int) -> void:
	if amount <= 0:
		return
	currency += amount
	currency_changed.emit(currency)

func spend_currency(amount: int) -> bool:
	if amount <= 0 or amount > currency:
		return false
	currency -= amount
	currency_changed.emit(currency)
	return true

func unlock_upgrade(key: String, data: Dictionary = {}) -> void:
	upgrades[key] = data
	upgrades_changed.emit(upgrades)

func snapshot() -> Dictionary:
	return {
		"currency": currency,
		"upgrades": upgrades.duplicate(true)
	}

func _load_from_save() -> void:
	var save_node := get_node_or_null("/root/Save")
	if save_node == null:
		return
	var save_data: Dictionary = save_node.data if "data" in save_node else {}
	currency = int(save_data.get("currency", 0))
	upgrades = save_data.get("upgrades", {}).duplicate(true)
