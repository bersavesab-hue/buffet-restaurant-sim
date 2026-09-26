class_name PlaceableEntity
extends Node2D

signal placement_changed(entity: PlaceableEntity, grid_position: Vector2i, rotation_index: int)

@export var furniture_definition: FurnitureDefinition
@export var grid_path: NodePath
@export var use_grid_placement := false
@export var grid_position := Vector2i.ZERO
@export_range(0, 3, 1) var rotation_index := 0

var restaurant_grid: RestaurantGrid

func _ready() -> void:
	_resolve_grid()
	if use_grid_placement and restaurant_grid != null:
		_apply_world_position()

func _resolve_grid() -> void:
	if restaurant_grid != null:
		return
	if grid_path.is_empty():
		return
	restaurant_grid = get_node_or_null(grid_path) as RestaurantGrid

func set_restaurant_grid(value: RestaurantGrid) -> void:
	restaurant_grid = value

func get_item_id() -> String:
	if furniture_definition == null:
		return ""
	return furniture_definition.item_id

func get_footprint(for_rotation: int = rotation_index) -> Vector2i:
	if furniture_definition == null:
		return Vector2i.ONE
	return furniture_definition.get_footprint(for_rotation)

func get_occupied_cells(
	anchor: Vector2i = grid_position,
	for_rotation: int = rotation_index
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var size := get_footprint(for_rotation)
	for y in range(size.y):
		for x in range(size.x):
			result.append(anchor + Vector2i(x, y))
	return result

func can_use_cell(anchor: Vector2i, for_rotation: int = rotation_index) -> bool:
	_resolve_grid()
	if restaurant_grid == null or furniture_definition == null:
		return false
	if furniture_definition.required_stage > restaurant_grid.current_stage:
		return false
	for cell in get_occupied_cells(anchor, for_rotation):
		if not restaurant_grid.is_cell_unlocked(cell):
			return false
	return true

func apply_grid_placement(anchor: Vector2i, new_rotation: int = rotation_index) -> bool:
	_resolve_grid()
	var normalized := posmod(new_rotation, 4)
	if not can_use_cell(anchor, normalized):
		return false
	grid_position = anchor
	rotation_index = normalized
	use_grid_placement = true
	_apply_world_position()
	emit_signal("placement_changed", self, grid_position, rotation_index)
	return true

func set_rotation_index(value: int) -> void:
	var normalized := posmod(value, 4)
	if furniture_definition != null and not furniture_definition.allow_rotation:
		normalized = 0
	rotation_index = normalized
	if use_grid_placement:
		_apply_world_position()

func _apply_world_position() -> void:
	if restaurant_grid == null:
		return
	position = restaurant_grid.grid_to_world(grid_position)
	z_as_relative = false
	z_index = int(round(position.y))
