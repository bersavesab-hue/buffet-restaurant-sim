class_name BuildPlacementPreview
extends Node2D

@export var grid_path: NodePath

@onready var restaurant_grid: RestaurantGrid = get_node(grid_path) as RestaurantGrid

var preview_cells: Array[Vector2i] = []
var preview_valid := false
var preview_active := false

func _ready() -> void:
	z_as_relative = false
	z_index = 3000

func show_preview(cells: Array[Vector2i], valid: bool) -> void:
	preview_cells = cells.duplicate()
	preview_valid = valid
	preview_active = true
	queue_redraw()

func clear_preview() -> void:
	preview_cells.clear()
	preview_active = false
	queue_redraw()

func _draw() -> void:
	if not preview_active or restaurant_grid == null:
		return

	var fill := Color(0.22, 0.72, 0.38, 0.32) if preview_valid else Color(0.82, 0.24, 0.22, 0.34)
	var edge := Color(0.16, 0.62, 0.30, 0.95) if preview_valid else Color(0.78, 0.16, 0.14, 0.95)
	var half := RestaurantGrid.HALF_CELL

	for cell in preview_cells:
		var center := restaurant_grid.grid_to_world(cell)
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -half.y),
			center + Vector2(half.x, 0.0),
			center + Vector2(0.0, half.y),
			center + Vector2(-half.x, 0.0)
		])
		draw_colored_polygon(diamond, fill)
		draw_polyline(
			PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
			edge,
			2.0,
			true
		)
