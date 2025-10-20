extends ColorRect
class_name GridBackground

@export var grid_size: int = 40
@export var grid_color: Color = Color(0, 0, 0, 0.1)
@export var grid_thickness: int = 2

func _draw() -> void:
	var rect_size := get_size()

	# Draw vertical lines
	var x := 0.0
	while x < rect_size.x:
		draw_line(
			Vector2(x, 0),
			Vector2(x, rect_size.y),
			grid_color,
			grid_thickness
		)
		x += grid_size

	# Draw horizontal lines
	var y := 0.0
	while y < rect_size.y:
		draw_line(
			Vector2(0, y),
			Vector2(rect_size.x, y),
			grid_color,
			grid_thickness
		)
		y += grid_size

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	if get_size() != size:
		queue_redraw()
