extends Control
class_name BoardGrid

const BOARD_PADDING := 24.0
const CELL_GAP := 12.0

@export var grid_size: int = 4
@export var cell_color: Color = Color(0.2, 0.2, 0.25, 1.0)
@export var cell_border_color: Color = Color(0, 0, 0, 1)
@export var cell_border_width: int = 8

var _cell_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Don't set z_index here - tiles are children of this control
	# The grid will be drawn in _draw() which happens before children render
	queue_redraw()

func _draw() -> void:
	var board_size := get_size()
	var available_space := board_size - Vector2(BOARD_PADDING * 2, BOARD_PADDING * 2)
	var total_gaps := (grid_size - 1) * CELL_GAP
	var cell_dimension := (available_space.x - total_gaps) / grid_size
	_cell_size = Vector2(cell_dimension, cell_dimension)

	for row in grid_size:
		for col in grid_size:
			var x := BOARD_PADDING + col * (cell_dimension + CELL_GAP)
			var y := BOARD_PADDING + row * (cell_dimension + CELL_GAP)
			var cell_rect := Rect2(Vector2(x, y), _cell_size)

			# Draw hard shadow offset FIRST (behind cell)
			var shadow_offset := Vector2(6, 6)
			var shadow_rect := Rect2(Vector2(x, y) + shadow_offset, _cell_size)
			draw_rect(shadow_rect, Color(0, 0, 0, 1), true)

			# Draw cell background - dark opaque color
			draw_rect(cell_rect, cell_color, true)

			# Draw thick border
			draw_rect(cell_rect, cell_border_color, false, cell_border_width)

func _process(_delta: float) -> void:
	if get_size() != size:
		queue_redraw()
