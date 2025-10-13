extends PanelContainer
class_name Tile

signal value_changed(new_value: int)
signal moved(new_position: Vector2i)
signal merged(new_value: int)

var value: int = 2:
	set = set_value

var grid_position: Vector2i = Vector2i.ZERO

@onready var value_label: Label = $MarginContainer/Label

func _ready() -> void:
	_update_label()

func set_value(new_value: int) -> void:
	if value == new_value:
		return
	value = new_value
	_update_label()
	value_changed.emit(value)

func set_grid_position(position: Vector2i) -> void:
	grid_position = position
	moved.emit(grid_position)

func notify_merge(result_value: int) -> void:
	set_value(result_value)
	merged.emit(result_value)

func _update_label() -> void:
	if value_label == null:
		return
	value_label.text = str(value)
