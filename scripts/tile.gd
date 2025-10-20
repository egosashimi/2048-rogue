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

	# Ensure tile is fully opaque
	modulate = Color(1, 1, 1, 1)

	var theme := get_theme()
	if theme != null:
		var style_name := _style_name_for_value(value)
		print("Tile value ", value, " trying style: ", style_name)

		var stylebox := theme.get_stylebox(style_name, "Tile")
		if stylebox != null:
			print("  Found stylebox! Type: ", stylebox.get_class())
			if stylebox is StyleBoxFlat:
				var flat_style := stylebox as StyleBoxFlat
				print("  BG Color: ", flat_style.bg_color)
			add_theme_stylebox_override("panel", stylebox)
		else:
			print("  ERROR: No stylebox found for '", style_name, "' in theme!")
			# Try fallback
			var fallback := theme.get_stylebox("panel_2", "Tile")
			if fallback:
				print("  Using fallback panel_2")
				add_theme_stylebox_override("panel", fallback)

		# Use dark font for bright backgrounds (yellow, lime, cyan, coral, mint)
		# Use white font for darker/saturated backgrounds (pink, purple, orange, black)
		var use_dark_font := value in [2, 8, 16, 128, 512]
		var color_name := "fg_dark" if use_dark_font else "fg_light"
		var font_color := theme.get_color(color_name, "Tile")
		value_label.add_theme_color_override("font_color", font_color)

	var target_size := _font_size_for_value(value)
	value_label.add_theme_font_size_override("font_size", target_size)

func _style_name_for_value(current_value: int) -> StringName:
	# Map specific values to their unique color panels
	match current_value:
		2:
			return &"panel_2"
		4:
			return &"panel_4"
		8:
			return &"panel_8"
		16:
			return &"panel_16"
		32:
			return &"panel_32"
		64:
			return &"panel_64"
		128:
			return &"panel_128"
		256:
			return &"panel_256"
		512:
			return &"panel_512"
		1024:
			return &"panel_1024"
		2048:
			return &"panel_2048"
		_:
			# For 4096+ cycle through vibrant colors
			return &"panel_2048"

func _font_size_for_value(current_value: int) -> int:
	var thresholds := FONT_SIZES.keys()
	thresholds.sort()
	thresholds.reverse()
	for threshold in thresholds:
		if current_value >= threshold:
			return FONT_SIZES[threshold]
	return FONT_SIZES[2]
