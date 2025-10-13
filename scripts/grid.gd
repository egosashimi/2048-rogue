extends RefCounted
class_name Grid

const SIZE := Vector2i(4, 4)

var cells: Array = []
var _next_tile_id: int = 1

func _init() -> void:
	reset()

func reset() -> void:
	cells = []
	for _y in range(SIZE.y):
		var row: Array = []
		for _x in range(SIZE.x):
			row.append(null)
		cells.append(row)
	_next_tile_id = 1

func clear() -> void:
	reset()

func get_size() -> Vector2i:
	return SIZE

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
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if cells[y][x] == null:
				empty.append(Vector2i(x, y))
	return empty

func can_move() -> bool:
	if get_empty_cells().size() > 0:
		return true
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var current = cells[y][x]
			if current == null:
				continue
			if x < SIZE.x - 1:
				var right_cell = cells[y][x + 1]
				if right_cell != null and right_cell["value"] == current["value"]:
					return true
			if y < SIZE.y - 1:
				var down_cell = cells[y + 1][x]
				if down_cell != null and down_cell["value"] == current["value"]:
					return true
	return false

func get_highest_value() -> int:
	var highest := 0
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var cell = cells[y][x]
			if cell == null:
				continue
			highest = max(highest, int(cell["value"]))
	return highest

func step(direction: Vector2i) -> Dictionary:
	var normalized := Vector2i(
		sign(direction.x),
		sign(direction.y)
	)
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

	var x_range := _get_axis_range(SIZE.x, normalized.x)
	var y_range := _get_axis_range(SIZE.y, normalized.y)

	for y in y_range:
		for x in x_range:
			var start := Vector2i(x, y)
			var tile := get_cell(start)
			if tile == null:
				continue

			var target := start
			var next := target + normalized

			while _is_within_bounds(next) and get_cell(next) == null:
				target = next
				next += normalized

			var merge_target := null
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
				var from_id := tile["id"]
				var into_id := merge_target["id"]
				merge_target["value"] = int(merge_target["value"]) * 2
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
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var tile = cells[y][x]
			if tile == null:
				continue
			positions[tile["id"]] = Vector2i(x, y)
	return positions

func _prepare_for_step() -> void:
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var cell = cells[y][x]
			if cell == null:
				continue
			cell["merged"] = false

func _clear_merge_markers() -> void:
	for y in range(SIZE.y):
		for x in range(SIZE.x):
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
		and position.x < SIZE.x \
		and position.y < SIZE.y
