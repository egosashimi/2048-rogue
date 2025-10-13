extends Node

signal currency_changed(amount: int)
signal upgrades_changed(upgrades: Dictionary)

const UPGRADE_DEFINITIONS := {
	"starter_tile": {
		"name": "Starter Tile",
		"description": "Begin each run with an extra tile valued at 4.",
		"base_cost": 200,
		"max_level": 1
	},
	"powerup_capacity": {
		"name": "Power Reserves",
		"description": "Gain +1 charge for every powerup each run.",
		"base_cost": 250,
		"max_level": 2
	},
	"score_multiplier": {
		"name": "Score Multiplier",
		"description": "Earn +10% currency at the end of each run.",
		"base_cost": 300,
		"max_level": 3
	}
}

var currency: int = 0
var upgrades: Dictionary = {}

func _ready() -> void:
	_load_from_save()

func get_currency() -> int:
	return currency

func add_currency(amount: int) -> void:
	if amount <= 0:
		return
	currency += amount
	currency_changed.emit(currency)
	_emit_snapshot_changed()

func spend_currency(amount: int) -> bool:
	if amount <= 0 or amount > currency:
		return false
	currency -= amount
	currency_changed.emit(currency)
	_emit_snapshot_changed()
	return true

func get_upgrade_level(key: String) -> int:
	return int(upgrades.get(key, 0))

func get_upgrade_definition(key: String) -> Dictionary:
	return UPGRADE_DEFINITIONS.get(key, {})

func get_upgrade_cost(key: String) -> int:
	if not UPGRADE_DEFINITIONS.has(key):
		return -1
	var level := get_upgrade_level(key)
	var def: Dictionary = UPGRADE_DEFINITIONS[key]
	var max_level := int(def.get("max_level", 1))
	if level >= max_level:
		return -1
	var base_cost := int(def.get("base_cost", 0))
	# Costs scale modestly with level.
	return int(round(base_cost * pow(1.4, level)))

func purchase_upgrade(key: String) -> bool:
	if not UPGRADE_DEFINITIONS.has(key):
		return false
	var cost := get_upgrade_cost(key)
	if cost <= 0:
		return false
	if not spend_currency(cost):
		return false
	var new_level := get_upgrade_level(key) + 1
	upgrades[key] = new_level
	upgrades_changed.emit(upgrades.duplicate(true))
	_emit_snapshot_changed()
	return true

func snapshot() -> Dictionary:
	return {
		"currency": currency,
		"upgrades": upgrades.duplicate(true)
	}

func get_run_config() -> Dictionary:
	var powerup_bonus := get_upgrade_level("powerup_capacity")
	var starter_tile_count := get_upgrade_level("starter_tile")
	var score_multiplier := 1.0 + (0.1 * get_upgrade_level("score_multiplier"))
	return {
		"powerup_bonus": powerup_bonus,
		"starter_tile_count": starter_tile_count,
		"score_multiplier": score_multiplier
	}

func _emit_snapshot_changed() -> void:
	var save_node := get_node_or_null("/root/Save")
	if save_node == null:
		return
	var current := snapshot()
	save_node.set_progression_snapshot(current)

func _load_from_save() -> void:
	var save_node := get_node_or_null("/root/Save")
	if save_node == null:
		return
	var save_data: Dictionary = save_node.data if "data" in save_node else {}
	currency = int(save_data.get("currency", 0))
	upgrades = save_data.get("upgrades", {}).duplicate(true)
