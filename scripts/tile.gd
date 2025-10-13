extends PanelContainer
class_name Tile

signal value_changed(new_value: int)
signal moved(new_position: Vector2i)
signal merged(new_value: int)

var value: int = 2:
	set = set_value

var grid_position: Vector2i = Vector2i.ZERO
var tile_id: int = -1

@onready var value_label: Label = $MarginContainer/Label

const FONT_SIZES := {
	2: 48,
	4: 46,
	8: 44,
	16: 40,
	32: 38,
	64: 36,
	128: 34,
	256: 32,
	512: 30,
	1024: 28,
	2048: 26
}

func _ready() -> void:
	_update_label()

func set_value(new_value: int) -> void:
	if value == new_value:
		return
	value = new_value
	_update_label()
	value_changed.emit(value)

func set_grid_position(position: Vector2i) -> void:
	if grid_position == position:
		return
	grid_position = position
	moved.emit(grid_position)

func notify_merge(result_value: int) -> void:
	set_value(result_value)
	merged.emit(result_value)

func _update_label() -> void:
	if value_label == null:
		return
	value_label.text = str(value)
	var theme := get_theme()
	if theme != null:
		var style_name := _style_name_for_value(value)
		var stylebox := theme.get_stylebox(style_name, "Tile")
		if stylebox != null:
			add_theme_stylebox_override("panel", stylebox)
		var use_dark_font := value >= 128
		var color_name := "fg_dark" if use_dark_font else "fg_light"
		var font_color := theme.get_color(color_name, "Tile")
		value_label.add_theme_color_override("font_color", font_color)
	var target_size := _font_size_for_value(value)
	value_label.add_theme_font_size_override("font_size", target_size)

func _style_name_for_value(current_value: int) -> StringName:
	if current_value >= 1024:
		return &"panel_max"
	if current_value >= 256:
		return &"panel_high"
	if current_value >= 8:
		return &"panel_mid"
	return &"panel_low"

func _font_size_for_value(current_value: int) -> int:
	for threshold in FONT_SIZES.keys().sorted(reverse=true):
		if current_value >= threshold:
			return FONT_SIZES[threshold]
	return FONT_SIZES[2]
