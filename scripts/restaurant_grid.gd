class_name RestaurantGrid
extends Node2D

signal stage_changed(stage: int, build_rect: Rect2i)

const GRID_SIZE := Vector2i(44, 36)
const CELL_SIZE := Vector2(64.0, 32.0)
const HALF_CELL := Vector2(32.0, 16.0)
const WORLD_ORIGIN := Vector2(360.0, 160.0)

const STAGE_RECTS: Array[Rect2i] = [
	Rect2i(13, 9, 18, 18),
	Rect2i(10, 7, 24, 22),
	Rect2i(7, 5, 30, 26),
	Rect2i(4, 3, 36, 30),
	Rect2i(0, 0, 44, 36)
]

var current_stage: int = 0
var build_overlay_visible := false

func _ready() -> void:
	queue_redraw()

func set_stage(stage: int) -> void:
	var clamped := clampi(stage, 0, STAGE_RECTS.size() - 1)
	if clamped == current_stage:
		return
	current_stage = clamped
	queue_redraw()
	emit_signal("stage_changed", current_stage, get_unlocked_rect())

func get_stage_count() -> int:
	return STAGE_RECTS.size()

func get_unlocked_rect() -> Rect2i:
	return STAGE_RECTS[current_stage]

func get_stage_rect(stage: int) -> Rect2i:
	return STAGE_RECTS[clampi(stage, 0, STAGE_RECTS.size() - 1)]

func is_cell_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y

func is_cell_unlocked(cell: Vector2i) -> bool:
	return is_cell_valid(cell) and get_unlocked_rect().has_point(cell)

func grid_to_world(cell: Vector2i) -> Vector2:
	return WORLD_ORIGIN + Vector2(
		float(cell.x - cell.y) * HALF_CELL.x,
		float(cell.x + cell.y) * HALF_CELL.y
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	var local := world_position - WORLD_ORIGIN
	var iso_x := local.x / HALF_CELL.x
	var iso_y := local.y / HALF_CELL.y
	var grid_x := (iso_y + iso_x) * 0.5
	var grid_y := (iso_y - iso_x) * 0.5
	return Vector2i(roundi(grid_x), roundi(grid_y))

func snap_world_to_grid(world_position: Vector2) -> Vector2:
	return grid_to_world(world_to_grid(world_position))

func get_rect_world_bounds(rect: Rect2i) -> Rect2:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return Rect2()

	var min_cell := rect.position
	var max_cell := rect.position + rect.size - Vector2i.ONE
	var corners: Array[Vector2] = [
		grid_to_world(Vector2i(min_cell.x, min_cell.y)),
		grid_to_world(Vector2i(max_cell.x, min_cell.y)),
		grid_to_world(Vector2i(min_cell.x, max_cell.y)),
		grid_to_world(Vector2i(max_cell.x, max_cell.y))
	]

	var min_x: float = corners[0].x
	var max_x: float = corners[0].x
	var min_y: float = corners[0].y
	var max_y: float = corners[0].y
	for point in corners:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)

	return Rect2(
		Vector2(min_x - HALF_CELL.x, min_y - HALF_CELL.y),
		Vector2((max_x - min_x) + CELL_SIZE.x, (max_y - min_y) + CELL_SIZE.y)
	)

func get_unlocked_world_bounds() -> Rect2:
	return get_rect_world_bounds(get_unlocked_rect())

func get_full_world_bounds() -> Rect2:
	return get_rect_world_bounds(Rect2i(Vector2i.ZERO, GRID_SIZE))

func set_build_overlay_visible(value: bool) -> void:
	if build_overlay_visible == value:
		return
	build_overlay_visible = value
	z_as_relative = false
	z_index = 2200 if value else -1500
	queue_redraw()

func _draw() -> void:
	if not build_overlay_visible:
		return

	var unlocked := get_unlocked_rect()
	for y in range(unlocked.position.y, unlocked.end.y):
		for x in range(unlocked.position.x, unlocked.end.x):
			var center := grid_to_world(Vector2i(x, y))
			var diamond := PackedVector2Array([
				center + Vector2(0.0, -HALF_CELL.y),
				center + Vector2(HALF_CELL.x, 0.0),
				center + Vector2(0.0, HALF_CELL.y),
				center + Vector2(-HALF_CELL.x, 0.0)
			])
			draw_polyline(diamond, Color(0.78, 0.70, 0.55, 0.42), 1.0, true)
			draw_line(diamond[3], diamond[0], Color(0.78, 0.70, 0.55, 0.42), 1.0, true)

	var bounds := get_unlocked_world_bounds()
	draw_rect(bounds, Color(0.91, 0.68, 0.24, 0.85), false, 3.0)
