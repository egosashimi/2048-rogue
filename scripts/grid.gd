extends RefCounted
class_name Grid

const DEFAULT_SIZE := Vector2i(4, 4)

var board_size: Vector2i = DEFAULT_SIZE
var cells: Array = []
var _next_tile_id: int = 1

func _init() -> void:
	reset()

func set_size(new_size: Vector2i) -> void:
	var clamped := Vector2i(max(2, new_size.x), max(2, new_size.y))
	if clamped == board_size:
		reset()
		return
	board_size = clamped
	reset()

func get_default_size() -> Vector2i:
	return DEFAULT_SIZE

func reset() -> void:
	cells = []
	for _y in range(board_size.y):
		var row: Array = []
		for _x in range(board_size.x):
			row.append(null)
		cells.append(row)
	_next_tile_id = 1

func clear() -> void:
	reset()

func get_size() -> Vector2i:
	return board_size

func get_cell(position: Vector2i):
	return cells[position.y][position.x]

func set_cell(position: Vector2i, value) -> void:
	cells[position.y][position.x] = value

func spawn_tile(position: Vector2i, value: int) -> Dictionary:
	if not _is_within_bounds(position):
		return {}
	if get_cell(position) != null:
		return {}
	var tile_state := {
		"id": _next_tile_id,
		"value": value,
		"merged": false
	}
	_next_tile_id += 1
	set_cell(position, tile_state)
	return {
		"id": tile_state["id"],
		"value": value,
		"position": position
	}

func get_empty_cells() -> Array:
	var empty: Array = []
	for y in range(board_size.y):
		for x in range(board_size.x):
			if cells[y][x] == null:
				empty.append(Vector2i(x, y))
	return empty

func can_move() -> bool:
	if get_empty_cells().size() > 0:
		return true
	for y in range(board_size.y):
		for x in range(board_size.x):
			var current = cells[y][x]
			if current == null:
				continue
			if x < board_size.x - 1:
				var right_cell = cells[y][x + 1]
				if right_cell != null and right_cell["value"] == current["value"]:
					return true
			if y < board_size.y - 1:
				var down_cell = cells[y + 1][x]
				if down_cell != null and down_cell["value"] == current["value"]:
					return true
	return false

func get_highest_value() -> int:
	var highest := 0
	for y in range(board_size.y):
		for x in range(board_size.x):
			var cell = cells[y][x]
			if cell == null:
				continue
			highest = max(highest, int(cell["value"]))
	return highest

func step(direction: Vector2i, options: Dictionary = {}) -> Dictionary:
	var normalized := Vector2i(
		sign(direction.x),
		sign(direction.y)
	)
	var merge_multiplier := float(options.get("merge_multiplier", 1.0))
	var result := {
		"moved": false,
		"moves": [],
		"merges": [],
		"score": 0,
		"positions": {},
		"highest": get_highest_value()
	}
	if normalized == Vector2i.ZERO:
		result["positions"] = _collect_positions()
		return result

	_prepare_for_step()

	var x_range := _get_axis_range(board_size.x, normalized.x)
	var y_range := _get_axis_range(board_size.y, normalized.y)

	for y in y_range:
		for x in x_range:
			var start := Vector2i(x, y)
			var tile: Variant = get_cell(start)
			if tile == null:
				continue

			var target := start
			var next := target + normalized

			while _is_within_bounds(next) and get_cell(next) == null:
				target = next
				next += normalized

			var merge_target: Variant = null
			if _is_within_bounds(next):
				var next_tile = get_cell(next)
				if next_tile != null \
						and not next_tile.get("merged", false) \
						and next_tile["value"] == tile["value"]:
					merge_target = next_tile
					target = next

			if target == start and merge_target == null:
				continue

			result["moved"] = true
			set_cell(start, null)

			if merge_target != null:
				var from_id: int = tile["id"]
				var into_id: int = merge_target["id"]
				var base_value := int(merge_target["value"]) * 2
				if merge_multiplier > 1.0:
					base_value = int(round(base_value * merge_multiplier))
				merge_target["value"] = base_value
				merge_target["merged"] = true
				result["score"] += merge_target["value"]
				result["moves"].append({
					"id": from_id,
					"from": start,
					"to": target,
					"merged": true,
					"into_id": into_id
				})
				result["merges"].append({
					"from_id": from_id,
					"into_id": into_id,
					"position": target,
					"result_value": merge_target["value"]
				})
			else:
				set_cell(target, tile)
				tile["merged"] = false
				result["moves"].append({
					"id": tile["id"],
					"from": start,
					"to": target,
					"merged": false
				})

	_clear_merge_markers()
	result["positions"] = _collect_positions()
	result["highest"] = get_highest_value()
	return result

func _collect_positions() -> Dictionary:
	var positions := {}
	for y in range(board_size.y):
		for x in range(board_size.x):
			var tile = cells[y][x]
			if tile == null:
				continue
			positions[tile["id"]] = Vector2i(x, y)
	return positions

func _prepare_for_step() -> void:
	for y in range(board_size.y):
		for x in range(board_size.x):
			var cell = cells[y][x]
			if cell == null:
				continue
			cell["merged"] = false

func _clear_merge_markers() -> void:
	for y in range(board_size.y):
		for x in range(board_size.x):
			var cell = cells[y][x]
			if cell == null:
				continue
			if cell.has("merged"):
				cell["merged"] = false

func _get_axis_range(length: int, direction_component: int) -> Array:
	if direction_component > 0:
		var indices: Array = []
		for i in range(length - 1, -1, -1):
			indices.append(i)
		return indices
	return range(length)

func _is_within_bounds(position: Vector2i) -> bool:
	return position.x >= 0 \
		and position.y >= 0 \
		and position.x < board_size.x \
		and position.y < board_size.y

func serialize_state() -> Dictionary:
	var state_rows: Array = []
	for y in range(board_size.y):
		var row: Array = []
		for x in range(board_size.x):
			var cell = cells[y][x]
			if cell == null:
				row.append(null)
			else:
				row.append({
					"id": int(cell.get("id", -1)),
					"value": int(cell.get("value", 2)),
					"merged": bool(cell.get("merged", false))
				})
		state_rows.append(row)
	return {
		"size": board_size,
		"cells": state_rows,
		"next_id": _next_tile_id
	}

func apply_state(state: Dictionary) -> void:
	var target_size := Vector2i(state.get("size", DEFAULT_SIZE))
	set_size(target_size)
	var rows: Array = state.get("cells", [])
	for y in range(board_size.y):
		for x in range(board_size.x):
			var cell_data: Variant = null
			if y < rows.size():
				var row_data = rows[y]
				if row_data is Array and x < row_data.size():
					cell_data = row_data[x]
			if cell_data == null:
				cells[y][x] = null
			else:
				cells[y][x] = {
					"id": int(cell_data.get("id", -1)),
					"value": int(cell_data.get("value", 2)),
					"merged": bool(cell_data.get("merged", false))
				}
	_next_tile_id = int(state.get("next_id", 1))

func get_tile_states() -> Array:
	var tiles: Array = []
	for y in range(board_size.y):
		for x in range(board_size.x):
			var cell = cells[y][x]
			if cell == null:
				continue
			tiles.append({
				"id": int(cell.get("id", -1)),
				"value": int(cell.get("value", 2)),
				"position": Vector2i(x, y)
			})
	return tiles
