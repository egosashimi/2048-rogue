extends RefCounted
class_name Grid

const SIZE := Vector2i(4, 4)

var cells: Array = []

func _init() -> void:
	reset()

func reset() -> void:
	cells = []
	for _y in range(SIZE.y):
		var row: Array = []
		for _x in range(SIZE.x):
			row.append(null)
		cells.append(row)

func clear() -> void:
	reset()

func get_size() -> Vector2i:
	return SIZE

func get_cell(position: Vector2i):
	return cells[position.y][position.x]

func set_cell(position: Vector2i, value) -> void:
	cells[position.y][position.x] = value

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
			if x < SIZE.x - 1 and cells[y][x + 1] == current:
				return true
			if y < SIZE.y - 1 and cells[y + 1][x] == current:
				return true
	return false

func step(direction: Vector2i) -> Dictionary:
	# Placeholder for slide/merge implementation to be completed in Phase 1.
	return {
		"moved": false,
		"merges": [],
		"score": 0
	}
