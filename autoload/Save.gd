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
		push_error("Save: Failed to open save file - Error code: " + str(FileAccess.get_open_error()))
		return _default_save()

	var text := file.get_as_text()
	file.close()

	if text.is_empty():
		push_warning("Save: Save file is empty, using defaults")
		return _default_save()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save: Invalid JSON in save file, using defaults")
		return _default_save()

	var save_dict: Dictionary = parsed
	if save_dict.get("version", 0) != SAVE_VERSION:
		save_dict = _migrate(save_dict)

	return save_dict

func save_game(new_data: Dictionary) -> void:
	new_data["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save: Failed to write save file - Error code: " + str(FileAccess.get_open_error()))
		return

	var json_string := JSON.stringify(new_data, "\t")  # Pretty print with tabs
	file.store_string(json_string)
	file.close()
	data = new_data

func set_progression_snapshot(snapshot: Dictionary) -> void:
	var merged := data.duplicate(true)
	for key in ["currency", "upgrades"]:
		if snapshot.has(key):
			merged[key] = snapshot[key]
	save_game(merged)

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
