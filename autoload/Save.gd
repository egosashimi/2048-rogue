extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var data: Dictionary = {}

func _ready() -> void:
	data = load_save()

func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_save()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _default_save()
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _default_save()
	var save_dict: Dictionary = parsed
	if save_dict.get("version", 0) != SAVE_VERSION:
		save_dict = _migrate(save_dict)
	return save_dict

func save_game(new_data: Dictionary) -> void:
	new_data["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(new_data))
	file.close()
	data = new_data

func _default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"best_score": 0,
		"last_seed": 0,
		"currency": 0,
		"upgrades": {},
		"statistics": {}
	}

func _migrate(old_save: Dictionary) -> Dictionary:
	# Placeholder for future migrations.
	var migrated := _default_save()
	for key in migrated.keys():
		if old_save.has(key):
			migrated[key] = old_save[key]
	return migrated
